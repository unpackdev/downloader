//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IMToken.sol";
import "./IClaimControl.sol";

contract Avatar is OwnableUpgradeable, ERC721Upgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    struct ClaimRecord {
        uint256 calculateTime;
        uint256 haveClaimed;
        uint256 notClaimed;
    }

    address public mintControl;

    mapping(address => EnumerableSet.UintSet) private userNFTs;

    mapping(address => ClaimRecord) userClaimRecord;
    mapping(uint256 => uint256) public haveBurnForMToken;

    string private baseTokenURI;

    IMToken  public iMToken;
    IClaimControl public claimControl;

    function initialize(string calldata name, string calldata symbol) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init();
    }

    function setBaseURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setIMToken(IMToken addr) public onlyOwner {
        iMToken = addr;
    }

    function setClaimControlAddress(IClaimControl addr) public onlyOwner {
        claimControl = addr;
    }

    function setMintControlAddress(address _addr) public onlyOwner {
        mintControl = _addr;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId), "TokenURI: URI query for nonexistent token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json")) : "";
    }

    function claim(address to, bool needMint) internal {
        ClaimRecord storage cr = userClaimRecord[to];
        uint256 b = balanceOf(to);
        uint256 haveClaimed = claimControl.canClaimedForOneNFT(cr.calculateTime);
        uint256 canClaimForOne = claimControl.canClaimedForOneNFT(block.timestamp);
        cr.calculateTime = block.timestamp;
        if (canClaimForOne > haveClaimed || cr.notClaimed > 0) {
            uint256 received = b * (canClaimForOne - haveClaimed);
            cr.notClaimed += received;
            if (needMint) {
                iMToken.mint(to, cr.notClaimed);
                cr.haveClaimed += cr.notClaimed;
                cr.notClaimed = 0;
            }
        }
    }

    function ClaimAll() external nonReentrant {
        claim(msg.sender, true);
    }

    function batchMint(address to, uint256 startTokenId, uint256 amount) external {
        require(msg.sender == mintControl, "batchMint: owner not allowed");

        claim(to, false);

        uint256 canClaimForOne = claimControl.canClaimedForOneNFT(block.timestamp);
        if (canClaimForOne > 0) {
            iMToken.burnSupply(msg.sender, amount * canClaimForOne);
        }
        uint256 id = startTokenId;
        for (uint i = 0; i < amount; i ++) {
            id += 1;
            userNFTs[to].add(id);
            haveBurnForMToken[id] = canClaimForOne;
            _mint(to, id);
        }

    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        claim(to, false);
        claim(from, false);

        super._transfer(from, to, tokenId);
        userNFTs[from].remove(tokenId);
        userNFTs[to].add(tokenId);
    }

    function getUserNFTs(address to) public view returns (uint256[] memory){
        return userNFTs[to].values();
    }

    function claimed(address to) public view returns (uint256) {
        ClaimRecord memory cr = userClaimRecord[to];
        uint256 b = balanceOf(to);
        uint256 haveClaimed = claimControl.canClaimedForOneNFT(cr.calculateTime);
        uint256 canClaimForOne = claimControl.canClaimedForOneNFT(block.timestamp);
        return b * (canClaimForOne - haveClaimed) + cr.notClaimed;
    }
}