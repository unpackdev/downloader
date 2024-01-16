// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC721A.sol";

interface IBeepBoopExoSuit {
    function adminMint(address recipient, uint256 quantity) external;

    function transferOwnership(address newOwner) external;

    function gameMintPrice() external returns (uint256);

    function gameMintable() external returns (bool);

    function owner() external view returns (address);
}
