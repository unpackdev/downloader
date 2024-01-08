// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC20.sol";

contract WaitlistBatch is Ownable {

    /* ========== Types ========== */

    struct Batch {
        uint256 totalSpots;
        uint256 filledSpots;
        uint256 batchStartTimestamp;
        uint256 depositAmount;
        bool claimable;
    }

    struct UserBatchInfo {
        bool hasParticipated;
        uint256 batchNumber;
        uint256 depositAmount;
    }

    /* ========== Variables ========== */

    address public moderator;

    IERC20 public depositCurrency;

    uint256 public nextBatchNumber;

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

    event BatchTimestampChanged(
        uint256 batchNumber,
        uint256 batchStartTimstamp
    );

    event BatchTotalSpotsUpdated(
        uint256 batchNumber,
        uint256 newTotalSpots
    );

    event BatchClaimsEnabled(
        uint256[] batchNumbers
    );

    event TokensReclaimed(
        address user,
        uint256 amount
    );

    event TokensReclaimedBlacklist(
        address user,
        uint256 amount
    );

    event TokensTransfered(
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

    /* ========== Modifiers ========== */

    modifier onlyModerator() {
        require(
            msg.sender == moderator,
            "WaitlistBatch: caller is not moderator"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor(address _depositCurrency) public {
        depositCurrency = IERC20(_depositCurrency);

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
            depositAmount: userDepositMapping[participatingBatch][_user]
        });
    }

    function getTotalNumberOfBatches()
        public
        view
        returns (uint256)
    {
        return nextBatchNumber - 1;
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
        UserBatchInfo memory batchInfo = getBatchInfoForUser(msg.sender);

        require(
            batchInfo.hasParticipated,
            "WaitlistBatch: user did not participate in a batch"
        );

        require(
            batchInfo.depositAmount > 0,
            "WaitlistBatch: there are no tokens to reclaim"
        );

        Batch memory batch = batchMapping[batchInfo.batchNumber];

        require(
            batch.claimable,
            "WaitlistBatch: the tokens are not yet claimable"
        );

        userDepositMapping[batchInfo.batchNumber][msg.sender] -= batchInfo.depositAmount;

        SafeERC20.safeTransfer(
            depositCurrency,
            msg.sender,
            batchInfo.depositAmount
        );

        if (blacklist[msg.sender] == true) {
            emit TokensReclaimedBlacklist(
                msg.sender,
                batchInfo.depositAmount
            );
        } else {
            emit TokensReclaimed(
                msg.sender,
                batchInfo.depositAmount
            );
        }
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
            false
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

    function enableClaims(
        uint256[] memory _batchNumbers
    )
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _batchNumbers.length; i++) {
            uint256 batchNumber = _batchNumbers[i];

            require(
                batchNumber > 0 && batchNumber < nextBatchNumber,
                "WaitlistBatch: the batch does not exist"
            );

            Batch storage batch = batchMapping[batchNumber];

            require(
                batch.claimable == false,
                "WaitlistBatch: batch has already claimable tokens"
            );

            batch.claimable = true;
        }

        emit BatchClaimsEnabled(_batchNumbers);
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

        emit TokensTransfered(
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
