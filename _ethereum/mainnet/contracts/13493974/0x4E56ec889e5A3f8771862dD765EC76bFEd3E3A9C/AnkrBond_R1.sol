// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./ERC20Transparent.sol";

import "./IAnkrBond_R1.sol";
import "./IOwnable.sol";
import "./IPausable.sol";

contract AnkrBond_R1 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20Transparent, ERC165Upgradeable, IAnkrBond_R1 {

    address private _operator;
    address private _pool;
    // ratio should be base on 1 DOT, if ratio is 0.9, this variable should be 9e17
    uint256 private _ratio;
    uint8 private _decimals;

    // token will be like DOT or KSM
    function initialize(address operator, address pool, string memory token, uint8 initDecimals) public override initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __AnkrBond_init(operator, pool, token, initDecimals);
    }

    function __AnkrBond_init(address operator, address pool, string memory token, uint8 initDecimals) internal {
        string memory name = string(abi.encodePacked("Ankr ", token, " Reward Earning Bond"));
        string memory symbol = string(abi.encodePacked("a", token, "b"));
        __ERC20_init(name, symbol);
        _operator = operator;
        _pool = pool;
        _ratio = 1e18;
        _decimals = initDecimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setDecimals(uint8 newDecimals) public onlyPoolOrOperator {
        _decimals = newDecimals;
    }

    function setName(string calldata name) external onlyOwner {
        _name = name;
    }

    function setSymbol(string calldata symbol) external onlyOwner {
        _symbol = symbol;
    }

    function ratio() public override view returns (uint256) {
        return _ratio;
    }

    function updateRatio(uint256 newRatio) public onlyPoolOrOperator {
        require(newRatio > 0, "Ratio must be positive");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return sharesToBalance(supply);
    }

    function totalSharesSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return sharesToBalance(super.balanceOf(account));
    }

    function sharesOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = balanceToShares(amount);
        //Replacement of super.transfer(recipient, shares) to emit proper amount
        address sender = msg.sender;
        _balances[sender] -= shares; // solidity ^0.8.0 does overflow check be default
        _balances[recipient] += shares;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return sharesToBalance(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = balanceToShares(amount);
        super.approve(spender, shares);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = balanceToShares(amount);
        super.transferFrom(sender, recipient, shares);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        uint256 shares = balanceToShares(addedValue);
        super.increaseAllowance(spender, shares);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 shares = balanceToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        return true;
    }

    function mintSharesTo(address owner, uint256 amount) public override onlyPoolOrOperator {
        _mint(owner, amount);
    }

    function burnSharesFrom(address owner, uint256 amount) public override onlyPoolOrOperator {
        _burn(owner, amount);
    }

    function balanceToShares(uint256 amount) public override view returns (uint256) {
        return multiplyAndDivideFloor(amount, _ratio, 1e18);
    }

    function sharesToBalance(uint256 amount) public view returns (uint256) {
        return multiplyAndDivideCeil(amount, 1e18, _ratio);
    }

    modifier onlyPoolOrOperator() {
        require(msg.sender == _pool || msg.sender == _operator, "onlyPoolOrOperator: not allowed");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId)
        || interfaceId == type(IOwnable).interfaceId
        || interfaceId == type(IPausable).interfaceId
        || interfaceId == type(IERC20Upgradeable).interfaceId
        || interfaceId == type(IERC20MetadataUpgradeable).interfaceId
        || interfaceId == type(IAnkrBond_R1).interfaceId;
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: floor((a * b) / c)
    function multiplyAndDivideFloor(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a / c) * b + ((a % c) * b) / c;
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: ceil((a * b) / c)
    function multiplyAndDivideCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return (a / c) * b + ((a % c) * b + (c - 1)) / c;
    }
}