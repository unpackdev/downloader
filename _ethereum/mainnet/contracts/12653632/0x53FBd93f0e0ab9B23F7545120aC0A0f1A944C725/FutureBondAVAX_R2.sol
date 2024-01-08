// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.6;

import "./SafeMathUpgradeable.sol";
import "./SignedSafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

interface IFutureBondAVAX {

    function mintBonds(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function pendingBurn(address account) external view returns (uint256);

    function lockForDelayedBurn(address account, uint256 amount) external;

    function commitDelayedBurn(address account, uint256 amount) external;

    function ratio() external view returns (uint256);

    function lastConfirmedRatio() external view returns (uint256);
}

contract FutureBondAVAX_R2 is OwnableUpgradeable, ERC20Upgradeable, IFutureBondAVAX {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    event RatioUpdate(uint256 newRatio);
    event LastConfirmedRatioUpdate(uint256 newRatio);

    address private _operator;
    address private _crossChainBridge;
    address private _avalanchePool;
    // ratio should be base on 1 AVAX, if ratio is 0.9, this variable should be 9e17
    uint256 private _ratio;
    uint256 private _lastConfirmedRatio;
    int256 private _lockedShares;

    mapping(address => uint256) private _pendingBurn;
    uint256 _pendingBurnsTotal;

    function initialize(address operator) public initializer {
        __Ownable_init();
        __ERC20_init("Ankr Avalanche Reward Earning Bond", "aAVAXb");
        _operator = operator;
        _ratio = 1e18;
        _lastConfirmedRatio = 1e18;
    }

    function ratio() public override view returns (uint256) {
        return _ratio;
    }

    function updateRatio(uint256 newRatio) public onlyOperator {
        // 0.002 * ratio
        uint256 threshold = _ratio.div(500);
        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function lastConfirmedRatio() public view override returns (uint256) {
        return _lastConfirmedRatio;
    }

    function updateLastConfirmedRatio(uint256 newRatio) public onlyOperator {
        // 0.002 * ratio
        uint256 threshold = _lastConfirmedRatio.div(500);
        require(newRatio < _lastConfirmedRatio.add(threshold) || newRatio > _lastConfirmedRatio.sub(threshold), "New ratio should be in limits");
        _lastConfirmedRatio = newRatio;
        emit LastConfirmedRatioUpdate(_lastConfirmedRatio);
    }

    function updateBothRatios(uint256 newRatio, uint256 newConfirmedRatio) public onlyOperator {
        updateRatio(newRatio);
        updateLastConfirmedRatio(newConfirmedRatio);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return _sharesTofAvax(supply);
    }

    function totalSharesSupply() public view returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        return _sharesTofAvax(balance).sub(_pendingBurn[account]);
    }

    function mintBonds(address account, uint256 amount) public override onlyBondMinter {
        uint256 shares = _fAvaxToShares(amount);
        _mint(account, shares);
    }

    function mint(address account, uint256 shares) public onlyMinter {
        _lockedShares = _lockedShares.sub(int256(shares));
        _mint(account, shares);
    }

    function burn(address account, uint256 amount) public override onlyMinter {
        uint256 shares = _fAvaxToShares(amount);
        _lockedShares = _lockedShares.add(int256(shares));
        _burn(account, shares);
    }

    function pendingBurn(address account) external view override returns (uint256) {
        return _pendingBurn[account];
    }

    function lockForDelayedBurn(address account, uint256 amount) public override onlyBondMinter {
        _pendingBurn[account] = _pendingBurn[account].add(amount);
        _pendingBurnsTotal = _pendingBurnsTotal.add(amount);
    }

    function commitDelayedBurn(address account, uint256 amount) public override onlyBondMinter {
        uint256 burnableAmount = _pendingBurn[account];
        require(burnableAmount >= amount, "Too big amount to burn");
        uint256 sharesToBurn = _fAvaxToSharesConfirmedRatio(amount);
        _pendingBurn[account] = burnableAmount.sub(amount);
        _pendingBurnsTotal = _pendingBurnsTotal.sub(amount);
        _burn(account, sharesToBurn);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _fAvaxToShares(amount);
        super.transfer(recipient, shares);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _sharesTofAvax(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _fAvaxToShares(amount);
        super.approve(spender, shares);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _fAvaxToShares(amount);
        super.transferFrom(sender, recipient, shares);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        uint256 shares = _fAvaxToShares(addedValue);
        super.increaseAllowance(spender, shares);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 shares = _fAvaxToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        return true;
    }

    function _fAvaxToShares(uint256 amount) internal view returns (uint256) {
        return amount.mul(_ratio).div(1e18);
    }

    function _sharesTofAvax(uint256 amount) internal view returns (uint256) {
        return amount.mul(1e18).div(_ratio);
    }

    function _fAvaxToSharesConfirmedRatio(uint256 amount) internal view returns (uint256) {
        return amount.mul(_lastConfirmedRatio).div(1e18);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == owner() || msg.sender == _crossChainBridge, "Minter: not allowed");
        _;
    }

    modifier onlyBondMinter() {
        require(msg.sender == owner() || msg.sender == _avalanchePool, "Minter: not allowed");
        _;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function changeAvalanchePool(address avalanchePool) public onlyOwner {
        _avalanchePool = avalanchePool;
    }

    function changeCrossChainBridge(address crossChainBridge) public onlyOwner {
        _crossChainBridge = crossChainBridge;
    }

    function lockedSupply() public view returns (int256) {
        return _lockedShares;
    }
}

contract PeggedAVAX is OwnableUpgradeable, ERC20Upgradeable {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    address private _operator;

    function initialize(address operator) public initializer {
        __Ownable_init();
        __ERC20_init("fAVAX Reward Bearing Bond", "aETH");
        _operator = operator;
    }

    function mint(address owner, uint256 amount) public onlyOperator {
        _mint(owner, amount);
    }

    function burn(address owner, uint256 amount) public onlyOperator {
        _burn(owner, amount);
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }
}
