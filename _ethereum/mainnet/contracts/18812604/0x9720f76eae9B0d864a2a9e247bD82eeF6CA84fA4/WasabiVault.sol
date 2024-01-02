// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC4626Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";

import "./IWasabiPerps.sol";
import "./IWasabiVault.sol";
import "./IAddressProvider.sol";
import "./IWETH.sol";

contract WasabiVault is IWasabiVault, UUPSUpgradeable, OwnableUpgradeable, ERC4626Upgradeable, ReentrancyGuardUpgradeable {
    IWasabiPerps public pool;
    uint256 public totalAssetValue;
    IAddressProvider public addressProvider;

    /// @dev Initializer for proxy
    /// @param _pool The WasabiPerps pool
    /// @param _addressProvider The address provider
    /// @param _asset The asset
    /// @param name The name of the vault
    /// @param symbol The symbol of the vault
    function initialize(
        IWasabiPerps _pool,
        IAddressProvider _addressProvider,
        IERC20 _asset,
        string memory name,
        string memory symbol
    ) public initializer {
        __Ownable_init(msg.sender);
        __ERC4626_init(_asset);
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        pool = _pool;
        addressProvider = _addressProvider;
        totalAssetValue = 0;
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @inheritdoc ERC4626Upgradeable
    function totalAssets() public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return totalAssetValue;
    }

    /** @dev See {IERC4626-deposit}. */
    function depositEth(address receiver) public payable returns (uint256) {
        if (asset() != addressProvider.getWethAddress()) revert CannotDepositEth();

        uint256 assets = msg.value;
        if (assets == 0) revert InvalidEthAmount();

        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);

        IWETH weth = IWETH(addressProvider.getWethAddress());
        weth.deposit{value: assets}();
        SafeERC20.safeTransfer(weth, address(pool), assets);

        _mint(receiver, shares);
        totalAssetValue += assets;
        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc IWasabiVault
    function getPoolAddress() external view override returns (address) {
        return address(pool);
    }

    /// @inheritdoc IWasabiVault
    function recordInterestEarned(uint256 _interestAmount) external override {
        if (address(pool) != msg.sender) revert CallerNotPool();

        if (_interestAmount > 0) {
            totalAssetValue += _interestAmount;
        }
    }

    /// @inheritdoc IWasabiVault
    function recordLoss(uint256 _amountLost) external override {
        if (address(pool) != msg.sender) revert CallerNotPool();

        totalAssetValue -= _amountLost;
    }

    /// @inheritdoc ERC4626Upgradeable
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(pool), assets);

        _mint(receiver, shares);
        totalAssetValue += assets;
        emit Deposit(caller, receiver, assets, shares);
    }

    /// @inheritdoc ERC4626Upgradeable
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        pool.withdraw(asset(), assets, receiver);

        totalAssetValue -= assets;

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
