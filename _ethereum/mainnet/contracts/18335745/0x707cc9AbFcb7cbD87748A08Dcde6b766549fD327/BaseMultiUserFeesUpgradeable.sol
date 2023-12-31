// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Initializable.sol";
import "./StorageSlotUpgradeable.sol";
import "./IBaseMultiUserFeesUpgradeableV1.sol";
import "./DefinitiveErrors.sol";
import "./ContextUpgradeable.sol";
import "./DefinitiveAssets.sol";

abstract contract BaseMultiUserFeesUpgradeable is IBaseMultiUserFeesUpgradeableV1, Initializable, ContextUpgradeable {
    using DefinitiveAssets for IERC20;

    uint256 private constant _MAX_FEE_PERCENTAGE = 10_000;

    /* solhint-disable max-line-length */
    /**
     * @dev Storage slot with the current fee charged upon redemption.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserFeesUpgradeableV1._REDEMPTION_FEE_PERCENTAGE_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserFeesUpgradeableV1._REDEMPTION_FEE_PERCENTAGE_SLOT")) - 1)
     */
    /* solhint-enable max-line-length */
    bytes32 internal constant _REDEMPTION_FEE_PERCENTAGE_SLOT =
        0x14aa58a89d3f94ea99187ab98e735eb8f742cc801507b0f8968576d3fdc3c8cc;

    /**
     * @dev Storage slot with the current fee charged upon redemption.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserFeesUpgradeableV1._FEES_ACCOUNT_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserFeesUpgradeableV1._FEES_ACCOUNT_SLOT")) - 1)
     */
    bytes32 internal constant _FEES_ACCOUNT_SLOT = 0x68433f9d83ac21ac7a279e7d087229a9129597a360563c499bb398b5664b27c1;

    function __BaseMultiUserFees_init(address _feesAccount) internal initializer {
        __BaseMultiUserFees_init_unchained(_feesAccount);
    }

    function __BaseMultiUserFees_init_unchained(address _feesAccount) internal initializer {
        _setFeesAccount(_feesAccount);
    }

    function getFeesAccount() public view returns (address) {
        return address(StorageSlotUpgradeable.getAddressSlot(_FEES_ACCOUNT_SLOT).value);
    }

    function getRedemptionFee() public view returns (uint256) {
        return uint256(StorageSlotUpgradeable.getUint256Slot(_REDEMPTION_FEE_PERCENTAGE_SLOT).value);
    }

    function getRedemptionFeeAmount(uint256 amount) public view returns (uint256 feeAmount) {
        feeAmount = _getFeeAmount(amount, getRedemptionFee());
    }

    function _getFeeAmount(uint256 amount, uint256 fee) private pure returns (uint256) {
        return (amount * fee) / _MAX_FEE_PERCENTAGE;
    }

    function _handleRedemptionFeesOnShares(
        address owner,
        address asset,
        uint256 amount,
        uint256 additionalFeePct
    ) internal returns (uint256 feeAmount) {
        uint256 baseFee = getRedemptionFee();
        if ((baseFee + additionalFeePct) > _MAX_FEE_PERCENTAGE) {
            revert InvalidInputs();
        }

        address feesAccount = getFeesAccount();
        uint256 baseFeeAmount = _getFeeAmount(amount, baseFee);
        uint256 additionalFeeAmount = _getFeeAmount(amount, additionalFeePct);
        feeAmount = baseFeeAmount + additionalFeeAmount;

        if (feeAmount > 0 && feesAccount != address(0)) {
            _transferShares(owner, feesAccount, feeAmount);
            emit RedemptionFee(_msgSender(), asset, amount, baseFeeAmount, additionalFeeAmount);
        }
    }

    function _setFeesAccount(address value) internal {
        if (value == address(0)) {
            revert InvalidInputs();
        }

        StorageSlotUpgradeable.getAddressSlot(_FEES_ACCOUNT_SLOT).value = value;
        emit FeeAccountUpdated(_msgSender(), value);
    }

    function _setRedemptionFee(uint256 value) internal {
        if (value >= _MAX_FEE_PERCENTAGE) {
            revert InvalidInputs();
        }
        StorageSlotUpgradeable.getUint256Slot(_REDEMPTION_FEE_PERCENTAGE_SLOT).value = value;
        emit RedemptionFeeUpdated(_msgSender(), value);
    }

    function _transferShares(address from, address to, uint256 amount) internal virtual;
}
