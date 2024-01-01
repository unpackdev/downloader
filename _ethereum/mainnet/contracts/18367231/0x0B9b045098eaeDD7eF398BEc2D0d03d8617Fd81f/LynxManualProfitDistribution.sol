//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ILynx is IERC20 {
    function getUserSnapshotAt(
        address user,
        uint snapId
    ) external view returns (uint);

    function takeSnapshot() external;

    function snapshots(
        uint snapshotId
    ) external view returns (uint t1Total, uint t2Total, uint timestamp);

    function currentSnapId() external view returns (uint);

    function isDividendExempt(address user) external view returns (bool);
}

error LynxPS__InvalidMsgValue();
error LynxPS__InvalidIndexesLength();
error LynxPS__InvalidClaimer();
error LynxPS__ExcludedClaimer();
error LynxPS__AlreadyClaimedOrInvalidSnapshotClaim();
error LynxPS__ETHTransferFailed();
error LynxPS__VerificationTierFailure(uint snapId, uint tierQ, uint tierV);
error LynxPS__InvalidReclaim();
error LynxPS__InvalidTierDistribution();

contract LynxManualProfitDistribution is Ownable, ReentrancyGuard {
    //------------------------
    //  Type Definitions
    //------------------------
    struct Snapshot {
        address[] holders;
        uint128[] balances;
        uint128 totalTier1;
        uint128 totalTier2;
        uint128 t1Claimed;
        uint128 t2Claimed;
        uint128 t1Distribution;
        uint128 t2Distribution;
        bool fullClaim;
    }
    //------------------------
    //  State Variables
    //------------------------
    ILynx public immutable lynx;
    mapping(uint _snapId => Snapshot) public snapshots;
    mapping(address user => mapping(uint _snapId => bool)) public claimed;
    mapping(address user => bool) public excluded;

    uint128 public tier1;
    uint128 public tier2;
    uint128 public totalTiers;
    uint private constant TIER1 = 50_000 ether;
    uint private constant TIER2 = 1_000 ether;
    uint128 private constant MAGNIFIER = 1 ether;

    //------------------------
    //  Events
    //------------------------
    event CreateSnapshot(
        uint indexed snapId,
        uint128 t1Distribution,
        uint128 t2Distribution
    );

    event ExcludeAddress(address indexed user);
    event ExcludeMultipleAddresses(address[] indexed users);
    event ReclaimDivs(uint indexed snapId, uint128 amount);
    event TierDistributionChanged(uint128 t1, uint128 t2);

    //------------------------
    //  Constructor
    //------------------------
    constructor(address _lynx, address _newOwner) {
        lynx = ILynx(_lynx);
        tier1 = 60;
        tier2 = 40;
        totalTiers = 100;
        transferOwnership(_newOwner);
        excluded[address(0)] = true;
    }

    //------------------------
    //  External Functions
    //------------------------

    /**
     *
     * @param holders Array to all VALID holders
     * @param balances Array of balances of each holder
     * @param t1Excluded Amount of tokens excluded from TIER 1 (That are not already divExcluded in Token)
     * @param t2Excluded Amount of tokens excluded from TIER 2 (That are not already divExcluded in Token)
     */
    function createSnapshot(
        address[] calldata holders,
        uint128[] calldata balances,
        uint128 t1Excluded,
        uint128 t2Excluded
    ) external payable onlyOwner {
        if (msg.value == 0) revert LynxPS__InvalidMsgValue();
        // TAKE SNAPSHOT
        uint currentSnapId = lynx.currentSnapId();
        lynx.takeSnapshot();
        // GET TOTAL TIERS FROM SNAPSHOT
        (uint tier1Total, uint tier2Total, ) = lynx.snapshots(currentSnapId);
        tier1Total -= t1Excluded;
        tier2Total -= t2Excluded;
        // SET TIMESTAMP (JUST FOR REFERENCE)
        snapshots[currentSnapId].totalTier1 = uint128(tier1Total);
        snapshots[currentSnapId].totalTier2 = uint128(tier2Total);
        snapshots[currentSnapId].holders = holders;
        snapshots[currentSnapId].balances = balances;
        // GET THE DISTRIBUTION AMOUNTS PER TOKEN
        uint128 t1Distribution = (uint128(msg.value) * tier1) / totalTiers;
        uint128 t2Distribution = uint128(msg.value) - t1Distribution;

        t1Distribution = (t1Distribution * MAGNIFIER) / uint128(tier1Total);
        t2Distribution = (t2Distribution * MAGNIFIER) / uint128(tier2Total);
        snapshots[currentSnapId].t1Distribution = uint128(t1Distribution);
        snapshots[currentSnapId].t2Distribution = uint128(t2Distribution);
        emit CreateSnapshot(currentSnapId, t1Distribution, t2Distribution);
    }

    /**
     *
     * @param claimIds Array of snapshot IDs to claim
     * @param claimQualifierIndexId The index of the user in the qualifier snapshot
     * @param claimVerifierIndexId The index of the user in the verifier snapshot
     */
    function claimDivs(
        uint[] calldata claimIds,
        uint[] calldata claimQualifierIndexId,
        uint[] calldata claimVerifierIndexId
    ) external nonReentrant {
        if (excluded[msg.sender]) revert LynxPS__ExcludedClaimer();
        uint currentSnapId = lynx.currentSnapId();
        uint claimsLength = claimIds.length;
        if (
            claimsLength != claimQualifierIndexId.length ||
            claimsLength != claimVerifierIndexId.length
        ) revert LynxPS__InvalidIndexesLength();
        uint128 totalReward;
        for (uint8 i = 0; i < claimsLength; i++) {
            uint qualifyId = claimIds[i];
            uint verifyId = qualifyId + 1;
            // Already claimed || invalid claimID
            if (
                claimed[msg.sender][qualifyId] ||
                qualifyId >= currentSnapId ||
                snapshots[qualifyId].fullClaim
            ) revert LynxPS__AlreadyClaimedOrInvalidSnapshotClaim();
            if (
                snapshots[qualifyId].holders[claimQualifierIndexId[i]] !=
                msg.sender ||
                snapshots[verifyId].holders[claimVerifierIndexId[i]] !=
                msg.sender
            ) revert LynxPS__InvalidClaimer();

            // Get balances
            uint128 qualifyBalance = snapshots[qualifyId].balances[
                claimQualifierIndexId[i]
            ];
            uint128 verifyBalance = snapshots[verifyId].balances[
                claimVerifierIndexId[i]
            ];

            // Verify initial Tier
            uint8 initialTier = getTierOfBalance(qualifyBalance);
            if (initialTier == 0)
                revert LynxPS__VerificationTierFailure(
                    qualifyId,
                    initialTier,
                    0
                );
            uint8 verifyTier = getTierOfBalance(verifyBalance);
            // Check balances remained in same tier
            if (initialTier != verifyTier)
                revert LynxPS__VerificationTierFailure(
                    qualifyId,
                    initialTier,
                    verifyTier
                );
            totalReward += calculateReward(
                qualifyId,
                qualifyBalance,
                initialTier
            );
        }

        totalReward /= MAGNIFIER;

        if (totalReward > 0) {
            (bool status, ) = payable(msg.sender).call{value: totalReward}("");
            if (!status) revert LynxPS__ETHTransferFailed();
        }
    }

    /**
     * Excluded users can't claim rewards forever
     * @param _user User to exclude
     */
    function excludeUser(address _user) external onlyOwner {
        _excludeUser(_user);
        emit ExcludeAddress(_user);
    }

    /**
     * Excluded users can't claim rewards forever
     * @param _users Array of users to exclude
     */
    function excludeMultipleUsers(
        address[] calldata _users
    ) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            _excludeUser(_users[i]);
        }
        emit ExcludeMultipleAddresses(_users);
    }

    /**
     * To prevent stuck rewards for too long (and incentivize more user interaction)
     * @param id Snapshot ID to remove unclaimed rewards from
     * @dev This function can only be called 30 days after the snapshot by owner
     */
    function removeUnclaimedRewards(uint id) external onlyOwner {
        // unclaimed can only be called 30days after the snapshot
        (, , uint snapshotTimestamp) = lynx.snapshots(id);
        Snapshot storage snap = snapshots[id];
        if (block.timestamp < snapshotTimestamp + 30 days || snap.fullClaim)
            revert LynxPS__InvalidReclaim();
        uint128 t1Unclaimed = snap.totalTier1 *
            snap.t1Distribution -
            snap.t1Claimed;
        uint128 t2Unclaimed = snap.totalTier2 *
            snap.t2Distribution -
            snap.t2Claimed;

        snap.t1Claimed += t1Unclaimed;
        snap.t2Claimed += t2Unclaimed;
        snap.fullClaim = true;

        t1Unclaimed += t2Unclaimed;
        t1Unclaimed = t1Unclaimed / MAGNIFIER;

        emit ReclaimDivs(id, t1Unclaimed);
        if (t1Unclaimed > 1 gwei) {
            (bool status, ) = payable(owner()).call{value: t1Unclaimed}("");
            if (!status) revert LynxPS__ETHTransferFailed();
        }
    }

    /**
     * @notice Sets the tier distribution
     * @param _t1 new Tier 1 distribution amount
     * @param _t2 new tier 2 distribution amount
     */
    function setTierDistribution(uint _t1, uint _t2) external onlyOwner {
        tier1 = uint128(_t1);
        tier2 = uint128(_t2);
        totalTiers = uint128(_t1 + _t2);

        if (totalTiers == 0) revert LynxPS__InvalidTierDistribution();
        emit TierDistributionChanged(tier1, tier2);
    }

    //------------------------
    //  Private Functions
    //------------------------

    /**
     * Change excluded status to true
     * @param _user User to set
     */
    function _excludeUser(address _user) private {
        if (_user == address(0)) revert LynxPS__ExcludedClaimer();
        excluded[_user] = true;
    }

    /**
     *
     * @param snapId ID of the snapshot
     * @param balance Of the user
     * @param _tier to check rewards against
     * @return _reward Amount of rewards Magnified
     * @dev the rewards are magnified so we can do a single division for all things
     */
    function calculateReward(
        uint snapId,
        uint128 balance,
        uint8 _tier
    ) private returns (uint128 _reward) {
        uint128 reward;
        if (_tier == 1) {
            reward = (balance * snapshots[snapId].t1Distribution);
            snapshots[snapId].t1Claimed += reward;
        } else if (_tier == 2) {
            reward = (balance * snapshots[snapId].t2Distribution);
            snapshots[snapId].t2Claimed += reward;
        }
        claimed[msg.sender][snapId] = true;
        return reward;
    }

    //------------------------
    //  View Functions
    //------------------------

    /**
     * Get the index of the user in the snapshot
     * @param snapId The snapshotID to check
     * @param user The user we're searching the Index for
     */
    function getIndexOfUser(
        uint snapId,
        address user
    ) public view returns (uint) {
        uint maxLength = snapshots[snapId].holders.length;
        for (uint i = 0; i < maxLength; i++) {
            if (snapshots[snapId].holders[i] == user) return i;
        }
        return type(uint).max;
    }

    /**
     * Return all indexes of the user in the specific snapshots
     * @param ids Array of snapshot IDs to check
     * @return qualifierIndexes Indexes of the user in the qualifier snapshot
     * @return verificationIndexes Indexes of the user in the verifier snapshot
     * @dev if the user is NOT found in snapshot, the index will be type(uint).max
     * @dev THIS FUNCTION IS ONLY MEANT TO BE CALLED IN THE FRONTEND DUE TO THE EXTREME GAS USAGE IF USED IN CONTRACT
     */
    function getIndexesOfUser(
        uint[] calldata ids
    )
        external
        view
        returns (
            uint[] memory qualifierIndexes,
            uint[] memory verificationIndexes
        )
    {
        uint length = ids.length;
        qualifierIndexes = new uint[](length);
        verificationIndexes = new uint[](length);
        uint currentIndex = lynx.currentSnapId();
        for (uint i = 0; i < length; i++) {
            if (ids[i] >= currentIndex) {
                qualifierIndexes[i] = type(uint).max;
                verificationIndexes[i] = type(uint).max;
                continue;
            }
            uint checkId = ids[i];
            // get qualification index
            qualifierIndexes[i] = getIndexOfUser(checkId, msg.sender);
            // get verification index
            checkId++;
            verificationIndexes[i] = getIndexOfUser(checkId, msg.sender);
        }
    }

    /**
     * @notice Returns all snapshots and the user's index in each snapshot
     * @param user User to check
     * @return qualfierIndexes This is an array of length of all snapshots, the value is the index of the user in the snapshot, while the index is the snapshot ID
     * @return verificationIndexes This is an array of length of all snapshots, the value is the index of the user in the snapshot, while the index is the snapshot ID for the verication
     * @return balances this is the array of user balances per each snapshot
     * @return claimable If the index is already claimed
     * @dev THIS FUNCTION IS ONLY MEANT TO BE CALLED IN THE FRONTEND DUE TO THE EXTREME GAS USAGE IF USED IN CONTRACT
     * @dev if the user is NOT found in snapshot, the value at the index will be type(uint).max
     */
    function getAllUserParticipatingSnapshots(
        address user
    )
        external
        view
        returns (
            uint[] memory qualfierIndexes,
            uint[] memory verificationIndexes,
            uint128[] memory balances,
            bool[] memory claimable
        )
    {
        uint currentSnapId = lynx.currentSnapId();
        qualfierIndexes = new uint[](currentSnapId);
        balances = new uint128[](currentSnapId);
        claimable = new bool[](currentSnapId);
        for (uint i = 0; i < currentSnapId; i++) {
            uint qualifyIndex = getIndexOfUser(i, user);
            qualfierIndexes[i] = qualifyIndex;
            verificationIndexes[i] = getIndexOfUser(i + 1, user);
            claimable[i] = !claimed[user][i];
            if (qualifyIndex == type(uint).max) continue;
            balances[i] = snapshots[i].balances[qualifyIndex];
        }
    }

    //------------------------
    //  Pure Functions
    //------------------------

    /**
     * Return the tier the balance belongs to ( NO TIER - 0, TIER 1 - 1, TIER 2 - 2)
     * @param amount Amount to check
     * @return _tier Tier of the balance
     */
    function getTierOfBalance(uint amount) private pure returns (uint8 _tier) {
        if (amount >= TIER1) return 1;
        if (amount >= TIER2) return 2;
        return 0;
    }
}