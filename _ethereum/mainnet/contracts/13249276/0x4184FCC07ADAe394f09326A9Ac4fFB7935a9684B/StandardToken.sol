// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    bool private initializedtonewowner = false;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnershipFromInitialized(address newOwner)
        internal
        virtual
    {
        require(
            !initializedtonewowner,
            "Contract owner has already been transfered from initialized to the new Owner"
        );
        initializedtonewowner = true;
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract StandardToken is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;

    string private _name;
    uint256 private _decimals;
    string private _symbol;
    uint256 private _totalSupply;
    bool public _isPool;

    mapping (address => uint256) public balance;
    address public pair;
    mapping (address => mapping(address => uint256)) public allowances;

    event DexPairCreated(address thisContract, address pairAddress);
    function init(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenInitialAmount,
        address newOwner,
        bool isPool,
        address dexAddress
    ) public {
        _decimals = 18;
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalSupply = tokenInitialAmount.mul(10**_decimals);
        _isPool = isPool;
        if (isPool) {
            _createPair(dexAddress);
        }
        transferOwnershipFromInitialized(newOwner);
        balance[newOwner] = _totalSupply;
        // emit Transfer(address(0), newOwner, totalSupply);

    }
    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balance[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(balance[_msgSender()] >= amount, "Insufficient Balance");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        balance[sender] = balance[sender].sub(amount);
        balance[recipient] = balance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Spender cannot be zero address");
        require(balance[_msgSender()] >= amount, "Insufficient Balance");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowances[owner][spender] = 0;
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address owner, address recipient, uint256 amount) public override returns (bool) {
        require(balance[owner] >= amount, "Insufficient owner balance");
        require(allowances[owner][_msgSender()] >= amount, "Not enough allowance");
        balance[owner] = balance[owner].sub(amount);
        allowances[owner][_msgSender()] = allowances[owner][_msgSender()].sub(amount);
        balance[recipient] = balance[recipient].add(amount);
        emit Transfer(owner, recipient, amount);
        return true;
    }

    function _createPair(address dexAddress) private {
        IUniswapV2Router02 _router = IUniswapV2Router02(dexAddress);
        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        emit DexPairCreated(address(this), pair);
    }

    function pairAddress() public view returns (address) {
        require(_isPool, "Pair not created from factory");
        return pair;
    }
}
