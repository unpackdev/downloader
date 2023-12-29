// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC721Enumerable.sol";

interface IDZooNFT is IERC721Enumerable {
    function mint(address to, uint256 amount) external;

    function MAX_SUPPLY() external view returns (uint256);
}
