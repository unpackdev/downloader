// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.21;

import "./MerkleProofUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * Contract responsible to manage the subscriptions and rewards of the dappnode smoothing pool
 */
contract DappnodeSmoothingPool is OwnableUpgradeable {
    /**
     * @notice Struct to store voted reports
     * @param slot Slot of the report
     * @param votes Current votes of this report
     */
    struct Report {
        uint64 slot;
        uint64 votes;
    }

    // This value is reserved as an initial voted report to mark an oracle address as active
    bytes32 public constant INITIAL_REPORT_HASH = bytes32(uint256(1));
    // 0x0000000000000000000000000000000000000000000000000000000000000001;

    // Subscription collateral
    uint256 public subscriptionCollateral;

    // Rewards merkle root, aggregate together all the validatorIDs with the same withdrawal address
    // Leaf:keccak256(abi.encodePacked(withdrawalAddress, availableBalance)
    bytes32 public rewardsRoot;

    // withdrawalAddress --> claimedBalance
    mapping(address => uint256) public claimedBalance;

    // Allow a withdrawal address to delegate his rewards to another address
    // withdrawalAddress --> rewardAddress
    mapping(address => address) public rewardRecipient;

    // The following parameters are used only to synch information on the oracle
    // And do not have any direct effect on the smart contract functions

    // Smoothing pool fee expressed in % with 2 decimals
    uint256 public poolFee;

    // Smoothing pool fee recipient
    address public poolFeeRecipient;

    // Indicates the deployment block number
    uint256 public deploymentBlockNumber;

    // The following parameters are relative to the oracle functions

    // Indicates the last consolidated slot
    uint64 public lastConsolidatedSlot;

    // Indicates how many slots must be between checkpoints
    uint64 public checkpointSlotSize;

    // Number of reports that must match to consolidate a new rewards root (N/M)
    uint64 public quorum;

    // Will be able to add/remove members of the oracle and update the quorum
    address public governance;

    // Will be able to accept the governance
    address public pendingGovernance;

    // Oracle member address --> current voted reportHash
    // reportHash: keccak256(abi.encodePacked(slot, rewardsRoot))
    mapping(address => bytes32) public addressToVotedReportHash;

    // reportHash --> Report(slot | votes)
    mapping(bytes32 => Report) public reportHashToReport;

    // This array is used only to easily get the current oracle members information
    address[] public oracleMembers;

    /**
     * @dev Emitted when the contract receives ether
     */
    event EtherReceived(address sender, uint256 donationAmount);

    /**
     * @dev Emitted when a new users subscribes
     */
    event SubscribeValidator(
        address sender,
        uint256 subscriptionCollateral,
        uint64 validatorID
    );

    /**
     * @dev Emitted when a user claim his rewards
     */
    event ClaimRewards(
        address withdrawalAddress,
        address rewardAddress,
        uint256 claimableBalance
    );

    /**
     * @dev Emitted when a validator address sets his rewards recipient
     */
    event SetRewardRecipient(address withdrawalAddress, address poolRecipient);

    /**
     * @dev Emitted when a validator unsubscribes
     */
    event UnsubscribeValidator(address sender, uint64 validatorID);

    /**
     * @dev Emitted when a the smoothing pool is initialized
     */
    event InitSmoothingPool(uint64 initialSmoothingPoolSlot);

    /**
     * @dev Emitted when the pool fee is updated
     */
    event UpdatePoolFee(uint256 newPoolFee);

    /**
     * @dev Emitted when the pool fee recipient is updated
     */
    event UpdatePoolFeeRecipient(address newPoolFeeRecipient);

    /**
     * @dev Emitted when the checkpoint slot size is updated
     */
    event UpdateCheckpointSlotSize(uint64 newCheckpointSlotSize);

    /**
     * @dev Emitted when the subscription collateral is update
     */
    event UpdateSubscriptionCollateral(uint256 newSubscriptionCollateral);

    /**
     * @dev Emitted when a report is submitted
     */
    event SubmitReport(
        uint256 slotNumber,
        bytes32 newRewardsRoot,
        address oracleMember
    );

    /**
     * @dev Emitted when a report is consolidated
     */
    event ReportConsolidated(uint256 slotNumber, bytes32 newRewardsRoot);

    /**
     * @dev Emitted when the quorum is updated
     */
    event UpdateQuorum(uint64 newQuorum);

    /**
     * @dev Emitted when a new oracle member is added
     */
    event AddOracleMember(address newOracleMember);

    /**
     * @dev Emitted when a new oracle member is removed
     */
    event RemoveOracleMember(address oracleMemberRemoved);

    /**
     * @dev Emitted when the governance starts the two-step transfer setting a new pending governance
     */
    event TransferGovernance(address newPendingGovernance);

    /**
     * @dev Emitted when the pending governance accepts the governance
     */
    event AcceptGovernance(address newGovernance);

    /**
     * @param _governance Governance address
     * @param _subscriptionCollateral Subscription collateral
     * @param _poolFee Pool Fee
     * @param _poolFeeRecipient Pool fee recipient
     * @param _checkpointSlotSize Checkpoint slot size
     */
    function initialize(
        address _governance,
        uint256 _subscriptionCollateral,
        uint256 _poolFee,
        address _poolFeeRecipient,
        uint64 _checkpointSlotSize,
        uint64 _quorum
    ) external initializer {
        // Initialize requires
        require(
            _poolFee <= 10000,
            "DappnodeSmoothingPool::initialize: Pool fee cannot be greater than 100%"
        );

        require(
            _quorum != 0,
            "DappnodeSmoothingPool::initialize: Quorum cannot be 0"
        );

        // Set initialize parameters
        governance = _governance;
        subscriptionCollateral = _subscriptionCollateral;

        checkpointSlotSize = _checkpointSlotSize;
        quorum = _quorum;

        poolFee = _poolFee;
        poolFeeRecipient = _poolFeeRecipient;
        deploymentBlockNumber = block.number;

        // Initialize OZ libs
        __Ownable_init();

        // Emit events
        emit UpdatePoolFee(_poolFee);
        emit UpdatePoolFeeRecipient(_poolFeeRecipient);
        emit UpdateCheckpointSlotSize(_checkpointSlotSize);
        emit UpdateQuorum(_quorum);
    }

    /**
     * @dev Governance modifier
     */
    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "DappnodeSmoothingPool::onlyGovernance: Only governance"
        );
        _;
    }

    /**
     * @notice Be able to receive ether donations and MEV rewards
     * Oracle will be able to differentiate between MEV rewards and donations and distribute rewards accordingly
     **/
    fallback() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    ////////////////////////
    // Validators functions
    ///////////////////////

    /**
     * @notice Subscribe multiple validators to the smoothing pool
     * The function won't check if there are duplicated validatorIDs
     * @param validatorIDArray Validator ID array
     */
    function subscribeValidators(
        uint64[] calldata validatorIDArray
    ) external payable {
        // Check collateral
        require(
            msg.value == subscriptionCollateral * validatorIDArray.length,
            "DappnodeSmoothingPool::subscribeValidator: msg.value does not equal subscription collateral"
        );

        // Emit a single event for every validator ID subscribed
        for (uint256 i = 0; i < validatorIDArray.length; ) {
            emit SubscribeValidator(
                msg.sender,
                subscriptionCollateral,
                validatorIDArray[i]
            );

            unchecked {
                i += 1;
            }
        }
    }

    /**
     * @notice Subscribe a validator ID to the smoothing pool
     * @param validatorID Validator ID
     */
    function subscribeValidator(uint64 validatorID) external payable {
        // Check collateral
        require(
            msg.value == subscriptionCollateral,
            "DappnodeSmoothingPool::subscribeValidator: msg.value does not equal subscription collateral"
        );

        emit SubscribeValidator(
            msg.sender,
            subscriptionCollateral,
            validatorID
        );
    }

    /**
     * @notice Claim available rewards
     * All the rewards that has the same withdrawal address and pool recipient are aggregated in the same leaf
     * @param withdrawalAddress Withdrawal address
     * @param accumulatedBalance Total available balance to claim
     * @param merkleProof Merkle proof against rewardsRoot
     */
    function claimRewards(
        address withdrawalAddress,
        uint256 accumulatedBalance,
        bytes32[] memory merkleProof
    ) external {
        // Verify the merkle proof
        bytes32 node = keccak256(
            abi.encodePacked(withdrawalAddress, accumulatedBalance)
        );

        require(
            MerkleProofUpgradeable.verify(merkleProof, rewardsRoot, node),
            "DappnodeSmoothingPool::claimRewards: Invalid merkle proof"
        );

        // Get claimable ether
        uint256 claimableBalance = accumulatedBalance -
            claimedBalance[withdrawalAddress];

        // Update claimed balance mapping
        claimedBalance[withdrawalAddress] = accumulatedBalance;

        // Load first the reward recipient for gas saving, to avoid load twice from storage
        address currentRewardRecipient = rewardRecipient[withdrawalAddress];
        address rewardAddress = currentRewardRecipient == address(0)
            ? withdrawalAddress
            : currentRewardRecipient;

        // Send ether
        (bool success, ) = rewardAddress.call{value: claimableBalance}(
            new bytes(0)
        );
        require(
            success,
            "DappnodeSmoothingPool::claimRewards: Eth transfer failed"
        );

        emit ClaimRewards(withdrawalAddress, rewardAddress, claimableBalance);
    }

    /**
     * @notice Allow a withdrawal address to set a reward recipient
     * @param rewardAddress Reward recipient
     */
    function setRewardRecipient(address rewardAddress) external {
        rewardRecipient[msg.sender] = rewardAddress;
        emit SetRewardRecipient(msg.sender, rewardAddress);
    }

    /**
     * @notice Unsubscribe a validator ID from smoothing pool
     * This call will only take effect in the oracle
     * if the msg.sender is the withdrawal address of that validator
     * @param validatorID Validator ID
     */
    function unsubscribeValidator(uint64 validatorID) external {
        emit UnsubscribeValidator(msg.sender, validatorID);
    }

    ////////////////////
    // Oracle functions
    ///////////////////

    /**
     * @notice Submit a report for a new rewards root
     * If the quorum is reached, consolidate the rewards root
     * @param slotNumber Slot number
     * @param proposedRewardsRoot Proposed rewards root
     */
    function submitReport(
        uint64 slotNumber,
        bytes32 proposedRewardsRoot
    ) external {
        // Check that the report contains the correct slot number
        uint64 cacheLastConsolidatedSlot = lastConsolidatedSlot;

        require(
            cacheLastConsolidatedSlot != 0,
            "DappnodeSmoothingPool::submitReport: Smoothing pool not initialized"
        );

        require(
            slotNumber == cacheLastConsolidatedSlot + checkpointSlotSize,
            "DappnodeSmoothingPool::submitReport: Slot number invalid"
        );

        // Check the last voted report
        bytes32 lastVotedReportHash = addressToVotedReportHash[msg.sender];

        // Check if it's a valid oracle member
        require(
            lastVotedReportHash != bytes32(0),
            "DappnodeSmoothingPool::submitReport: Not a oracle member"
        );

        // If it's not the initial report hash, check last report voted
        if (lastVotedReportHash != INITIAL_REPORT_HASH) {
            Report storage lastVotedReport = reportHashToReport[
                lastVotedReportHash
            ];

            // Subtract a vote on the last voted report
            // That report could have 0 votes because:
            // - The report was already consolidated
            // - Were subtracted all the votes from that report
            if (lastVotedReport.votes > 0) {
                unchecked {
                    lastVotedReport.votes--;
                }
            }
        }

        // Get the current report
        bytes32 currentReportHash = getReportHash(
            slotNumber,
            proposedRewardsRoot
        );
        Report memory currentVotedReport = reportHashToReport[
            currentReportHash
        ];

        // Check if it's a new report
        if (currentVotedReport.slot == 0) {
            // It's a new report, set slot and votes
            currentVotedReport.slot = slotNumber;
            currentVotedReport.votes = 1;
        } else {
            // It's an existing report, add a new vote
            currentVotedReport.votes++;
        }

        // Emit Submit report before check the quorum
        emit SubmitReport(slotNumber, proposedRewardsRoot, msg.sender);

        // Check if it reaches the quorum
        if (currentVotedReport.votes >= quorum) {
            delete reportHashToReport[currentReportHash];

            // Consolidate report
            lastConsolidatedSlot = slotNumber;
            rewardsRoot = proposedRewardsRoot;
            emit ReportConsolidated(slotNumber, proposedRewardsRoot);
        } else {
            // Store submitted report with a new added vote
            reportHashToReport[currentReportHash] = currentVotedReport;

            // Store voted report hash
            addressToVotedReportHash[msg.sender] = currentReportHash;
        }
    }

    ////////////////////////
    // Governance functions
    ////////////////////////

    /**
     * @notice Add an oracle member
     * Only the governance can call this function
     * @param newOracleMember Address of the new oracle member
     */
    function addOracleMember(address newOracleMember) external onlyGovernance {
        require(
            addressToVotedReportHash[newOracleMember] == bytes32(0),
            "DappnodeSmoothingPool::addOracleMember: Already oracle member"
        );

        // Add oracle member
        addressToVotedReportHash[newOracleMember] = INITIAL_REPORT_HASH;

        // Add oracle member to the oracleMembers array
        oracleMembers.push(newOracleMember);

        emit AddOracleMember(newOracleMember);
    }

    /**
     * @notice Remove an oracle member
     * Only the governance can call this function
     * @param oracleMemberAddress Address of the removed oracle member
     * @param oracleMemberIndex Index of the removed oracle member
     */
    function removeOracleMember(
        address oracleMemberAddress,
        uint256 oracleMemberIndex
    ) external onlyGovernance {
        bytes32 lastVotedReportHash = addressToVotedReportHash[
            oracleMemberAddress
        ];

        require(
            lastVotedReportHash != bytes32(0),
            "DappnodeSmoothingPool::removeOracleMember: Was not an oracle member"
        );

        require(
            oracleMembers[oracleMemberIndex] == oracleMemberAddress,
            "DappnodeSmoothingPool::removeOracleMember: Oracle member index does not match"
        );

        // If it's not the initial report hash, check last report voted
        if (lastVotedReportHash != INITIAL_REPORT_HASH) {
            Report storage lastVotedReport = reportHashToReport[
                lastVotedReportHash
            ];

            // Subtract a vote of this oracle member
            // If the votes == 0, that report was already consolidated
            if (lastVotedReport.votes > 0) {
                unchecked {
                    lastVotedReport.votes--;
                }
            }
        }

        // Remove oracle member
        addressToVotedReportHash[oracleMemberAddress] = bytes32(0);

        // Remove the oracle member from the oracleMembers array
        oracleMembers[oracleMemberIndex] = oracleMembers[
            oracleMembers.length - 1
        ];
        oracleMembers.pop();

        emit RemoveOracleMember(oracleMemberAddress);
    }

    /**
     * @notice Update the quorum value
     * Only the governance can call this function
     * @param newQuorum new quorum
     */
    function updateQuorum(uint64 newQuorum) external onlyGovernance {
        require(
            newQuorum != 0,
            "DappnodeSmoothingPool::updateQuorum: Quorum cannot be 0"
        );
        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    /**
     * @notice Starts the governance transfer
     * This is a two step process, the pending governance must accepted to finalize the process
     * Only the governance can call this function
     * @param newPendingGovernance new governance address
     */
    function transferGovernance(
        address newPendingGovernance
    ) external onlyGovernance {
        pendingGovernance = newPendingGovernance;
        emit TransferGovernance(newPendingGovernance);
    }

    /**
     * @notice Allow the current pending governance to accept the governance
     */
    function acceptGovernance() external {
        require(
            pendingGovernance == msg.sender,
            "DappnodeSmoothingPool::acceptGovernance: Only pending governance"
        );

        governance = pendingGovernance;
        emit AcceptGovernance(pendingGovernance);
    }

    ///////////////////
    // Owner functions
    ///////////////////

    /**
     * @notice Initialize smoothing pool
     * Only the owner can call this function
     * @param initialSmoothingPoolSlot Initial smoothing pool slot
     */
    function initSmoothingPool(
        uint64 initialSmoothingPoolSlot
    ) external onlyOwner {
        // Smoothing pool must not have been initialized
        require(
            lastConsolidatedSlot == 0,
            "DappnodeSmoothingPool::initSmoothingPool: Smoothing pool already initialized"
        );

        // Cannot initialize smoothing pool to slot 0
        require(
            initialSmoothingPoolSlot != 0,
            "DappnodeSmoothingPool::initSmoothingPool: Cannot initialize to slot 0"
        );

        lastConsolidatedSlot = initialSmoothingPoolSlot;
        emit InitSmoothingPool(initialSmoothingPoolSlot);
    }

    /**
     * @notice Update pool fee
     * Only the owner can call this function
     * @param newPoolFee new pool fee
     */
    function updatePoolFee(uint256 newPoolFee) external onlyOwner {
        require(
            newPoolFee <= 10000,
            "DappnodeSmoothingPool::updatePoolFee: Pool fee cannot be greater than 100%"
        );
        poolFee = newPoolFee;
        emit UpdatePoolFee(newPoolFee);
    }

    /**
     * @notice Update the pool fee recipient
     * Only the owner can call this function
     * @param newPoolFeeRecipient new pool fee recipient
     */
    function updatePoolFeeRecipient(
        address newPoolFeeRecipient
    ) external onlyOwner {
        poolFeeRecipient = newPoolFeeRecipient;
        emit UpdatePoolFeeRecipient(newPoolFeeRecipient);
    }

    /**
     * @notice Update the checkpoint slot size
     * Only the owner can call this function
     * @param newCheckpointSlotSize new checkpoint slot size
     */
    function updateCheckpointSlotSize(
        uint64 newCheckpointSlotSize
    ) external onlyOwner {
        checkpointSlotSize = newCheckpointSlotSize;
        emit UpdateCheckpointSlotSize(newCheckpointSlotSize);
    }

    /**
     * @notice Update the collateral needed to subscribe a validator
     * Only the owner can call this function
     * @param newSubscriptionCollateral new subscription collateral
     */
    function updateCollateral(
        uint256 newSubscriptionCollateral
    ) external onlyOwner {
        subscriptionCollateral = newSubscriptionCollateral;
        emit UpdateSubscriptionCollateral(newSubscriptionCollateral);
    }

    ///////////////////
    // View functions
    ///////////////////

    /**
     * @notice Return oracle member index
     * @param oracleMember oracle member address
     */
    function getOracleMemberIndex(
        address oracleMember
    ) external view returns (uint256) {
        for (uint256 i = 0; i < oracleMembers.length; ++i) {
            if (oracleMembers[i] == oracleMember) {
                return i;
            }
        }

        // In case the oracle member does not exist, revert
        revert(
            "DappnodeSmoothingPool::getOracleMemberIndex: Oracle member not found"
        );
    }

    /**
     * @notice Return all the oracle members
     */
    function getAllOracleMembers() external view returns (address[] memory) {
        return oracleMembers;
    }

    /**
     * @notice Return oracle members count
     */
    function getOracleMembersCount() external view returns (uint256) {
        return oracleMembers.length;
    }

    /**
     * @notice Get the report hash given the rewards root and slot
     * @param _slot Slot
     * @param _rewardsRoot Rewards root
     */
    function getReportHash(
        uint64 _slot,
        bytes32 _rewardsRoot
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_slot, _rewardsRoot));
    }
}
