// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./GelatoBytes.sol";
import "./FMakerVaultUnsafe.sol";

/// @title ConditionMakerVaultUnsafe
/// @notice Condition tracking Maker vault collateralization safety requirements.
/// @author Gelato Team
contract ConditionMakerVaultUnsafe is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    /// @notice Convenience function for off-chain _conditionData encoding
    /// @dev Use the return for your Task's Condition.data field off-chain.
    /// @return The encoded payload for your Task's Condition.data field.
    function getConditionData(
        uint256 _vaultId,
        address _priceOracle,
        bytes calldata _oraclePayload,
        uint256 _minColRatio
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isVaultUnsafe.selector,
                _vaultId,
                _priceOracle,
                _oraclePayload,
                _minColRatio
            );
    }

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
            bytes memory _oraclePayload,
            uint256 _minColRatio
        ) = abi.decode(_conditionData[4:], (uint256, address, bytes, uint256));

        return
            isVaultUnsafe(_vaultID, _priceOracle, _oraclePayload, _minColRatio);
    }

    /// @notice Specific implementation of this Condition's ok function
    /// @dev The price oracle must return a uint256 WAD (10**18) value.
    /// @param _vaultID The id of the Maker vault
    /// @param _priceOracle The price oracle contract to supply the collateral price
    ///  e.g. Maker's ETH/USD oracle for ETH collateral pricing.
    /// @param _oraclePayload The data for making the staticcall to the oracle's read
    ///  method e.g. the selector for MakerOracle's read fn.
    /// @param _minColRatio The minimum collateral ratio measured in the price
    /// of the collateral as specified by the _priceOracle.
    /// @return OK if the Maker Vault is unsafe, otherwise some error message.
    function isVaultUnsafe(
        uint256 _vaultID,
        address _priceOracle,
        bytes memory _oraclePayload,
        uint256 _minColRatio
    ) public view virtual returns (string memory) {
        return
            _isVaultUnsafe(_vaultID, _priceOracle, _oraclePayload, _minColRatio)
                ? OK
                : "MakerVaultNotUnsafe";
    }
}
