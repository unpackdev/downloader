// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./ERC721Interface.sol";

contract FishChips is ERC20Capped, Ownable {
    uint256 private _tokensPerDay = 10 * 10**decimals();
    uint256 private _startTime = 1636625462; //Block 13597750 (Nov-11-2021 11:11:02 PM +UTC)
    address private _genesisFishAddress = address(0x0);

    //Mapping tokenId->claimedTokens
    mapping(uint256 => uint256) private _tokenClaimedMapping;

    constructor()
        ERC20("Fish-Tank Pearls", "PEARL$")
        ERC20Capped(1111 * 365 * 10 * 10**decimals())
    {}

    function setGenesisFishAddress(address genesisFishAddress)
        external
        onlyOwner
    {
        _genesisFishAddress = genesisFishAddress;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function getGenesisFishAddress() external view returns (address) {
        return _genesisFishAddress;
    }

    function claim(uint256[] memory tokenIds) external {
        require(tokenIds.length > 0, "No tokens specified");
        require(_genesisFishAddress != address(0x0), "Genesis Fish not set");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            claimOne(tokenIds[i]);
        }
    }

    function claimOne(uint256 tokenId) private {
        uint256 claimableTokens = calcClaimableTokens(tokenId);
        require(claimableTokens > 0, "No tokens to claim");

        _tokenClaimedMapping[tokenId] =
            _tokenClaimedMapping[tokenId] +
            claimableTokens;

        ERC721Interface erc721 = ERC721Interface(_genesisFishAddress);
        address owner = erc721.ownerOf(tokenId);

        super._mint(owner, claimableTokens);
    }

    function calcClaimableTokens(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 daysSinceStart = calcDaysSinceStart();
        uint256 maxPossibleTokens = calcTokensPerNft(daysSinceStart);
        uint256 claimedAmount = _tokenClaimedMapping[tokenId];
        return maxPossibleTokens - claimedAmount;
    }

    function calcDaysSinceStart() public view returns (uint256) {
        return (block.timestamp - _startTime) / 24 hours;
    }

    function calcTokensPerNft(uint256 numberOfDays)
        public
        view
        returns (uint256)
    {
        return numberOfDays * _tokensPerDay;
    }
}
