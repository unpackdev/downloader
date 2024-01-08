// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";


interface IBallerBars is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function burnUnclaimed(uint256[] memory _tokenIds, uint256 amount) external;
    function _calculateBoost(string memory _hash) external view returns (uint256);
}
