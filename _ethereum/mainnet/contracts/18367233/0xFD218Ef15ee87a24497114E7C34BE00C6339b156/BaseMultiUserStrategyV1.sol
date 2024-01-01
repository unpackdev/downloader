// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IBaseMultiUserStrategyV1.sol";
import "./ICoreAccessControlV1.sol";
import "./DefinitiveErrors.sol";
import "./UUPSUpgradeable.sol";
import "./CoreMulticall.sol";
import "./BaseMultiUserFeesUpgradeable.sol";
import "./CoreTransfersNativeUpgradeable.sol";
import "./BaseNativeWrapperUpgradeable.sol";
import "./IBaseSafeHarborMode.sol";
import "./StorageSlotUpgradeable.sol";

interface IDefinitiveVault is ICoreAccessControlV1, IBaseSafeHarborMode {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
}

abstract contract BaseMultiUserStrategyV1 is
    IBaseMultiUserStrategyV1,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    CoreMulticall,
    BaseMultiUserFeesUpgradeable,
    CoreTransfersNativeUpgradeable,
    BaseNativeWrapperUpgradeable
{
    address payable public VAULT;

    /* solhint-disable max-line-length */
    /**
     * @dev Storage slot with flag allowing redemptions during safe harbor.
     * This is the keccak-256 hash of "Definitive.BaseMultiUserStrategyV1._ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT" subtracted by 1
     * bytes32(uint256(keccak256("Definitive.BaseMultiUserStrategyV1._ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT")) - 1)
     */
    /* solhint-enable max-line-length */
    bytes32 internal constant _ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT =
        0xd8e383845db7ecbb6065c22cc5d1320931e4ef39a73fc10e0587d5257ff50379;

    modifier onlyDefinitiveVaultAdmins() {
        _validateOnlyDefinitiveVaultAdmins();

        _;
    }

    /// @notice Revert if safe harbor mode is enabled
    modifier revertIfSafeHarborModeEnabled() {
        if (getSafeHarborModeEnabled()) {
            revert SafeHarborModeEnabled();
        }
        _;
    }

    function __BaseMultiUserStrategy_init(
        address _vault,
        string memory _name,
        string memory _symbol,
        address _feesAccount
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC20_init(_name, _symbol);
        __BaseMultiUserFees_init(_feesAccount);
        __BaseMultiUserStrategy_init_unchained(_vault);
    }

    function __BaseMultiUserStrategy_init_unchained(address _vault) internal onlyInitializing {
        VAULT = payable(_vault);
        StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value = false;
    }

    function getVersion() external view returns (uint256) {
        return _getInitializedVersion();
    }

    function setFeesAccount(address _value) external onlyDefinitiveVaultAdmins {
        _setFeesAccount(_value);
    }

    function setRedemptionFee(uint256 _value) external onlyDefinitiveVaultAdmins {
        _setRedemptionFee(_value);
    }

    function setSafeHarborRedemptions(bool allow) external onlyDefinitiveVaultAdmins {
        StorageSlotUpgradeable.getBooleanSlot(_ENABLE_SAFE_HARBOR_REDEMPTIONS_SLOT).value = allow;
    }

    function getSafeHarborModeEnabled() public view returns (bool) {
        return IDefinitiveVault(VAULT).SAFE_HARBOR_MODE_ENABLED();
    }

    /// @dev Required by UUPSUpgradeable, used by `upgradeTo()` and `upgradeToAndCall()`
    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Revert if caller is not definitive admin on underlying vault
    function _validateOnlyDefinitiveVaultAdmins() private {
        IDefinitiveVault mVault = IDefinitiveVault(VAULT);

        if (
            !mVault.hasRole(mVault.ROLE_DEFINITIVE_ADMIN(), _msgSender()) &&
            !mVault.hasRole(mVault.DEFAULT_ADMIN_ROLE(), _msgSender())
        ) {
            revert AccountNotAdmin(_msgSender());
        }
    }

    function _transferShares(address from, address to, uint256 amount) internal override {
        return _transfer(from, to, amount);
    }
}
