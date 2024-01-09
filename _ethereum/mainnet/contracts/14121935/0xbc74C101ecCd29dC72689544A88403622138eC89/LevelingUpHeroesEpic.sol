// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity 0.8.10;

import "./BaseDutchAuctionERC721A.sol";

contract LevelingUpHeroesEpic is BaseDutchAuctionERC721A {
    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint, 
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _price
    )
        BaseDutchAuctionERC721A(payees, shares, name, symbol, _whitelistMaxMint, _publicListMaxMint, _nonReservedMax, _reservedMax, _price)
    {
    }
}