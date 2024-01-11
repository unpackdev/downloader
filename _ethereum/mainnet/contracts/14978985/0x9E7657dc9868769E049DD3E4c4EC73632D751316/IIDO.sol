// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ISharedData.sol";
import "./IAccessControlUpgradeable.sol";

interface IIDO is IAccessControlUpgradeable, ISharedData {
    event Claim(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event DepositToken(
        address indexed currency,
        address indexed user,
        uint256 amount
    );

    function initialize(IDOParams memory params) external;

    function deposit() external payable;

    function claim() external;

    function refund() external;

    function transferBalance(uint256 tokenId) external;

    function getStatus() external view returns (string memory);

    function pause() external;

    function unpause() external;
}
