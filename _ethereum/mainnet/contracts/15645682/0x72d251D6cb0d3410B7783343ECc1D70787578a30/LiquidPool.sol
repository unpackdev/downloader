// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";

import "./BudgetApprovalExecutee.sol";

import "./Denominations.sol";

import "./PriceResolver.sol";
import "./Concat.sol";
import "./IDao.sol";

contract LiquidPool is Initializable, UUPSUpgradeable, ERC20Upgradeable, PriceResolver, BudgetApprovalExecutee {
    using Concat for string;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    
    IDao public dao;
    address[] public assets;
    mapping(address => uint256) private _assetIndex;

    event AllowDepositToken(address token);
    event DisallowDepositToken(address token);
    event Deposit(address account, address token, uint256 depositAmount);

    modifier onlyGovern(string memory category) {
        IDao _dao = dao;
        require(
            (_dao.byPassGovern(msg.sender)) || msg.sender == _dao.govern(category),
            string("Dao: only Govern").concat(category));
        _;
    }

    modifier onlyDao() {
        require(msg.sender == address(dao), "not dao");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        address owner,
        address[] memory depositTokens,
        address _baseCurrency
    )
        public initializer
    {
        __ERC20_init("LiquidPool", "LP");
        __PriceResolver_init(_baseCurrency);
        dao = IDao(payable(owner));
        _addAssets(depositTokens);
        ___BudgetApprovalExecutee_init(IDao(payable(owner)).team());
    }

    function assetsShares(address asset, uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        require(amount <= _totalSupply, "gt totalSupply");
        require(isAssetSupported(asset), "Asset not support");
        if (_totalSupply == 0) return 0;

        return _assetBalance(asset) * amount / _totalSupply;
    }

    function quote(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) return amount;
        return amount * _totalSupply / totalPrice();
    }

    function canAddAsset(address asset) public view returns (bool) {
        return canResolvePrice(asset);
    }

    function totalPrice() public view returns (uint256) {
        uint256 total;
        uint256 _assetsLength = assets.length;

        for (uint256 i = 0; i < _assetsLength; i++) {
            address _asset = assets[i];
            total += assetBaseCurrencyPrice(_asset,  _assetBalance(_asset));
        }
        return total;
    }

    function totalPriceInEth() public view returns (uint256) {
        uint256 total;
        uint256 _assetsLength = assets.length;

        for (uint256 i = 0; i < _assetsLength; i++) {
            address _asset = assets[i];
            total += assetEthPrice(_asset,  _assetBalance(_asset));
        }
        return total;
    }

    function isAssetSupported(address asset) public view returns (bool) {
        return _assetIndex[asset] > 0;
    }

    function deposit(address receiver) public payable {
        require(isAssetSupported(Denominations.ETH), "asset not support");

        uint256 _totalSupply = totalSupply();
        uint256 ethPriceInBaseCurrency = assetBaseCurrencyPrice(Denominations.ETH, msg.value);

        if (_totalSupply == 0) {
            _mint(receiver, ethPriceInBaseCurrency);
            _afterDeposit(receiver, ethPriceInBaseCurrency);
            emit Deposit(receiver, Denominations.ETH, msg.value);
            return;
        }
        uint256 total = totalPrice() - ethPriceInBaseCurrency;
        _mint(receiver, ethPriceInBaseCurrency * _totalSupply / total);

        _afterDeposit(receiver, ethPriceInBaseCurrency);

        emit Deposit(receiver, Denominations.ETH, msg.value);
    }

    function redeem(uint256 amount) public {
        IDao _dao = dao;
        require(balanceOf(msg.sender) >= amount, "not enough balance");
        require(_dao.firstDepositTime(msg.sender) + _dao.locktime() <= block.timestamp, "lockup time");

        uint256 _assetsLength = assets.length;
        for (uint256 i = 0; i < _assetsLength; i++) {
            address _asset = assets[i];
            _transferAsset(msg.sender, _asset, assetsShares(_asset, amount));
        }
        _burn(msg.sender, amount);
    }

    function depositToken(address receiver, address asset, uint256 amount) public {
        require(isAssetSupported(asset), "Asset not support");
        require(IERC20MetadataUpgradeable(asset).allowance(msg.sender, address(this)) >= amount, "not approve");

        uint256 assetPriceInBaseCurrency = assetBaseCurrencyPrice(asset, amount);
        _mint(receiver, quote(assetPriceInBaseCurrency));
        IERC20MetadataUpgradeable(asset).safeTransferFrom(msg.sender, address(this), amount);
        _afterDeposit(receiver, assetPriceInBaseCurrency);

        emit Deposit(receiver, asset, amount);
    }

    function addAssets(address[] calldata erc20s) public onlyGovern("General") {
        _addAssets(erc20s);
    }

    function removeAssets(address[] calldata erc20s) public onlyGovern("General") {
        _removeAssets(erc20s);
    }

    function _beforeCreateBudgetApproval(address budgetApproval) internal view override onlyGovern("General") {
        require(dao.canCreateBudgetApproval(budgetApproval), "not whitelist");
    }

    function _assetBalance(address asset) internal view returns (uint256) {
        if(asset == Denominations.ETH) {
            return address(this).balance;
        }
        
        return IERC20MetadataUpgradeable(asset).balanceOf(address(this));
    }

    function _transferAsset(address target, address asset, uint256 amount) internal {
        if(asset == Denominations.ETH) {
            (bool success, ) = payable(target).call{ value: amount }("");
            require(success, "Failed to send Ether");
        } else {
            IERC20MetadataUpgradeable(asset).safeTransfer(target, amount);
        }
    }
    
    function _afterDeposit(address account, uint256 amount) private {
      dao.afterDeposit(account, amount);
    }

    function _addAssets(address[] memory erc20s) internal {
        for (uint256 i = 0; i < erc20s.length; i++) {
            _addAsset(erc20s[i]);
        }
    }

    function _removeAssets(address[] memory erc20s) internal {
        for (uint256 i = 0; i < erc20s.length; i++) {
            _removeAsset(erc20s[i]);
        }
    }

    function _addAsset(address erc20) internal {
        require(canAddAsset(erc20) && !isAssetSupported(erc20), "Asset not support");
        assets.push(erc20);
        _assetIndex[erc20] = assets.length;

        emit AllowDepositToken(erc20);
    }

    function _removeAsset(address erc20) internal {
        require(isAssetSupported(erc20), "Asset not in list");
        uint256 index = _assetIndex[erc20] - 1;
        address lastEl = assets[assets.length - 1];
        assets[index] = lastEl;

        _assetIndex[lastEl] = index + 1;
        _assetIndex[erc20] = 0;
        assets.pop();
        emit DisallowDepositToken(erc20);
    }

    function assetsLength() public view returns(uint256) {
        return assets.length;
    }

    function _authorizeUpgrade(address) internal view override onlyDao {}
    receive() external payable {}

    uint256[50] private __gap;
}