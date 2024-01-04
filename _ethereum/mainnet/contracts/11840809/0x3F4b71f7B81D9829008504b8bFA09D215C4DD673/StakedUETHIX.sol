// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./ITransferHook.sol";
import "./StakedToken.sol";

/**
 * @title StakedUEthix
 * @notice StakedToken with U-ETHIX token as staked token
 * @author Aave / Ethichub
 **/
contract StakedUETHIX is StakedToken {
    function initialize(
        IERC20Upgradeable stakedToken,
        ITransferHook ethixGovernance,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        IReserve rewardsVault,
        address emissionManager,
        uint128 distributionDuration
    ) public initializer {
        __StakedToken_init(
            'Staked U-ETHIX/ETH',
            'stkU-ETHIX/ETH',
            18,
            ethixGovernance,
            stakedToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            emissionManager,
            distributionDuration
        );
    }
}
