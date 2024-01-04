// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import "./IERC20.sol";

contract Bank is IERC20 {
    /// @dev Return the total ETH entitled to the token holders. Be careful of unaccrued interests.
    function totalETH() public view returns (uint256);

    /// @dev Add more ETH to the bank. Hope to get some good returns.
    function deposit() external payable;

    /// @dev Withdraw ETH from the bank by burning the share tokens.
    function withdraw(uint256 share) external;
}
