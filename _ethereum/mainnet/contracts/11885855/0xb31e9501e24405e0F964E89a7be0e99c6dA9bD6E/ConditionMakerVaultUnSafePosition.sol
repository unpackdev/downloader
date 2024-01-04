// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./CGelato.sol";
import "./IConditionMakerVaultUnsafeOSM.sol";

/// @title ConditionMakerVaultUnSafePosition
/// @notice Condition tracking Maker Vault safety requirements.
/// @author Gelato Team
contract ConditionMakerVaultUnSafePosition is GelatoConditionsStandard {
    /// @notice Standard GelatoCore system function
    /// @dev A standard interface for GelatoCore to read Conditions
    /// @param _conditionData The data you get from `getConditionData()`
    /// @return OK if the Condition is there, else some error message.
    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            uint256 _vaultID,
            address _priceOracle,
            bytes memory _oraclePeekPayload,
            bytes memory _oraclePeepPayload,
            uint256 _minPeekLimit,
            uint256 _minPeepLimit
        ) =
            abi.decode(
                _conditionData[4:],
                (uint256, address, bytes, bytes, uint256, uint256)
            );

        return
            _isOk(
                isVaultUnsafeOSM(
                    _vaultID,
                    _priceOracle,
                    _oraclePeekPayload,
                    _minPeekLimit
                )
            ) ||
                _isOk(
                    isVaultUnsafeOSM(
                        _vaultID,
                        _priceOracle,
                        _oraclePeepPayload,
                        _minPeepLimit
                    )
                )
                ? OK
                : "MakerVaultNotUnsafe";
    }

    /// @notice Specific implementation of this Condition's ok function
    /// @dev The price oracle must return (bytes32, bool).
    /// @param _vaultID The id of the Maker vault
    /// @param _priceOracle The price oracle contract to supply the collateral price
    ///  e.g. Maker's ETH/USD oracle for ETH collateral pricing.
    /// @param _oraclePayload The data for making the staticcall to the oracle's read
    ///  method e.g. the selector for MakerOracle's read fn.
    /// @param _minLimit The minimum collateral ratio measured in the price
    /// of the collateral as specified by the _priceOracle.
    /// @return OK if the Maker Vault is unsafe, otherwise some error message.
    function isVaultUnsafeOSM(
        uint256 _vaultID,
        address _priceOracle,
        bytes memory _oraclePayload,
        uint256 _minLimit
    ) public view virtual returns (string memory) {
        return
            IConditionMakerVaultUnsafeOSM(CONDITION_MAKER_VAULT_UNSAFE_OSM)
                .isVaultUnsafeOSM(
                _vaultID,
                _priceOracle,
                _oraclePayload,
                _minLimit
            );
    }

    /// @notice Convenience function for off-chain _conditionData encoding
    /// @dev Use the return for your Task's Condition.data field off-chain.
    /// @return The encoded payload for your Task's Condition.data field.
    function getConditionData(
        uint256 _vaultId,
        address _priceOracle,
        bytes calldata _oraclePeekPayload,
        bytes calldata _oraclePeepPayload,
        uint256 _minPeekLimit,
        uint256 _minPeepLimit
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isVaultUnsafeOSM.selector,
                _vaultId,
                _priceOracle,
                _oraclePeekPayload,
                _oraclePeepPayload,
                _minPeekLimit,
                _minPeepLimit
            );
    }

    function _isOk(string memory _isSafe) internal view returns (bool) {
        return
            keccak256(abi.encodePacked(_isSafe)) ==
            keccak256(abi.encodePacked(OK));
    }
}
