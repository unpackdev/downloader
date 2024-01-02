// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./LibFeeStoreStorage.sol";
import "./GenericErrors.sol";
import "./Structs.sol";

/// @title Fee Store Library
/// @author Daniel <danieldegendev@gmail.com>
/// @notice Functions to help with the fee store for other instances
library LibFeeStore {
    using SafeERC20 for IERC20;
    uint256 constant DENOMINATOR_RELATIVE = 10 ** 5; // bps denominator
    uint256 constant DENOMINATOR_ABSOLUTE = 10 ** 4;

    error ZeroFees();
    error FeeNotExisting(bytes32 id);
    error FeeExists(bytes32 id);

    event FeeConfigAdded(bytes32 indexed id);
    event FeeConfigUpdated(bytes32 indexed id);
    event FeeConfigDeleted(bytes32 indexed id);
    event FeeConfigMarkedAsDeleted(bytes32 indexed id);
    event FeesPrepared(uint256 amount, FeeConfigSyncHomeDTO candidate);

    /// Store a specific amount of fees in the store
    /// @param _feeConfigId fee config id
    /// @param _amount amount of tokens
    function putFees(bytes32 _feeConfigId, uint256 _amount) internal {
        if (_amount == 0) revert ZeroValueNotAllowed();
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        FeeStoreConfig memory _config = s.feeConfigs[_feeConfigId];
        if (_config.id == bytes32("")) revert NotAllowed();
        s.collectedFees[_config.id] += _amount;
        s.collectedFeesTotal += _amount;
    }

    /// Prepares the fees collected on the store to be send to the home chain
    /// @return _dto the dto that will be used on the home chain for receiving and process fees
    /// @dev this method will also clean up every fee collected and sets it to 0
    function prepareToSendFees() internal returns (FeeConfigSyncHomeDTO memory _dto) {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        if (s.collectedFeesTotal == 0) revert ZeroFees();

        uint256 _feeIndex = 0;
        uint256 _noOfExpectedFees = 0;

        // get how many fees need to get sent
        for (uint256 i = 0; i < s.feeConfigIds.length; ) {
            if (s.collectedFees[s.feeConfigIds[i]] > 0) _noOfExpectedFees++;
            unchecked {
                i++;
            }
        }

        // collect amounts and gathers configs
        _dto.fees = new FeeConfigSyncHomeFees[](_noOfExpectedFees);
        for (uint256 i = 0; i < s.feeConfigIds.length; ) {
            bytes32 _id = s.feeConfigIds[i];
            if (s.collectedFees[_id] > 0) {
                uint256 _amount = s.collectedFees[_id];
                s.collectedFees[_id] = 0;
                if (s.feeConfigs[_id].deleted) deleteFee(_id);
                _dto.totalFees += _amount;
                _dto.fees[_feeIndex] = FeeConfigSyncHomeFees({ id: _id, amount: _amount });
                unchecked {
                    _feeIndex++;
                }
            }
            unchecked {
                i++;
            }
        }
        s.collectedFeesTotal = 0;
        emit FeesPrepared(_dto.totalFees, _dto);
    }

    /// Removes a fee from the store
    /// @param _id fee id
    /// @dev if a fee is still in use, it will be marked as deleted. Once fees get moved to home chain, it will be deleted properly
    function deleteFee(bytes32 _id) internal {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        if (s.feeConfigs[_id].id == bytes32(0)) revert FeeNotExisting(_id);
        if (s.collectedFees[_id] > 0) {
            s.feeConfigs[_id].deleted = true;
            emit FeeConfigMarkedAsDeleted(_id);
        } else {
            delete s.collectedFees[_id];
            delete s.feeConfigs[_id];
            for (uint256 i = 0; i < s.feeConfigIds.length; ) {
                if (s.feeConfigIds[i] == _id) {
                    s.feeConfigIds[i] = s.feeConfigIds[s.feeConfigIds.length - 1];
                    break;
                }
                unchecked {
                    i++;
                }
            }
            s.feeConfigIds.pop();
            emit FeeConfigDeleted(_id);
        }
    }

    /// Adds a fee to the store
    /// @param _id fee id
    /// @param _fee fee value
    /// @param _target the target address
    function addFee(bytes32 _id, uint256 _fee, address _target) internal {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        if (s.feeConfigs[_id].id != bytes32(0)) revert FeeExists(_id);
        s.feeConfigs[_id] = FeeStoreConfig({ id: _id, fee: _fee, target: _target, deleted: false });
        s.feeConfigIds.push(_id);
        emit FeeConfigAdded(_id);
    }

    /// Updates a fee on the store
    /// @param _id fee id
    /// @param _fee fee value
    /// @param _target the target address
    function updateFee(bytes32 _id, uint256 _fee, address _target) internal {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        if (s.feeConfigs[_id].id == bytes32(0)) revert FeeNotExisting(_id);
        s.feeConfigs[_id] = FeeStoreConfig({ id: _id, fee: _fee, target: _target, deleted: false });
        emit FeeConfigUpdated(_id);
    }

    /// viewables

    /// Calculates the relative fee based on the inserted amount
    /// @param _feeConfigId fee config id
    /// @param _asset address of the token
    /// @param _amount amount that fees are based on
    /// @return _amountNet amount excluding fee
    /// @return _fee amount of fee
    /// @return _feePoints fee value that is applied
    function calcFeesRelative(
        bytes32 _feeConfigId,
        address _asset,
        uint256 _amount
    ) internal view returns (uint256 _amountNet, uint256 _fee, uint256 _feePoints) {
        return calcFees(_feeConfigId, _asset, _amount, false);
    }

    /// Calculates the absolute fee based on the inserted amount
    /// @param _feeConfigId fee config id
    /// @param _asset address of the token
    /// @param _amount amount that fees are based on
    /// @return _amountNet amount excluding fee
    /// @return _fee amount of fee
    /// @return _feePoints fee value that is applied
    function calcFeesAbsolute(
        bytes32 _feeConfigId,
        address _asset,
        uint256 _amount
    ) internal view returns (uint256 _amountNet, uint256 _fee, uint256 _feePoints) {
        return calcFees(_feeConfigId, _asset, _amount, true);
    }

    /// Calculates the relative or absolute fees based on the inserted amount
    /// @param _feeConfigId fee config id
    /// @param _asset address of the token
    /// @param _amount amount that fees are based on
    /// @param _absolute whether a calculation is relative or absolute
    /// @return _amountNet amount excluding fee
    /// @return _fee amount of fee
    /// @return _feePoints fee value that is applied
    function calcFees(
        bytes32 _feeConfigId,
        address _asset,
        uint256 _amount,
        bool _absolute
    ) internal view returns (uint256 _amountNet, uint256 _fee, uint256 _feePoints) {
        if (_amount == 0) revert ZeroValueNotAllowed();
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        FeeStoreConfig memory _config = s.feeConfigs[_feeConfigId];
        if (_config.id == bytes32("")) return (_amount, 0, 0);
        _feePoints = _config.fee;
        _fee = _absolute
            ? ((_feePoints * (10 ** IERC20Metadata(_asset).decimals())) / DENOMINATOR_ABSOLUTE)
            : ((_amount * _feePoints) / DENOMINATOR_RELATIVE);
        _amountNet = _amount - _fee;
    }

    function getOperator() internal view returns (address _operator) {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        _operator = s.operator;
    }

    function setOperator(address _operator) internal {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        s.operator = _operator;
    }

    function getIntermediateAsset() internal view returns (address _intermediateAsset) {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        _intermediateAsset = s.intermediateAsset;
    }

    function setIntermediateAsset(address _intermediateAsset) internal {
        LibFeeStoreStorage.FeeStoreStorage storage s = LibFeeStoreStorage.feeStoreStorage();
        s.intermediateAsset = _intermediateAsset;
    }
}
