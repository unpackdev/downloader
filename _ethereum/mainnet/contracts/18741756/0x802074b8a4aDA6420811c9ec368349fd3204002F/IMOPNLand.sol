// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC721.sol";

interface IMOPNLand is IERC721 {
    function auctionMint(address to, uint256 amount) external;

    function nextTokenId() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}
