// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./GelatoConditionsStandard.sol";
import "./SafeMath.sol";
import "./IGelatoCore.sol";
import "./GelatoBytes.sol";

/// @notice A general contract for retrieving and comparing 2 uints from 2 contracts.
/// @dev This contract only works if the refContracts fns returndata has a uint in
/// the first 32-byte position.
contract ConditionCompareUintsFromTwoSources is GelatoConditionsStandard {
    using GelatoBytes for bytes;
    using SafeMath for uint256;

    /// @notice Helper to encode the Condition.data field off-chain
    function getConditionData(
        address _sourceA,
        address _sourceB,
        bytes calldata _sourceAData,
        bytes calldata _sourceBData,
        uint256 _minSpread
    ) public pure virtual returns (bytes memory) {
        return
            abi.encode(
                _sourceA,
                _sourceB,
                _sourceAData,
                _sourceBData,
                _minSpread
            );
    }

    /// @notice Gelato Standard Condition function.
    /// @dev Every Gelato Condition must have this function selector as entry point.
    /// @param _conditionData The encoded data from getConditionData()
    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            address _sourceA,
            address _sourceB,
            bytes memory _sourceAData,
            bytes memory _sourceBData,
            uint256 _minSpread
        ) =
            abi.decode(
                _conditionData,
                (address, address, bytes, bytes, uint256)
            );
        return
            compare(_sourceA, _sourceB, _sourceAData, _sourceBData, _minSpread);
    }

    /// @notice Compares 2 values from sourceA and sourceB to check if minSpread is there.
    /// @dev If you want to trigger when ContractA uint is greater than or equal
    /// to ContractB by _minSpread: (ContractA=_sourceA, ContractB=_sourceB)
    /// For the reverse (lower than/equal to): (ContractA=_sourceB, ContractB=_sourceA)
    /// @param _sourceA The first contract that returns a uint for comparison.
    /// @param _sourceB The second contract that returns a uint256 for comparison.
    /// @param _sourceAData Payload for retrieving the uint from _sourceA.
    /// @param _sourceBData Payload for retrieving the uint from _sourceB.
    /// @param _minSpread The minimum diff between sourceA and sourceB
    ///  for the Condition to be relevant.
    /// @return OK if the Condition is fulfilled.
    function compare(
        address _sourceA,
        address _sourceB,
        bytes memory _sourceAData,
        bytes memory _sourceBData,
        uint256 _minSpread
    ) public view virtual returns (string memory) {
        // Retrieve uint256 from sourceA
        (bool success, bytes memory returndata) =
            _sourceA.staticcall(_sourceAData);
        if (!success) {
            return
                returndata.returnError(
                    "ConditionCompareTwoUints.compare._sourceA:"
                );
        }
        uint256 a = abi.decode(returndata, (uint256));

        // Retrieve uint256 from sourceB
        (success, returndata) = _sourceB.staticcall(_sourceBData);
        if (!success) {
            return
                returndata.returnError(
                    "ConditionCompareTwoUints.compare._sourceB:"
                );
        }
        uint256 b = abi.decode(returndata, (uint256));

        if (a >= b.add(_minSpread)) return OK;
        return "ANotGreaterOrEqualToBbyMinspread";
    }
}
