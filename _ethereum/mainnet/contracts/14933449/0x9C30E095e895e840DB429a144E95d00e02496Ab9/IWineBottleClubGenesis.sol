//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

import "./IERC721.sol";

interface IWineBottleClubGenesis is IERC721 {
    function publicMint(address to, uint256 count) external payable;

    function totalSupply() external view returns (uint256);
}
