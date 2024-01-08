// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";

contract WaitlistBatch is Ownable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;

    /* ========== Types ========== */

    struct Batch {
        uint256 totalSpots;
        uint256 filledSpots;
        uint256 batchStartTimestamp;
        uint256 depositAmount;
        uint256 approvedAt;
    }

    struct UserBatchInfo {
        bool hasParticipated;
        uint256 batchNumber;
        uint256 depositAmount;
        uint256 depositRetrievalTimestamp;
    }

    /* ========== Variables ========== */

    address public moderator;

    IERC20 public depositCurrency;

    uint256 public nextBatchNumber;

    uint256 public depositLockupDuration;

    mapping (uint256 => mapping (address => uint256)) public userDepositMapping;

    mapping (uint256 => Batch) public batchMapping;

    mapping (address => uint256) public userBatchMapping;

    mapping (address => bool) public blacklist;

    /* ========== Events ========== */

    event AppliedToBatch(
        address indexed user,
        uint256 batchNumber,
        uint256 amount
    );

    event NewBatchAdded(
        uint256 totalSpots,
        uint256 batchStartTimestamp,
        uint256 depositAmount,
        uint256 batchNumber
    );

    event BatchApproved(uint256 _batchNumber);

    event BatchTimestampChanged(
        uint256 batchNumber,
        uint256 batchStartTimstamp
    );

    event BatchTotalSpotsUpdated(
        uint256 batchNumber,
        uint256 newTotalSpots
    );

    event TokensReclaimed(
        address user,
        uint256 amount
    );

    event TokensReclaimedBlacklist(
        address user,
        uint256 amount
    );

    event TokensTransferred(
        address tokenAddress,
        uint256 amount,
        address destination
    );

    event RemovedFromBlacklist(
        address user
    );

    event AddedToBlacklist(
        address user
    );

    event ModeratorSet(
        address user
    );

    event DepositLockupDurationSet(uint256 _depositLockupDuration);

    /* ========== Modifiers ========== */

    modifier onlyModerator() {
        require(
            msg.sender == moderator,
            "WaitlistBatch: caller is not moderator"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor(
        address _depositCurrency,
        uint256 _depositLockupDuration
    ) public {
        depositCurrency = IERC20(_depositCurrency);
        depositLockupDuration = _depositLockupDuration;

        // Set the next batch number to 1 to avoid some complications
        // caused by batch number 0
        nextBatchNumber = 1;
    }

    /* ========== Public Getters ========== */

    function getBatchInfoForUser(
        address _user
    )
        public
        view
        returns (UserBatchInfo memory)
    {
        uint256 participatingBatch = userBatchMapping[_user];

        return UserBatchInfo({
            hasParticipated: participatingBatch > 0,
            batchNumber: participatingBatch,
            depositAmount: userDepositMapping[participatingBatch][_user],
            depositRetrievalTimestamp: getDepositRetrievalTimestamp(_user)
        });
    }

    function getTotalNumberOfBatches()
        public
        view
        returns (uint256)
    {
        return nextBatchNumber - 1;
    }

    /**
     * @notice Returns the epoch when the user can withdraw their deposit
     */
    function getDepositRetrievalTimestamp(
        address _account
    )
        public
        view
        returns (uint256)
    {
        uint256 participatingBatch = userBatchMapping[_account];

        Batch memory batch = batchMapping[participatingBatch];

        return batch.approvedAt == 0
            ? 0
            : batch.approvedAt.add(depositLockupDuration);
    }

    /* ========== Public Functions ========== */

    function applyToBatch(
        uint256 _batchNumber
    )
        public
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: batch does not exist"
        );

        // Check if user already applied to a batch
        UserBatchInfo memory batchInfo = getBatchInfoForUser(msg.sender);
        require(
            !batchInfo.hasParticipated,
            "WaitlistBatch: cannot apply to more than one batch"
        );

        Batch storage batch = batchMapping[_batchNumber];

        require(
            batch.filledSpots < batch.totalSpots,
            "WaitlistBatch: batch is filled"
        );

        require(
            currentTimestamp() >= batch.batchStartTimestamp,
            "WaitlistBatch: cannot apply before the start time"
        );

        batch.filledSpots++;

        userDepositMapping[_batchNumber][msg.sender] = batch.depositAmount;
        userBatchMapping[msg.sender] = _batchNumber;

        SafeERC20.safeTransferFrom(
            depositCurrency,
            msg.sender,
            address(this),
            batch.depositAmount
        );

        emit AppliedToBatch(
            msg.sender,
            _batchNumber,
            batch.depositAmount
        );
    }

    function reclaimTokens()
        public
    {
        require(
            blacklist[msg.sender] == false,
            "WaitlistBatch: user is blacklisted"
        );

        UserBatchInfo memory batchInfo = getBatchInfoForUser(msg.sender);

        require(
            batchInfo.hasParticipated,
            "WaitlistBatch: user did not participate in a batch"
        );

        require(
            batchInfo.depositAmount > 0,
            "WaitlistBatch: there are no tokens to reclaim"
        );

        require(
            batchInfo.depositRetrievalTimestamp > 0,
            "WaitlistBatch: the batch is not approved yet"
        );

        require(
            batchInfo.depositRetrievalTimestamp <= currentTimestamp(),
            "WaitlistBatch: the deposit lockup duration has not passed yet"
        );

        userDepositMapping[batchInfo.batchNumber][msg.sender] -= batchInfo.depositAmount;

        SafeERC20.safeTransfer(
            depositCurrency,
            msg.sender,
            batchInfo.depositAmount
        );

        emit TokensReclaimed(msg.sender, batchInfo.depositAmount);
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Adds a new batch to the `batchMapping` and increases the
     *      count of `totalNumberOfBatches`
     */
    function addNewBatch(
        uint256 _totalSpots,
        uint256 _batchStartTimestamp,
        uint256 _depositAmount
    )
        public
        onlyOwner
    {
        require(
            _batchStartTimestamp >= currentTimestamp(),
            "WaitlistBatch: batch start time cannot be in the past"
        );

        require(
            _depositAmount > 0,
            "WaitlistBatch: deposit amount cannot be 0"
        );

        require(
            _totalSpots > 0,
            "WaitlistBatch: batch cannot have 0 spots"
        );

        Batch memory batch = Batch(
            _totalSpots,
            0,
            _batchStartTimestamp,
            _depositAmount,
            0
        );

        batchMapping[nextBatchNumber] = batch;
        nextBatchNumber = nextBatchNumber + 1;

        emit NewBatchAdded(
            _totalSpots,
            _batchStartTimestamp,
            _depositAmount,
            nextBatchNumber - 1
        );
    }

    /**
     * @dev Approves a batch. Users can then start reclaiming their deposit
     *      after the retrieval date delay.
     */
    function approveBatch(
        uint256 _batchNumber
    )
        external
        onlyOwner
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: the batch does not exist"
        );

        Batch storage batch = batchMapping[_batchNumber];

        require(
            batch.approvedAt == 0,
            "WaitlistBatch: the batch is already approved"
        );

        batch.approvedAt = currentTimestamp();

        emit BatchApproved(_batchNumber);
    }

    function changeBatchStartTimestamp(
        uint256 _batchNumber,
        uint256 _newStartTimestamp
    )
        public
        onlyOwner
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: batch does not exit"
        );

        require(
            _newStartTimestamp >= currentTimestamp(),
            "WaitlistBatch: batch start time cannot be in the past"
        );

        Batch storage batch = batchMapping[_batchNumber];
        batch.batchStartTimestamp = _newStartTimestamp;

        emit BatchTimestampChanged(
            _batchNumber,
            _newStartTimestamp
        );
    }

    function changeBatchTotalSpots(
        uint256 _batchNumber,
        uint256 _newSpots
    )
        public
        onlyOwner
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: the batch does not exist"
        );

        Batch storage batch = batchMapping[_batchNumber];

        require(
            currentTimestamp() < batch.batchStartTimestamp,
            "WaitlistBatch: the batch start date already passed"
        );

        require(
            batch.totalSpots < _newSpots,
            "WaitlistBatch: cannot change total spots to a smaller or equal number"
        );

        batch.totalSpots = _newSpots;

        emit BatchTotalSpotsUpdated(
            _batchNumber,
            _newSpots
        );
    }

    function transferTokens(
        address _tokenAddress,
        uint256 _amount,
        address _destination
    )
        public
        onlyOwner
    {
        SafeERC20.safeTransfer(
            IERC20(_tokenAddress),
            _destination,
            _amount
        );

        emit TokensTransferred(
            _tokenAddress,
            _amount,
            _destination
        );
    }

    function setModerator(
        address _user
    )
        public
        onlyOwner
    {
        moderator = _user;

        emit ModeratorSet(_user);
    }

    function setDepositLockupDuration(
        uint256 _duration
    )
        external
        onlyOwner
    {
        depositLockupDuration = _duration;

        emit DepositLockupDurationSet(depositLockupDuration);
    }

    /* ========== Moderator Functions ========== */

    function addToBlacklist(
        address _user
    )
        public
        onlyModerator
    {
        blacklist[_user] = true;

        emit AddedToBlacklist(_user);
    }

    function removeFromBlacklist(
        address _user
    )
        public
        onlyModerator
    {
        blacklist[_user] = false;

        emit RemovedFromBlacklist(_user);
    }

    /* ========== Dev Functions ========== */

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}
