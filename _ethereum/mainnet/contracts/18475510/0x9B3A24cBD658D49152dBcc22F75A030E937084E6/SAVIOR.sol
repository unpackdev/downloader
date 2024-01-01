/*

http://saviorcoin66.com/
https://twitter.com/SaviorCoin66?t=kMYP344exYrRkvpLFRRwUA&s=09
https://t.me/SaviorCoin66

*/
// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Savior Coin.sol



pragma solidity ^0.8.22;


// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// ----------------------------------------------------------------------------

interface ERC20Interface {

    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

}


// ----------------------------------------------------------------------------

// Safe Math Library

// ----------------------------------------------------------------------------

library SafeMath {

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {

        c = a + b;

        require(c >= a, "SafeMath: addition overflow");

    }


    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {

        require(b <= a, "SafeMath: subtraction overflow");

        c = a - b;

    }


    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {

        c = a * b;

        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");

    }


    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {

        require(b > 0, "SafeMath: division by zero");

        c = a / b;

    }

}


contract SAVIOR is ERC20Interface, Ownable {

    using SafeMath for uint256;


    string public name;

    string public symbol;

    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it


    uint256 public totalSupply;


    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;


    constructor() Ownable(msg.sender) {
    name = "Savior Coin";
    symbol = "SAVIOR";
    decimals = 18;
    totalSupply = 8000000066000000000000000000;
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
}


    function balanceOf(address tokenOwner) public view override returns (uint256) {

        return balances[tokenOwner];

    }


    function transfer(address to, uint256 tokens) public override returns (bool) {

        require(to != address(0), "SAVIOR: transfer to the zero address");

        require(tokens <= balances[msg.sender], "SAVIOR: transfer amount exceeds balance");


        balances[msg.sender] = balances[msg.sender].safeSub(tokens);

        balances[to] = balances[to].safeAdd(tokens);


        emit Transfer(msg.sender, to, tokens);

        return true;

    }


    function allowance(address tokenOwner, address spender) public view override returns (uint256) {

        return allowances[tokenOwner][spender];

    }


    function approve(address spender, uint256 tokens) public override returns (bool) {

        allowances[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }


    function transferFrom(address from, address to, uint256 tokens) public override returns (bool) {

        require(from != address(0), "SAVIOR: transfer from the zero address");

        require(to != address(0), "SAVIOR: transfer to the zero address");

        require(tokens <= balances[from], "SAVIOR: transfer amount exceeds balance");

        require(tokens <= allowances[from][msg.sender], "SAVIOR: transfer amount exceeds allowance");


        balances[from] = balances[from].safeSub(tokens);

        balances[to] = balances[to].safeAdd(tokens);

        allowances[from][msg.sender] = allowances[from][msg.sender].safeSub(tokens);


        emit Transfer(from, to, tokens);

        return true;

    }


}