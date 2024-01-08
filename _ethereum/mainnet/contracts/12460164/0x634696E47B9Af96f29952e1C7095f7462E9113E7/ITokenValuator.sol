//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface ITokenValuator {
    function valuate(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view returns (uint256);

    function isConfigured(address token) external view returns (bool);

    function requireIsConfigured(address token) external view;

    function hasValuation(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view returns (bool);

    function requireHasValuation(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view;
}
