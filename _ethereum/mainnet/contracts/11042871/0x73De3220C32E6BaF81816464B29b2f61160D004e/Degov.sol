pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Initializable.sol";

contract Degov is ERC20, Ownable, Initializable {
    using SafeMath for uint256;

    uint256 private constant DECIMALS = 18;

    address public degovUNIPool;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
    );

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator_,
        address indexed fromDelegate_,
        address indexed toDelegate_
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate_,
        uint256 previousBalance_,
        uint256 newBalance_
    );

    //The threshold of the total token supply required in order to pass a proposal
    uint256 public quorumThreshold = 20;

    //The threshold of the total token supply required in order to propose a proposal
    uint256 public proposalThreshold = 1;

    uint256 public constant TOTAL_SUPPLY = 25000 * 10**DECIMALS;

    event LogSetQuorumThresholdRatio(uint256 quorumThreshold_);
    event LogSetProposalThresholdRatio(uint256 proposalThreshold_);

    constructor() public ERC20("Degov", "DEGOV", uint8(DECIMALS)) {}

    /**
     * @notice Initialize the token with policy address and pool for the token distribution
     * @param degovUNIPool_ Address of the pool contract where newly minted degov tokens are sent.
     */
    function initialize(address degovUNIPool_) external initializer {
        degovUNIPool = degovUNIPool_;
        _mint(degovUNIPool, TOTAL_SUPPLY);
    }

    /**
     * @notice Sets the quorum threshold threshold for proposal voting. Used to calculate the % of the total supply required in order for a vote on a proposal to pass
     * @param quorumThreshold_ The new quorum threshold threshold.
     */
    function setQuorumThresholdRatio(uint256 quorumThreshold_)
        external
        onlyOwner
    {
        require(
            quorumThreshold_ > 0 && quorumThreshold <= 100,
            "Quorum threshold must be greater than zero and less/equal to 100"
        );
        require(
            quorumThreshold_ >= proposalThreshold,
            "Quorum threshold must be great or equal too proposal threshold"
        );
        quorumThreshold = quorumThreshold_;
        emit LogSetQuorumThresholdRatio(quorumThreshold_);
    }

    /**
     * @notice Sets the proposal threshold threshold for proposal voting. Used to calculate the % of the total supply required in order for a proposal to be initiated.
     * @param proposalThreshold_ The new proposal threshold threshold.
     */
    function setProposalThresholdRatio(uint256 proposalThreshold_)
        external
        onlyOwner
    {
        require(
            proposalThreshold_ > 0 && proposalThreshold_ <= 100,
            "Proposal threshold must be greater than zero and less/equal to 100"
        );
        require(
            proposalThreshold_ <= quorumThreshold,
            "Proposal threshold must be great or equal too quorum threshold"
        );
        proposalThreshold = proposalThreshold_;
        emit LogSetProposalThresholdRatio(proposalThreshold_);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        super.transfer(recipient, amount);
        _moveDelegates(delegates[msg.sender], delegates[recipient], amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        _moveDelegates(delegates[sender], delegates[recipient], amount);
        return true;
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Degov::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Degov::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "Degov::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "Degov::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "Degov::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
