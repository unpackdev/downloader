// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;
import "./MerkleProof.sol";

import "./Adminable.sol";
import "./SafeMath.sol";
import "./SapphireTypes.sol";
import "./ISapphireCreditScore.sol";

contract SapphireCreditScore is ISapphireCreditScore, Adminable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;

    /* ========== Events ========== */

    event MerkleRootUpdated(
        address indexed updater,
        bytes32 merkleRoot,
        uint256 updatedAt
    );

    event CreditScoreUpdated(
        address indexed account,
        uint256 score,
        uint256 lastUpdated
    );

    event PauseStatusUpdated(bool value);

    event DelayDurationUpdated(
        address indexed account,
        uint256 value
    );

    event PauseOperatorUpdated(
        address pauseOperator
    );

    event MerkleRootUpdaterUpdated(
        address merkleRootUpdater
    );

    event DocumentIdUpdated(
        string newDocumentId
    );

    /* ========== Variables ========== */

    bool private _initialized;

    uint16 public maxScore;

    bool public isPaused;

    uint256 public lastMerkleRootUpdate;

    uint256 public merkleRootDelayDuration;

    bytes32 public currentMerkleRoot;

    bytes32 public upcomingMerkleRoot;

    address public merkleRootUpdater;

    address public pauseOperator;

    // The document ID of the IPFS document containing the current Merkle Tree
    string public documentId;

    mapping(address => SapphireTypes.CreditScore) public userScores;

    uint256 public currentEpoch;

    /* ========== Modifiers ========== */

    modifier onlyMerkleRootUpdater() {
        require(
            merkleRootUpdater == msg.sender,
            "SapphireCreditScore: caller is not authorized to update merkle root"
        );
        _;
    }

    modifier onlyWhenActive() {
        require(
            !isPaused,
            "SapphireCreditScore: contract is not active"
        );
        _;
    }

    /* ========== Init ========== */

    function init(
        bytes32 _merkleRoot,
        address _merkleRootUpdater,
        address _pauseOperator,
        uint16 _maxScore
    )
        public
        onlyAdmin
    {
        require(
            !_initialized,
            "SapphireCreditScore: init already called"
        );

        require(
            _maxScore > 0,
            "SapphireCreditScore: max score cannot be zero"
        );

        currentMerkleRoot = _merkleRoot;
        upcomingMerkleRoot = _merkleRoot;
        merkleRootUpdater = _merkleRootUpdater;
        pauseOperator = _pauseOperator;
        lastMerkleRootUpdate = 0;
        isPaused = true;
        merkleRootDelayDuration = 86400; // 24 * 60 * 60 sec
        maxScore = _maxScore;

        _initialized = true;
    }

    /* ========== View Functions ========== */

    /**
     * @dev Returns current block's timestamp
     *
     * @notice This function is introduced in order to properly test time delays in this contract
     */
    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Return last verified user score
     */
    function getLastScore(
        address _user
    )
        external
        view
        returns (uint256, uint16, uint256)
    {
        SapphireTypes.CreditScore memory userScore = userScores[_user];
        return (userScore.score, maxScore, userScore.lastUpdated);
    }

    /* ========== Mutative Functions ========== */

    /**
     * @dev Update upcoming merkle root
     *
     * @notice Can be called by:
     *      - the admin:
     *          1. Check if contract is paused
     *          2. Replace upcoming merkle root
     *      - merkle root updater:
     *          1. Check if contract is active
     *          2. Replace current merkle root with upcoming merkle root
     *          3. Update upcoming one with passed Merkle root.
     *          4. Update the last merkle root update with the current timestamp
     *          5. Increment the `currentEpoch`
     *
     * @param _newRoot New upcoming merkle root
     */
    function updateMerkleRoot(
        bytes32 _newRoot
    )
        external
    {
        require(
            _newRoot != 0x0000000000000000000000000000000000000000000000000000000000000000,
            "SapphireCreditScore: root is empty"
        );

        if (msg.sender == getAdmin()) {
            updateMerkleRootAsAdmin(_newRoot);
        } else {
            updateMerkleRootAsUpdater(_newRoot);
        }
        emit MerkleRootUpdated(msg.sender, _newRoot, currentTimestamp());
    }

    /**
     * @dev Request for verifying user's credit score
     *
     * @notice If the credit score is verified, this function updates the
     *         user's credit score with the verified one and current timestamp
     *
     * @param _proof Data required to verify if score is correct for current merkle root
     */
    function verifyAndUpdate(
        SapphireTypes.ScoreProof memory _proof
    )
        public
        returns (uint256, uint16)
    {
        require(
            _proof.account != address(0),
            "SapphireCreditScore: account cannot be address 0"
        );

        bytes32 node = keccak256(abi.encodePacked(_proof.account, _proof.score));

        require(
            MerkleProof.verify(_proof.merkleProof, currentMerkleRoot, node),
            "SapphireCreditScore: invalid proof"
        );

        userScores[_proof.account] = SapphireTypes.CreditScore({
            score: _proof.score,
            lastUpdated: currentTimestamp()
        });
        emit CreditScoreUpdated(_proof.account, _proof.score, currentTimestamp());

        return (_proof.score, maxScore);
    }

     /* ========== Private Functions ========== */

    /**
     * @dev Merkle root updating strategy for merkle root updater
    **/
    function updateMerkleRootAsUpdater(
        bytes32 _newRoot
    )
        private
        onlyMerkleRootUpdater
        onlyWhenActive
    {
        require(
            currentTimestamp() >= merkleRootDelayDuration.add(lastMerkleRootUpdate),
            "SapphireCreditScore: cannot update merkle root before delay period"
        );

        currentMerkleRoot = upcomingMerkleRoot;
        upcomingMerkleRoot = _newRoot;
        currentEpoch++;
        lastMerkleRootUpdate = currentTimestamp();
    }

    /**
     * @dev Merkle root updating strategy for the admin
    **/
    function updateMerkleRootAsAdmin(
        bytes32 _newRoot
    )
        private
        onlyAdmin
    {
        require(
            isPaused,
            "SapphireCreditScore: only admin can update merkle root if paused"
        );

        upcomingMerkleRoot = _newRoot;
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Update merkle root delay duration
    */
    function setMerkleRootDelay(
        uint256 _delay
    )
        external
        onlyAdmin
    {
        require(
            _delay > 0,
            "SapphireCreditScore: the delay must be greater than 0"
        );

        require(
            _delay != merkleRootDelayDuration,
            "SapphireCreditScore: the same delay is already set"
        );

        merkleRootDelayDuration = _delay;
        emit DelayDurationUpdated(msg.sender, _delay);
    }

    /**
     * @dev Pause or unpause contract, which cause the merkle root updater
     *      to not be able to update the merkle root
     */
    function setPause(
        bool _value
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "SapphireCreditScore: caller is not the pause operator"
        );

        require(
            _value != isPaused,
            "SapphireCreditScore: cannot set the same pause value"
        );

        isPaused = _value;
        emit PauseStatusUpdated(_value);
    }

    /**
     * @dev Sets the merkle root updater
    */
    function setMerkleRootUpdater(
        address _merkleRootUpdater
    )
        external
        onlyAdmin
    {
        require(
            _merkleRootUpdater != merkleRootUpdater,
            "SapphireCreditScore: cannot set the same merkle root updater"
        );

        merkleRootUpdater = _merkleRootUpdater;
        emit MerkleRootUpdaterUpdated(merkleRootUpdater);
    }

    /**
     * @dev Sets the pause operator
    */
    function setPauseOperator(
        address _pauseOperator
    )
        external
        onlyAdmin
    {
        require(
            _pauseOperator != pauseOperator,
            "SapphireCreditScore: cannot set the same pause operator"
        );

        pauseOperator = _pauseOperator;
        emit PauseOperatorUpdated(pauseOperator);
    }

    /**
     * @dev Sets the document ID of the IPFS document containing the current Merkle Tree.
     */
    function setDocumentId(
        string memory _documentId
    )
        public
        onlyAdmin
    {
        documentId = _documentId;

        emit DocumentIdUpdated(documentId);
    }
}
