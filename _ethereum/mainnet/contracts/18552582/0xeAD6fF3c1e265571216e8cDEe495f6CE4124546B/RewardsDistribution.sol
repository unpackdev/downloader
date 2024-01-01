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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/Administrable.sol


pragma solidity ^0.8.21;



contract Administrable is Pausable, Ownable {
    error AdministrableCallerMustBeAdmin();
    error AdministrableAlreadyAnAdmin();
    error AdministrableNotAnAdmin();

    mapping(address => bool) private _admins;

    constructor(address[] memory _initialAdmins){
        for (uint256 i = 0; i < _initialAdmins.length; i++) {
            _admins[_initialAdmins[i]] = true;
        }
    }

    function addAdminRights(address _newAdmin) external onlyOwner {
        if (_isAdmin(_newAdmin)) revert AdministrableAlreadyAnAdmin();
        _admins[_newAdmin] = true;
    }

    function revokeAdminRights(address _admin) external onlyOwner {
        if (!_isAdmin(_admin)) revert AdministrableNotAnAdmin();
        delete _admins[_admin];
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function _isAdmin(address _user) internal view returns (bool){
        return _admins[_user];
    }

    modifier onlyAdmin(){
        if (!_admins[_msgSender()]) revert AdministrableCallerMustBeAdmin();
        _;
    }
}
// File: contracts/RewardsDistribution.sol


pragma solidity ^0.8.21;


contract RewardsDistribution is Administrable {
    bytes32 public merkleRoot;
    uint256 public rootVersion = 1;
    uint256 public lastMerkleRootUpdateTimestamp;
    uint256 public transferAndTerminationTimestamp = type(uint256).max;
    uint256 public fundsGatheredInPeriod;

    mapping(address => uint256) public lastClaimedVersion;

    event RewardsClaimed(address claimer, uint256 amount);
    event FundsReceived(address sender, uint256 amount);
    event MerkleRootUpdated();
    event TransferAndTerminateNotified(uint256 transferTimestamp);
    event TransferredAndTerminated();

    constructor(address[] memory _initialAdmins) Administrable(_initialAdmins) {}

    function updateMerkleRootAndUnpause(bytes32 _newRoot, bool mustUnpause) external onlyAdmin {
        require(paused(), "RewardsDistribution: Contract must be paused");

        merkleRoot = _newRoot;
        rootVersion += 1;
        lastMerkleRootUpdateTimestamp = block.timestamp;
        fundsGatheredInPeriod = 0;
        if (mustUnpause && paused()) {
            unpause();
        }
    }

    function verifyProof(address _user, uint256 _fullRewardsAmount, bytes32[] calldata _proof) public view returns (bool){
        bytes32 hash = keccak256(abi.encodePacked(_user, _fullRewardsAmount));

        for (uint256 i = 0; i < _proof.length; i++) {
            hash = _computeMerkleProofNodes(hash, _proof[i]);
        }

        return hash == merkleRoot;
    }

    function claimRewards(uint256 _fullRewardsAmount, bytes32[] calldata _proof) external whenNotPaused {
        require(lastClaimedVersion[msg.sender] < rootVersion, "RewardsDistribution: Reward already claimed");
        require(address(this).balance >= _fullRewardsAmount, "RewardsDistribution: Not enough funds in contract");
        require(verifyProof(msg.sender, _fullRewardsAmount, _proof), "RewardsDistribution: Invalid proof");

        lastClaimedVersion[msg.sender] = rootVersion;
        emit RewardsClaimed(msg.sender, _fullRewardsAmount);

        (bool success,) = payable(msg.sender).call{value: _fullRewardsAmount}("");
        require(success, "RewardsDistribution: Failed to send reward");
    }

    receive() external payable {
        handleFundsReception();
    }

    fallback() external payable {
        handleFundsReception();
    }

    function handleFundsReception() internal {
        fundsGatheredInPeriod += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }

    function notifyTransferAndTermination() public onlyAdmin {
        transferAndTerminationTimestamp = block.timestamp + 30 days;
        emit TransferAndTerminateNotified(transferAndTerminationTimestamp);
    }

    function cancelTransferAndTerminationNotice() public onlyAdmin {
        transferAndTerminationTimestamp = type(uint256).max;
        emit TransferAndTerminateNotified(transferAndTerminationTimestamp);
    }

    function transferFundsAndTerminate(address _to) external onlyAdmin {
        require(block.timestamp >= transferAndTerminationTimestamp, "RewardsDistribution: 30 days notice period not yet passed");

        transferAndTerminationTimestamp = type(uint256).max;
        emit TransferredAndTerminated();
        if (!paused()) {
            pause();
        }

        (bool sent,) = payable(_to).call{value: address(this).balance}("");
        require(sent, "RewardsDistribution: Funds transfer failed");
    }

    function _computeMerkleProofNodes(bytes32 a, bytes32 b) internal pure returns (bytes32){
        return keccak256(a < b ? abi.encodePacked(a, b) : abi.encodePacked(b, a));
    }
}