// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./IInitializer.sol";
import "./BitMaps.sol";
import "./IValidatorsRegisterStorage.sol";

/// Threshold value cannot be grater than divider.
/// @param maxValue maximum threshold value.
error TooBigThreshold(uint32 maxValue);
/// Threshold value cannot be less then 50%
/// @param minValue minimum threshold value.
error TooSmallThreshold(uint32 minValue);
/// Activation timestamp must be in future.
error ActivationInPast();

contract VaultStorage is Context, Ownable, Initializable, IInitializer, IValidatorsRegisterStorage {
    uint32 public constant THRESHOLD_DIVIDER = 1000;
    uint32 private _threshold;

    // LockerStorage
    BitMaps.BitMap private _released;

    // ValidatorsRegisterStorage
    mapping(address => uint256) private _validators;
    BitMaps.BitMap private _validatorIds;
    ValidatorsInfo private _validatorsInfo;

    // Vault
    struct LootBoxInfo {
        address lootBox;
        uint32 chainId;
        uint64 reserved;
    }
    LootBoxInfo private _lootBoxInfo;


    constructor() {
        _disableInitializers();
    }

    function initialize(uint32 threshold_, address lootBox, uint32 chainId) initializer override external {
        _setThreshold(threshold_);
        _setLootBoxInfo(lootBox, chainId);
        _transferOwnership(_msgSender());
    }

    function threshold() public view returns (uint32) {
        return _threshold;
    }

    function _setThreshold(uint32 threshold_) internal {
        if (threshold_ > THRESHOLD_DIVIDER) {
            revert TooBigThreshold(THRESHOLD_DIVIDER);
        }
        if (threshold_ < THRESHOLD_DIVIDER / 2) {
            revert TooSmallThreshold(THRESHOLD_DIVIDER / 2);
        }
        _threshold = threshold_;
    }

    function _setLootBoxInfo(address lootBox, uint32 chainId) internal {
        _lootBoxInfo.lootBox = lootBox;
        _lootBoxInfo.chainId = chainId;
    }

    function _getLootBoxInfo() internal view returns (LootBoxInfo storage) {
        return _lootBoxInfo;
    }

    function _readReleased() internal view returns (BitMaps.BitMap storage) {
        return _released;
    }

    function _readValidator(address account) internal view override returns (uint256) {
        return _validators[account];
    }

    function _writeValidator(address account, uint256 id) internal override {
        _validators[account] = id;
    }

    function _deleteValidator(address account) internal override {
        delete _validators[account];
    }

    function _readValidatorIds() internal view override returns (BitMaps.BitMap storage) {
        return _validatorIds;
    }

    function _readValidatorsInfo() internal view override returns (ValidatorsInfo storage) {
        return _validatorsInfo;
    }

    function _writeValidatorsInfo(ValidatorsInfo memory info) internal override {
        _validatorsInfo = info;
    }
}
