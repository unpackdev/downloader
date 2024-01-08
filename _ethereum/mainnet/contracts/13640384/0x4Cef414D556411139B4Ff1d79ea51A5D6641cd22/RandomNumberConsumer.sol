pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FulfilledVRF(bytes32 indexed requestId, uint256 indexed randomness);

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

contract RandomNumberConsumer is VRFConsumerBase, Ownable {

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => uint256) public randomResult;
    mapping(address => bool) public approvedRandomnessRequesters;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee
    )
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(approvedRandomnessRequesters[msg.sender], "RandomNumberConsumer::getRandomNumber: msg.sender is not an approved requester of randomness");
        require(LINK.balanceOf(address(this)) >= fee, "RandomNumberConsumer::getRandomNumber: Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function setRandomnessRequesterApproval(address _requester, bool _approvalStatus) public onlyOwner {
        approvedRandomnessRequesters[_requester] = _approvalStatus;
    }

    /**
     * Reads fulfilled randomness for a given request ID
     */
    function readFulfilledRandomness(bytes32 requestId) public view returns (uint256) {
        return randomResult[requestId];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult[requestId] = randomness;
        emit FulfilledVRF(requestId, randomness);
    }

    function withdrawLink(address _destination) external onlyOwner {
      LINK.transferFrom(address(this), _destination, LINK.balanceOf(address(this)));
    }
}
