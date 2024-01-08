//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Counters.sol";
import "./SafeERC20.sol";
import "./IFeeExternal.sol";
import "./LibFeeExternal.sol";
import "./LibRouter.sol";

contract FeeExternalFacet is IFeeExternal {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    /**
     *  @notice Construct a new FeeExternal contract
     *  @param _externalFee The initial external fee in ALBT tokens (flat)
     *  @param _externalFeeAddress The initial receiving address for the external fee
     */
    function initFeeExternal(uint256 _externalFee, address _externalFeeAddress) external override {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        require(!fes.initialized, "FeeExternal: already initialized");
        fes.initialized = true;
        fes.externalFee = _externalFee;
        fes.externalFeeAddress = _externalFeeAddress;
    }

    /// @return The currently set external fee
    function externalFee() external view override returns (uint256) {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        return fes.externalFee;
    }

    /// @return The currently set external fee address
    function externalFeeAddress() external view override returns (address) {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        return fes.externalFeeAddress;
    }

    /**
     *  @notice Sets the external fee for this chain
     *  @param _externalFee The new external fee
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setExternalFee(uint256 _externalFee, bytes[] calldata _signatures)
        onlyValidSignatures(_signatures.length)
        external override
    {
        bytes32 ethHash = computeExternalFeeUpdateMessage(_externalFee);
        LibGovernance.validateSignatures(ethHash, _signatures);
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        fes.externalFee = _externalFee;
        emit ExternalFeeSet(msg.sender, _externalFee);
        gs.administrativeNonce.increment();
    }

    /**
     *  @notice Sets the address collecting the external fees
     *  @param _externalFeeAddress The new external fee account
     *  @param _signatures The array of signatures from the members, authorising the operation
     */
    function setExternalFeeAddress(address _externalFeeAddress, bytes[] calldata _signatures)
        onlyValidSignatures(_signatures.length)
        external override
    {
        bytes32 ethHash = computeExternalFeeAddressUpdateMessage(_externalFeeAddress);
        LibGovernance.validateSignatures(ethHash, _signatures);
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        fes.externalFeeAddress = _externalFeeAddress;
        emit ExternalFeeAddressSet(msg.sender, _externalFeeAddress);
        gs.administrativeNonce.increment();
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for fee updates
     *  @param _newExternalFee The fee that was used when creating the validator signatures
    */
    function computeExternalFeeUpdateMessage(uint256 _newExternalFee) internal view returns (bytes32) {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        bytes32 hashedData =
            keccak256(
                abi.encode(fes.externalFee, _newExternalFee, gs.administrativeNonce.current())
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
    }

    /**
     *  @notice Computes the Eth signed message to use for extracting signature signers for address updates
     *  @param _newExternalFeeAddress The address that was used when creating the validator signatures
    */
    function computeExternalFeeAddressUpdateMessage(address _newExternalFeeAddress) internal view returns (bytes32) {
        LibFeeExternal.Storage storage fes = LibFeeExternal.feeExternalStorage();
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        bytes32 hashedData =
            keccak256(
                abi.encode(fes.externalFeeAddress, _newExternalFeeAddress, gs.administrativeNonce.current())
            );
        return ECDSA.toEthSignedMessageHash(hashedData);
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
