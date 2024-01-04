// Dependency file: contracts/controller/Storage.sol

// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;


contract Storage {
    // percent value must be multiple by 1e6
    uint256[] marketingLevels;

    // array of addresses which have already registered account
    address[] accountList;

    // bind left with right
    // THE RULE: the child referred by the parent
    mapping(address => address) referrals;

    // whitelist root tree of marketing level
    mapping(address => bool) whitelistRoots;

    function getTotalAccount() public view returns(uint256) {
        return accountList.length;
    }

    function getAccountList() public view returns(address[] memory) {
        return accountList;
    }

    function getReferenceBy(address _child) public view returns(address) {
        return referrals[_child];
    }

    function getMarketingMaxLevel() public view returns(uint256) {
        return marketingLevels.length;
    }

    function getMarketingLevelValue(uint256 _level) public view returns(uint256) {
        return marketingLevels[_level];
    }

    // get reference parent address matching the level tree
    function getReferenceParent(address _child, uint256 _level) public view returns(address) {
        uint i;
        address pointer = _child;

        while(i < marketingLevels.length) {
            pointer = referrals[pointer];

            if (i == _level) {
                return pointer;
            }

            i++;
        }

        return address(0);
    }

    function getWhiteListRoot(address _root) public view returns(bool) {
        return whitelistRoots[_root];
    }
}


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "./Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Root file: contracts/controller/Controller.sol


pragma solidity 0.6.12;

// import "./Storage.sol";
// import "./Ownable.sol";


contract Controller is Storage, Ownable {
    event LinkCreated(address indexed addr, address indexed refer);

    constructor() public {
        // init marketing level values
        // level from 1 -> 8
        marketingLevels.push(25e6); // 25%
        marketingLevels.push(20e6);
        marketingLevels.push(15e6);
        marketingLevels.push(10e6);
        marketingLevels.push(10e6);
        marketingLevels.push(10e6);
        marketingLevels.push(5e6);
        marketingLevels.push(5e6);
    }

    // user register referral address
    function register(address _refer) public {
        require(msg.sender != _refer, "ERROR: address cannot refer itself");
        require(referrals[msg.sender] == address(0), "ERROR: already set refer address");

        // owner address is the root of references tree
        if (_refer != owner() && !getWhiteListRoot(_refer)) {
            require(referrals[_refer] != address(0), "ERROR: invalid refer address");
        }

        // update reference tree
        referrals[msg.sender] = _refer;

        emit LinkCreated(msg.sender, _refer);
    }

    // admin update marketing level value
    function updateMarketingLevelValue(uint256 _level, uint256 _value) public onlyOwner {
        // value must be expo with 1e6
        // 25% -> 25e6
        marketingLevels[_level] = _value;
    }

    // add white list root tree
    function addWhiteListRoot(address _root) public onlyOwner {
        whitelistRoots[_root] = true;
    }
}