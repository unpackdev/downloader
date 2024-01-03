// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./ITransferHook.sol";
import "./StakedToken.sol";

/**
 * @title StakedBEthix
 * @notice StakedToken with B-ETHIX token as staked token
 * @author Aave / Ethichub
 **/
contract StakedBETHIX is StakedToken {
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
            'Staked B-ETHIX/DAI',
            'stkB-ETHIX/DAI',
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
