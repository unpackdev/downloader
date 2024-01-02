// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReferralRegistry {
    mapping(address => address) public referrals; // Maps a referee to the referrer

    event ReferralSet(address indexed referee, address indexed referrer);

    constructor() {}

    // Set a referrer for a referee
    function setReferral(address referee, address referrer) external {
        require(referee != referrer, "Cannot refer oneself");
        require(referrals[referee] == address(0), "Referrer already set");
        referrals[referee] = referrer;
        emit ReferralSet(referee, referrer);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

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

contract Bitman is Ownable {

    address public treasuryAddress;

    IERC20 public coin;

    ReferralRegistry public referralRegistry;
    
    uint256 public gameCost;

    event StartGame(
        address indexed player,
        uint256 gameId
    );

    constructor(uint256 _cost, address _coinAddress) Ownable(msg.sender) {
        gameCost = _cost;
        coin = IERC20(_coinAddress);
    }

    function setReferralRegistry(address registryAddress) external onlyOwner {
        referralRegistry = ReferralRegistry(registryAddress);
    }

    function setGameCost(uint256 cost) external onlyOwner {
        require(cost > 0, "ZERO_COST");
        gameCost = cost;
    }

    function startGame(address player) external {
        require(msg.sender == player, "WALLET_NOT_OWNED");

        uint256 fee = gameCost;
        if (address(referralRegistry) != address(0)) {
            address referrer = referralRegistry.referrals(player);
            if (referrer != address(0)) {
                uint256 discount = fee * 5 / 100; // Calculate 5% of the fee
                fee -= discount;                  // Reduce the fee by the calculated discount
                require(coin.transferFrom(player, referrer, discount), "TRANSFER_FAILED");
            }
        }

        require(coin.transferFrom(player, address(this), fee), "TRANSFER_FAILED");

        emit StartGame(player, gameCost);
    }
}