// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;
import "./IGovernable.sol";

interface IMirrorTokenLogic is IGovernable {
    function version() external returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function setTreasuryConfig(address newTreasuryConfig) external;
}
