// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./IFeeCalculator.sol";
import "./LibDiamond.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";

contract FeeCalculatorFacet is IFeeCalculator {
    using SafeERC20 for IERC20;

    /// @notice Construct a new FeeCalculator contract
    /// @param _precision The precision for every fee calculator
    function initFeeCalculator(uint256 _precision) external override {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator
            .feeCalculatorStorage();
        require(!fcs.initialized, "FeeCalculatorFacet: already initialized");
        require(
            _precision >= 10,
            "FeeCalculatorFacet: precision must not be single-digit"
        );
        fcs.initialized = true;
        fcs.precision = _precision;
    }

    /// @return The current precision for service fee calculations of tokens
    function serviceFeePrecision() external view override returns (uint256) {
        return LibFeeCalculator.precision();
    }

    /// @notice Sets the service fee for a token
    /// @param _token The target token
    /// @param _serviceFeePercentage The new service fee
    function setServiceFee(address _token, uint256 _serviceFeePercentage)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibFeeCalculator.setServiceFee(_token, _serviceFeePercentage);
        emit ServiceFeeSet(msg.sender, _token, _serviceFeePercentage);
    }

    /// @param _account The address of a validator
    /// @param _token The token address
    /// @return The total amount of claimed tokens by the provided validator address
    function claimedRewardsPerAccount(address _account, address _token)
        external
        view
        override
        returns (uint256)
    {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator
            .feeCalculatorStorage();
        return
            fcs.nativeTokenFeeCalculators[_token].claimedRewardsPerAccount[
                _account
            ];
    }

    /// @notice Returns all data for a specific fee calculator
    /// @param _token The target token
    /// @return serviceFeePercentage The current service fee
    /// @return feesAccrued Total fees accrued since contract deployment
    /// @return previousAccrued Total fees accrued up to the last point a member claimed rewards
    /// @return accumulator Accumulates rewards on a per-member basis
    function tokenFeeData(address _token)
        external
        view
        override
        returns (
            uint256 serviceFeePercentage,
            uint256 feesAccrued,
            uint256 previousAccrued,
            uint256 accumulator
        )
    {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator
            .feeCalculatorStorage();
        LibFeeCalculator.FeeCalculator storage fc = fcs
            .nativeTokenFeeCalculators[_token];

        return (
            fc.serviceFeePercentage,
            fc.feesAccrued,
            fc.previousAccrued,
            fc.accumulator
        );
    }

    /// @notice Sends out the reward accumulated by the member for the specified token
    /// to the member admin
    function claim(address _token, address _member)
        external
        override
        onlyMember(_member)
    {
        LibGovernance.enforceNotPaused();
        uint256 claimableAmount = LibFeeCalculator.claimReward(_member, _token);
        address memberAdmin = LibGovernance.memberAdmin(_member);
        IERC20(_token).safeTransfer(memberAdmin, claimableAmount);
        emit Claim(_member, memberAdmin, _token, claimableAmount);
    }

    /// @notice Accepts only `msg.sender` part of the members
    modifier onlyMember(address _member) {
        require(
            LibGovernance.isMember(_member),
            "FeeCalculatorFacet: _member is not a member"
        );
        _;
    }
}
