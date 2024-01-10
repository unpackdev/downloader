// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import "./helpers.sol";
import "./interface.sol";
import "./SafeMath.sol";

/**
 * Matic protocol staking connectors provide function to delegate, undelegate, restake and withdraw functions for matic tokens.
 */
contract MaticProtocolStaking is Helpers {
    string public constant name = "MaticProtocol-v1";

    using SafeMath for uint256;

    /**
     *  @notice Delegate matic token to single validator.
     *
     *  @param validatorContractAddress Validator contract address to whom delegation would be done.
     *  @param amount Total amount of matic to be delegated.
     *  @param minShare minimum share of validator pool should be recieved after delegation.
     *  @param getId If non zero than it will override amount and read it from memory contract.
     */
    function delegate(
        IValidatorShareProxy validatorContractAddress,
        uint256 amount,
        uint256 minShare,
        uint256 getId
    ) external payable {
        uint256 delegationAmount = getUint(getId, amount);
        require(address(validatorContractAddress) != address(0), "!Validator");
        maticToken.approve(address(stakeManagerProxy), delegationAmount);
        validatorContractAddress.buyVoucher(delegationAmount, minShare);
    }

    /**
     * @notice Delegate matic token to multiple validators in one go.
     *
     * @param validatorAddresses List of validator addresses to whom delegation will be done.
     * @param amount Total amount of matic tokens to be delegated.
     * @param portions List of percentage from `amount` to delegate to each validator.
     * @param minShares List of minshares recieved for each validators.
     * @param getId If non zero than it will override amount and read it from memory contract.
     */
    function delegateMultiple(
        IValidatorShareProxy[] memory validatorAddresses,
        uint256 amount,
        uint256[] memory portions,
        uint256[] memory minShares,
        uint256 getId
    ) external payable {
        require(
            validatorAddresses.length > 0,
            "! validators Ids length"
        );
        require(
            portions.length == validatorAddresses.length,
            "Validator and Portion length doesnt match"
        );

        require(
            validatorAddresses.length == minShares.length,
            "Validator and min shares length mismatch"
        );

        uint256 delegationAmount = getUint(getId, amount);
        uint256 totalPortions = 0;

        uint256[] memory validatorAmount = new uint256[](
            validatorAddresses.length
        );

        uint256 portionsSize = portions.length;

        for (uint256 position = 0; position < portionsSize; position++) {
            validatorAmount[position] = portions[position]
                .mul(delegationAmount)
                .div(PORTIONS_SUM);
            totalPortions = totalPortions + portions[position];
        }

        require(totalPortions == PORTIONS_SUM, "Portion Mismatch");

        maticToken.approve(address(stakeManagerProxy), delegationAmount);

        for (uint256 i = 0; i < portionsSize; i++) {
            IValidatorShareProxy validatorContractAddress = validatorAddresses[
                i
            ];
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

    /**
     * @notice Withdraw matic token rewards generated after delegation.
     *
     * @param validatorContractAddress Id of Validator.
     * @param setId If set to non zero it will set reward amount to memory contract to be used by subsequent connectors.
     */
    function withdrawRewards(
        IValidatorShareProxy validatorContractAddress,
        uint256 setId
    ) external payable {
        require(address(validatorContractAddress) != address(0), "!Validator");
        uint256 initialBal = getTokenBal(maticToken);
        validatorContractAddress.withdrawRewards();
        uint256 finalBal = getTokenBal(maticToken);
        uint256 rewards = sub(finalBal, initialBal);
        setUint(setId, rewards);
    }

    /**
     * @notice Withdraw matic token rewards generated after delegationc from multiple validators.
     *
     * @param validatorContractAddresses List of validators contract addresses.
     * @param setId If set to non zero it will set reward amount to memory contract to be used by subsequent connectors.
     */
    function withdrawRewardsMultiple(
        IValidatorShareProxy[] memory validatorContractAddresses,
        uint256 setId
    ) external payable {
        require(
            validatorContractAddresses.length > 0,
            "! validators Ids length"
        );

        uint256 initialBal = getTokenBal(maticToken);
        uint256 validatorsSize = validatorContractAddresses.length;
        for (uint256 i = 0; i < validatorsSize; i++) {
            IValidatorShareProxy validatorContractAddress = validatorContractAddresses[
                    i
                ];
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

    /** 
     * @notice Trigger undelegation process from a single validator.
     * 
     * @param validatorContractAddress Validator contract address.
     * @param claimAmount Total amount to be undelegated. 
     / @param maximumSharesToBurn Maximum shares to be burned.
     */
    function sellVoucher(
        IValidatorShareProxy validatorContractAddress,
        uint256 claimAmount,
        uint256 maximumSharesToBurn
    ) external payable {
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.sellVoucher_new(
            claimAmount,
            maximumSharesToBurn
        );
    }

    /** 
     * @notice Trigger undelegation process from multiple validators.
     * 
     * @param validatorContractAddresses List of validator contract address.
     * @param claimAmounts List of claim amounts. 
     / @param maximumSharesToBurns List of maximum shares to burn for each validators. 
     */
    function sellVoucherMultiple(
        IValidatorShareProxy[] memory validatorContractAddresses,
        uint256[] memory claimAmounts,
        uint256[] memory maximumSharesToBurns
    ) external payable {
        require(
            validatorContractAddresses.length > 0,
            "! validators Ids length"
        );
        require(
            (validatorContractAddresses.length == claimAmounts.length),
            "!claimAmount "
        );
        require(
            (validatorContractAddresses.length == maximumSharesToBurns.length),
            "!maximumSharesToBurns "
        );

        uint256 validatorsSize = validatorContractAddresses.length;
        for (uint256 i = 0; i < validatorsSize; i++) {
            IValidatorShareProxy validatorContractAddress = validatorContractAddresses[
                    i
                ];
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

    /**
     * @notice Restake rewards generated by delegation to a validator.
     *
     * @param validatorContractAddress Validator contract address.
     */
    function restake(IValidatorShareProxy validatorContractAddress)
        external
        payable
    {
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.restake();
    }

    /**
     * @notice Restake rewards generated by delegation to a multiple validators.
     *
     * @param validatorContractAddresses List of validator contract address.
     */
    function restakeMultiple(
        IValidatorShareProxy[] memory validatorContractAddresses
    ) external payable {
        require(
            validatorContractAddresses.length > 0,
            "! validators Ids length"
        );

        uint256 validatorsSize = validatorContractAddresses.length;
        for (uint256 i = 0; i < validatorsSize; i++) {
            IValidatorShareProxy validatorContractAddress = validatorContractAddresses[
                    i
                ];
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.restake();
        }
    }

    /**
     * @notice Withdraw undelegated token after unbonding period is passed.
     *
     * @param validatorContractAddress Validator contract address.
     * @param unbondNonce Nonce of unbond request.
     */
    function unstakeClaimedTokens(
        IValidatorShareProxy validatorContractAddress,
        uint256 unbondNonce
    ) external payable {
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.unstakeClaimTokens_new(unbondNonce);
    }

    /**
     * @notice Multiple Withdraw undelegated tokens after unbonding period is passed.
     *
     * @param validatorContractAddresses Validator contract addresses.
     * @param unbondNonces List of unbond nonces.
     */
    function unstakeClaimedTokensMultiple(
        IValidatorShareProxy[] memory validatorContractAddresses,
        uint256[] memory unbondNonces
    ) external payable {
        require(
            validatorContractAddresses.length > 0,
            "! validators Ids length"
        );

        uint256 validatorsSize = validatorContractAddresses.length;
        for (uint256 i = 0; i < validatorsSize; i++) {
            IValidatorShareProxy validatorContractAddress = validatorContractAddresses[
                    i
                ];
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.unstakeClaimTokens_new(unbondNonces[i]);
        }
    }
}
