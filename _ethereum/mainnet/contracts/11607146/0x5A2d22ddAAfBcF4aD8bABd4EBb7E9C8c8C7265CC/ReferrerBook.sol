// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\access\Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: contracts\IReferrerBook.sol

pragma solidity 0.6.12;

interface IReferrerBook {
    function getReferrer(address addr) external view returns(address);
    function getLevelDiffedReferrers(address addr) external view returns (address[2] memory);
}

// File: contracts\ReferrerBook.sol

pragma solidity 0.6.12;



contract ReferrerBook is IReferrerBook, Ownable {
    address public root;

    struct UserInfo {
        address referrer;
        uint256 level;
    }

    mapping(address => UserInfo) public users;

    address public levelSetter;

    address constant ZERO_ADDRESS = address(0);
    uint256 public constant MAX_LEVEL = 2;

    event ReferrerSetted(address indexed user, address indexed referrer, uint256 timestampSec);
    event UserLevelSetted(address indexed user, uint256 level, uint256 timestampSec);

    modifier onlyLevelSetter() {
        require(msg.sender == levelSetter, 'Only node setter');
        _;
    }

    constructor() public {
        levelSetter = msg.sender;

        root = msg.sender;
        users[root] = UserInfo(address(this), 0);
        emit ReferrerSetted(root, address(this), now);
    }

    function setReferrer(address addr) external {
        require(addr != ZERO_ADDRESS, 'referrer == 0');
        require(users[addr].referrer != ZERO_ADDRESS, 'referrer not in the list');
        require(users[msg.sender].referrer == ZERO_ADDRESS, 'referrer already exists');
        require(addr != msg.sender, 'referrer cannot be one self');

        users[msg.sender] = UserInfo(addr, 0);

        emit ReferrerSetted(msg.sender, addr, now);
    }

    function getReferrer(address addr) external view override returns (address) {
        return users[addr].referrer;
    }

    function setLevelSetter(address addr) external onlyOwner {
        levelSetter = addr;
    }

    function setUserLevel(address addr, uint256 level) external onlyLevelSetter {
        require(addr != ZERO_ADDRESS, 'addr == 0');
        require(users[addr].referrer != ZERO_ADDRESS, 'addr not in the list');
        require(level <= MAX_LEVEL, 'level exceed');

        users[addr].level = level;

        emit UserLevelSetted(addr, level, now);
    }

    function getLevel(address addr) external view returns (uint256) {
        return users[addr].level;
    }

    function getLevelDiffedReferrers(address addr) external view override returns (address[MAX_LEVEL] memory refs) {
        UserInfo memory info = users[addr];
        uint256 maxLevel = info.level;
        address ref = info.referrer;

        uint256 loopCount = 0; //avoiding out of gas
        while (maxLevel < MAX_LEVEL && ref != ZERO_ADDRESS && loopCount++ < 100) {
            info = users[ref];
            uint256 level = info.level;
            if (level > maxLevel) {
                refs[level - 1] = ref;
                maxLevel = level;
            }
            ref = info.referrer;
        }
    }
}