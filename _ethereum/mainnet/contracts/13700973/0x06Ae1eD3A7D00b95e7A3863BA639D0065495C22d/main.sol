// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import "./helpers.sol";
import "./interface.sol";
import "./SafeMath.sol";

contract MaticProtocolStaking is Helpers {
    string public constant name = "MaticProtocol-v1";

    using SafeMath for uint256;

    function delegate(
        uint256 validatorId,
        uint256 amount,
        uint256 minShare,
        uint256 getId
    ) external payable {
        uint256 delegationAmount = getUint(getId, amount);
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.buyVoucher(delegationAmount, minShare);
    }

    function delegateMultiple(
        uint256[] memory validatorIds,
        uint256 amount,
        uint256[] memory portions,
        uint256[] memory minShares,
        uint256 getId
    ) external payable {
        require(
            portions.length == validatorIds.length,
            "Validator and Portion length doesnt match"
        );
        uint256 delegationAmount = getUint(getId, amount);
        uint256 totalPortions = 0;

        uint256[] memory validatorAmount = new uint256[](validatorIds.length);

        for (uint256 position = 0; position < portions.length; position++) {
            validatorAmount[position] = portions[position]
                .mul(delegationAmount)
                .div(PORTIONS_SUM);
            totalPortions = totalPortions + portions[position];
        }

        require(totalPortions == PORTIONS_SUM, "Portion Mismatch");

        maticToken.approve(address(stakeManagerProxy), delegationAmount);

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.buyVoucher(
                validatorAmount[i],
                minShares[i]
            );
        }
    }

    function withdrawRewards(uint256 validatorId, uint256 setId)
        external
        payable
    {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        uint256 initialBal = getTokenBal(maticToken);
        validatorContractAddress.withdrawRewards();
        uint256 finalBal = getTokenBal(maticToken);
        uint256 rewards = sub(finalBal, initialBal);
        setUint(setId, rewards);
    }

    function withdrawRewardsMultiple(
        uint256[] memory validatorIds,
        uint256 setId
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        uint256 initialBal = getTokenBal(maticToken);
        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.withdrawRewards();
        }
        uint256 finalBal = getTokenBal(maticToken);
        uint256 rewards = sub(finalBal, initialBal);
        setUint(setId, rewards);
    }

    function sellVoucher(
        uint256 validatorId,
        uint256 claimAmount,
        uint256 maximumSharesToBurn
    ) external payable {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.sellVoucher_new(
            claimAmount,
            maximumSharesToBurn
        );
    }

    function sellVoucherMultiple(
        uint256[] memory validatorIds,
        uint256[] memory claimAmounts,
        uint256[] memory maximumSharesToBurns
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");
        require((validatorIds.length == claimAmounts.length), "!claimAmount ");
        require(
            (validatorIds.length == maximumSharesToBurns.length),
            "!maximumSharesToBurns "
        );

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.sellVoucher_new(
                claimAmounts[i],
                maximumSharesToBurns[i]
            );
        }
    }

    function restake(uint256 validatorId) external payable {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.restake();
    }

    function restakeMultiple(uint256[] memory validatorIds) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.restake();
        }
    }

    function unstakeClaimedTokens(uint256 validatorId, uint256 unbondNonce)
        external
        payable
    {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.unstakeClaimTokens_new(unbondNonce);
    }

    function unstakeClaimedTokensMultiple(
        uint256[] memory validatorIds,
        uint256[] memory unbondNonces
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.unstakeClaimTokens_new(unbondNonces[i]);
        }
    }
}
