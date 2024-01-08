// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";
import "./SignedSafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./IinternetBond.sol";

contract aMATICb_R1 is OwnableUpgradeable, ERC20Upgradeable, IinternetBond {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    event RatioUpdate(uint256 newRatio);
    event LastConfirmedRatioUpdate(uint256 newRatio);

    address private _operator;
    address private _crossChainBridge;
    address private _polygonPool;
    // ratio should be base on 1 MATIC, if ratio is 0.9, this variable should be 9e17
    uint256 private _ratio;
    int256 private _lockedShares;

    mapping(address => uint256) private _pendingBurn;
    uint256 private _pendingBurnsTotal;

    uint256 private _collectableFee;

    string private _name;
    string private _symbol;

    function initialize(address operator) public initializer {
        __Ownable_init();
        __ERC20_init("Ankr MATIC Reward Earning Bond", "aMATICb");
        _operator = operator;
        _ratio = 1e18;
    }

    function ratio() public override view returns (uint256) {
        return _ratio;
    }

    function updateRatio(uint256 newRatio) public onlyOperator {
//        // 0.002 * ratio
//        uint256 threshold = _ratio.div(500);
//        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        require(newRatio <= 1e18, "new ratio should be less or equal to 1e18");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function repairRatio(uint256 newRatio) public onlyOwner {
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function collectableFee() public view returns (uint256) {
        return _collectableFee;
    }

    function repairCollectableFee(uint256 newFee) public onlyOwner {
        _collectableFee = newFee;
    }

    function updateRatioAndFee(uint256 newRatio, uint256 newFee) public onlyOperator {
        // 0.002 * ratio
        uint256 threshold = _ratio.div(500);
        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        require(newRatio <= 1e18, "new ratio should be less or equal to 1e18");
        _ratio = newRatio;
        _collectableFee = newFee;
        emit RatioUpdate(_ratio);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return _sharesToBonds(supply);
    }

    function totalSharesSupply() public view returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = super.balanceOf(account);
        return _sharesToBonds(shares).sub(_pendingBurn[account]);
    }

    function mintBonds(address account, uint256 amount) public override onlyBondMinter {
        uint256 shares = _bondsToShares(amount);
        _mint(account, shares);
    }

    function mint(address account, uint256 shares) public onlyMinter {
        _lockedShares = _lockedShares.sub(int256(shares));
        _mint(account, shares);
    }

    function burn(address account, uint256 amount) public override onlyMinter {
        uint256 shares = _bondsToShares(amount);
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
        uint256 sharesToBurn = _bondsToShares(amount);
        _pendingBurn[account] = burnableAmount.sub(amount);
        _pendingBurnsTotal = _pendingBurnsTotal.sub(amount);
        _burn(account, sharesToBurn);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToSharesCeil(amount);
        super.transfer(recipient, shares);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _sharesToBonds(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToSharesCeil(amount);
        super.approve(spender, shares);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToSharesCeil(amount);
        super.transferFrom(sender, recipient, shares);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        uint256 shares = _bondsToShares(addedValue);
        super.increaseAllowance(spender, shares);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 shares = _bondsToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        return true;
    }

    function _bondsToShares(uint256 amount) internal view returns (uint256) {
        return safeMultiplyAndDivide(amount, _ratio, 1e18);
    }

    function _bondsToSharesCeil(uint256 amount) internal view returns (uint256) {
        return safeCeilMultiplyAndDivide(amount, _ratio, 1e18);
    }

    function _sharesToBonds(uint256 amount) internal view returns (uint256) {
        return safeMultiplyAndDivide(amount, 1e18, _ratio);
    }

    function _sharesToBondsCeil(uint256 amount) internal view returns (uint256) {
        return safeCeilMultiplyAndDivide(amount, 1e18, _ratio);
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
        require(msg.sender == owner() || msg.sender == _polygonPool, "Minter: not allowed");
        _;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function changePolygonPool(address polygonPool) public onlyOwner {
        _polygonPool = polygonPool;
    }

    function changeCrossChainBridge(address crossChainBridge) public onlyOwner {
        _crossChainBridge = crossChainBridge;
    }

    function lockedSupply() public view returns (int256) {
        return _lockedShares;
    }

    function name() public view override returns (string memory) {
        if (bytes(_name).length != 0) {
            return _name;
        }
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        if (bytes(_symbol).length != 0) {
            return _symbol;
        }
        return super.symbol();
    }

    function setNameAndSymbol(string memory new_name, string memory new_symbol) public onlyOperator {
        _name = new_name;
        _symbol = new_symbol;
    }

    function safeMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 reminder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(reminder.mul(b).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }

    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 reminder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(reminder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }
}
