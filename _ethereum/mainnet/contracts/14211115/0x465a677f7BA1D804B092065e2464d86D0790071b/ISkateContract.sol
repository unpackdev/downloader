// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./IERC721.sol";

interface ISkateContract is IERC721 {
    function auctionStart() external;

    function settleCurrentAndCreateNewAuction() external;

    // function burn(uint256 gnarId) external;
    function owner() external returns (address);

    function transferOwnership(address) external;
}
