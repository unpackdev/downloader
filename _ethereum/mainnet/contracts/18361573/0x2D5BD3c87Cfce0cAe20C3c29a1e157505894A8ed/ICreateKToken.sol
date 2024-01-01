// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;
import "./IKyokoPool.sol";

interface ICreateKToken {
    event CreateKToken(address user, address kToken);

    function createKToken(
        address weth,
        address provider,
        address treasury,
        uint256 reserveId,
        string memory symbol,
        string memory s1,
        string memory s2
    ) external returns (address stableDebtAddress);
}