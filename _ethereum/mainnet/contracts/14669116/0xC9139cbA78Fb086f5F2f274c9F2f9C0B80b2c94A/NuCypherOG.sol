// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.12;

import "IERC20.sol";
import "ERC721.sol";
import "Strings.sol";
import "BitMaps.sol";

import "StakingEscrow.sol";

contract NuCypherOG is ERC721 {

    enum Trait { Seeker, Diligent, Pragmatic, Believer, Accomplice, Forgetful, Hoarder, Sluggish, EarlyBird, Follower, Laggard }
    string[11] traitName = ["Seeker", "Diligent", "Pragmatist", "Believer", "Accomplice", "Forgetful", "Hoarder", "Sluggish", "Early Bird", "Follower", "Laggard"];

    IERC20 public immutable nuToken;
    StakingEscrow public immutable stakingEscrow;

    uint256 private constant ONE_NU = 10**18;

    address public immutable owner;

    string private _contractURI;
    string private _imageURI;
    string private _description;

    address private _hoarder;
    BitMaps.BitMap private _wasBurned;

    using BitMaps for BitMaps.BitMap;
    
    constructor(IERC20 _nuToken, StakingEscrow _stakingEscrow)
        ERC721("NuCypher OG", "NUOG")
    {
        owner = msg.sender;
        stakingEscrow = _stakingEscrow;
        nuToken = _nuToken;
        _contractURI = "ipfs://QmeR4LLZWmjU4wHCo4qAQipGUJ7PQwYLHppQtFmTeLHLBF";
        _imageURI = "ipfs://QmWyrmmnDPVxah7vaY2eeVhCYCEbVtWbUTtqTcL2WGgcnn";
        _description = "With love from the NuCypher team to all our current and past stakers. Each NuCypher OG NFT will be forever redeemable for 1 NU. This collection is, literally, a token of our appreciation <3";
    }

    function isHoarder(address addy) internal pure returns (bool){
        uint160 first2Bytes = uint160(bytes20(addy) >> (18*8));
        return first2Bytes == 0;
    }

    function claim(uint256 tokenID) external {
        require(tokenID < stakingEscrow.getStakersLength());
        require(stakingEscrow.stakers(tokenID) == msg.sender);
        require(!_wasBurned.get(tokenID));
        if (isHoarder(msg.sender)){
            require(_hoarder == address(0), "Hoarder already claimed");
            _hoarder = msg.sender;
        }
        _mint(msg.sender, tokenID);
    }

    function redeem(uint256 tokenID) external {
        require(!_wasBurned.get(tokenID));
        require(_isApprovedOrOwner(msg.sender, tokenID));
        _burn(tokenID);
        _wasBurned.setTo(tokenID, true);
        nuToken.transfer(msg.sender, ONE_NU);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory output) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory meta = string.concat(
            '{"name": "NuCypher OG #',
            Strings.toString(tokenId),
            '", "description": "',
            _description,
            '", "attributes": [',
            renderTraits(tokenId),
            '], "image": "',
            _imageURI,
            '", "animation_url": "',
            _imageURI,
            '"}'
        );
        output = string.concat('data:application/json,', meta);
        return output;
    }

    function setBitIf(uint256 bitmap, Trait index, bool condition) internal pure returns(uint256){
        return bitmap | (condition ? 1 << uint256(index) : 0);
    }

    function traits(uint256 tokenID) internal view returns(uint256 bitmap){
        address staker = stakingEscrow.stakers(tokenID);
        StakingEscrow.StakerInfo memory info = stakingEscrow.stakerInfo(staker);

        // # if stakingProvider: Seeker
        // # if completedWork: Diligent
        // # if value == 0: Pragmatic
        // # if value > 0: Believer
        // # if vestingReleaseTimestamp > 0: SAFT --> "Accomplice"
        // # if workerStartPeriod = 0: Never set worker --> forgetful
        // # if address starts with 0x0000 --> Steamer.eth --> "Hoarder"
        // # if not nextCommittedPeriod and not lastCommittedPeriod --> sluggish
        // # if index < 100: EarlyBird
        // # if 100 < index < 2050: Follower
        // # if index > 2050: Laggard

        bitmap = setBitIf(bitmap, Trait.Seeker, info.stakingProvider != address(0));
        bitmap = setBitIf(bitmap, Trait.Diligent, info.completedWork > 0);
        bitmap = setBitIf(bitmap, Trait.Pragmatic, info.value == 0);
        bitmap = setBitIf(bitmap, Trait.Believer, info.value > 0);
        bitmap = setBitIf(bitmap, Trait.Accomplice, info.vestingReleaseTimestamp > 0);
        bitmap = setBitIf(bitmap, Trait.Hoarder, staker == _hoarder);
        bitmap = setBitIf(bitmap, Trait.Forgetful, info.workerStartPeriod == 0);
        bitmap = setBitIf(bitmap, Trait.Sluggish, info.workerStartPeriod > 0 && info.nextCommittedPeriod == 0 && info.lastCommittedPeriod == 0);
        bitmap = setBitIf(bitmap, Trait.EarlyBird, tokenID < 100);
        bitmap = setBitIf(bitmap, Trait.Follower, 100 <= tokenID && tokenID < 2050);
        bitmap = setBitIf(bitmap, Trait.Laggard, tokenID >= 2050);
        return bitmap;
    }

    function renderBitmap(uint256 bitmap) internal view returns (string memory attributes) {
        bool needsComma = false;
        for (uint i=0; i<traitName.length; i++){
            if(bitmap % 2 == 1){
                attributes = string.concat(attributes, needsComma? ', ' : '', '{"value": "', traitName[i], '"}');
                needsComma = true;
            }
            bitmap = bitmap >> 1;
        }
    }

    function renderTraits(uint256 tokenID) public view returns (string memory attributes) {
        return renderBitmap(traits(tokenID));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractUri(string memory uri) external {
        require(msg.sender == owner);
        _contractURI = uri;
    }

    function setImageUri(string memory uri) external {
        require(msg.sender == owner);
        _imageURI = uri;
    }

    function setDescription(string memory description) external {
        require(msg.sender == owner);
        _description = description;
    }
}