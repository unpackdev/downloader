// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Counters.sol";
import "./IDiamondCut.sol";
import "./LibDiamond.sol";
import "./LibGovernance.sol";

contract DiamondCutFacet is IDiamondCut {
    using Counters for Counters.Counter;

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    /// @param _signatures The signatures of between n/2 and n validators for this upgrade
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata,
        bytes[] calldata _signatures
    ) external override onlyValidSignatures(_signatures.length) {
        bytes32 ethHash = computeDiamondCutMessage(_diamondCut);
        LibGovernance.validateSignatures(ethHash, _signatures);
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    ///  @notice Computes the bytes32 ethereum signed message hash of the signature
    function computeDiamondCutMessage(IDiamondCut.FacetCut[] memory _diamondCut) internal view returns (bytes32) {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        bytes32 hashedData =
            keccak256(
                abi.encode(_diamondCut, gs.administrativeNonce.current())
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
}
