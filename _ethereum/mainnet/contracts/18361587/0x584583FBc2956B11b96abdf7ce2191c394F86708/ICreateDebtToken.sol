// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;
import "./IKyokoPool.sol";

interface ICreateDebtToken {
    event CreateVariableToken(address user, address variableDebtAddress);
    event CreateStableToken(address user, address stableDebtAddress);

    function createVariableDebtToken(
        address weth,
        address provider,
        uint256 reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external returns (address variableAddress);
    

    function createStableDebtToken(
        address weth,
        address provider,
        uint256 reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external returns (address stableDebtAddress);
}