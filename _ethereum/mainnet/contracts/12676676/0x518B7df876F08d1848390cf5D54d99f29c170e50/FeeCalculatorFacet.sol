//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Counters.sol";
import "./SafeERC20.sol";
import "./IFeeCalculator.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";

contract FeeCalculatorFacet is IFeeCalculator {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /**
     *  @notice Construct a new FeeCalculator contract
     *  @param _serviceFee The initial service fee in ALBT tokens (flat)
     */
    function initFeeCalculator(uint256 _serviceFee) external override {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        require(!fcs.initialized, "FeeCalculator: already initialized");
        fcs.initialized = true;
        fcs.serviceFee = _serviceFee;
    }

    /// @return The currently set service fee
    function serviceFee() external view override returns (uint256) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        return fcs.serviceFee;
    }

    /**
     *  @notice Sets the service fee for this chain
     *  @param _serviceFee The new service fee
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setServiceFee(uint256 _serviceFee, bytes[] calldata _signatures)
        onlyValidSignatures(_signatures.length)
        external override
    {
        bytes32 ethHash = computeFeeUpdateMessage(_serviceFee);
        LibGovernance.validateSignatures(ethHash, _signatures);
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        fcs.serviceFee = _serviceFee;
        emit ServiceFeeSet(msg.sender, _serviceFee);
        gs.administrativeNonce.increment();
    }

    /// @return The current feesAccrued counter
    function feesAccrued() external view override returns (uint256) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        return fcs.feesAccrued;
    }

    /// @return The feesAccrued counter before the last reward distribution
    function previousAccrued() external view override returns (uint256) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        return fcs.previousAccrued;
    }

    /// @return The current accumulator counter
    function accumulator() external view override returns (uint256) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        return fcs.accumulator;
    }

    /**
     *  @param _account The address of a validator
     *  @return The total amount of ALBT claimed by the provided validator address
     */
    function claimedRewardsPerAccount(address _account) external view override returns (uint256) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        return fcs.claimedRewardsPerAccount[_account];
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for fee updates
     *  @param _newServiceFee The fee that was used when creating the validator signatures
    */
    function computeFeeUpdateMessage(uint256 _newServiceFee) internal view returns (bytes32) {
        LibFeeCalculator.Storage storage fcs = LibFeeCalculator.feeCalculatorStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        bytes32 hashedData =
            keccak256(
                abi.encode(fcs.serviceFee, _newServiceFee, gs.administrativeNonce.current())
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /// @notice Sends out the reward in ALBT accumulated by the caller
    function claim() external override onlyMember {
        LibRouter.Storage storage rs = LibRouter.routerStorage();
        uint256 claimableAmount = LibFeeCalculator.claimReward(msg.sender);
        IERC20(rs.albtToken).safeTransfer(msg.sender, claimableAmount);
        emit Claim(msg.sender, claimableAmount);
    }

    /// @notice Accepts number of signatures in the range (n/2; n] where n is the number of members
    modifier onlyValidSignatures(uint256 _n) {
        uint256 members = LibGovernance.membersCount();
        require(_n <= members, "Governance: Invalid number of signatures");
        require(_n > members / 2, "Governance: Invalid number of signatures");
        _;
    }

    /// @notice Accepts only `msg.sender` part of the members
    modifier onlyMember() {
        require(LibGovernance.isMember(msg.sender), "Governance: msg.sender is not a member");
        _;
    }
}
