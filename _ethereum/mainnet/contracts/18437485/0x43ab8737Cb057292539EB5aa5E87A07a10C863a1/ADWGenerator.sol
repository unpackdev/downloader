// File @openzeppelin/contracts/utils/Context.sol@v4.6.0

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/Ownable.sol@v4.6.0


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File contracts/ADWKeyless.sol



pragma solidity ^0.8.17;

contract ADWGenerator is Ownable {
    event NewCreation(
        address indexed _from,
        uint256 tokenId,
        bytes32 submission
    );
    struct Fees {
        uint256 basic_fee;
        uint256 drippy_fee;
        uint256 legendary_fee;
        uint256 mythic_fee;
    }

    mapping(uint256 => bytes32) public submissions;
    mapping(uint256 => uint256) public customFees;
    bool public creationisActive = true;
    Fees public creationFees =
        Fees(0.0033 ether, 0.0066 ether, 0.0099 ether, 0.0132 ether);

    uint256 public constant BASIC = 0;
    uint256 public constant DRIPPY = 1;
    uint256 public constant LEGENDARY = 2;
    uint256 public constant MYTHIC = 3;

    modifier whenCreationActive() {
        require(creationisActive, "Public burn is not active");
        _;
    }

    function togglePublicBurnActive() public onlyOwner {
        creationisActive = !creationisActive;
    }

    function setCreationFee(
        uint256 newBasic,
        uint256 newDrippy,
        uint256 newLegendary,
        uint256 newMythic
    ) public onlyOwner {
        creationFees.basic_fee = newBasic;
        creationFees.drippy_fee = newDrippy;
        creationFees.legendary_fee = newLegendary;
        creationFees.mythic_fee = newMythic;
    }

    function createCustomFee(uint256 tier, uint256 price) public onlyOwner {
        require(tier > 3, "invalid tier");
        customFees[tier] = price;
    }

    function submit(
        uint256 tokenId,
        uint256 tier,
        bytes32 submission
    ) public payable whenCreationActive {
        if (tier == BASIC) {
            require(msg.value >= creationFees.basic_fee, "Invalid fee");
        } else if (tier == DRIPPY) {
            require(msg.value >= creationFees.drippy_fee, "Invalid fee");
        } else if (tier == LEGENDARY) {
            require(msg.value >= creationFees.legendary_fee, "Invalid fee");
        } else if (tier == MYTHIC) {
            require(msg.value >= creationFees.mythic_fee, "Invalid fee");
        } else if (customFees[tier] > 0) {
            require(msg.value >= customFees[tier], "Invalid fee");
        } else {
            revert("Invalid fee");
        }

        submissions[tokenId] = submission;
        emit NewCreation(msg.sender, tokenId, submission);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed");
    }
}