pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 */
contract GrailToken is
    Context,
    AccessControlEnumerable,
    ERC20Snapshot,
    ERC20Burnable
{
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTER_ROLE");

    // A record of each accounts delegate
    mapping(address => address) public delegates;
    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public numCheckpoints;

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    constructor() ERC20("GRAIL Governance Token", "GRAIL") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(SNAPSHOTTER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
        _moveDelegates(from, to, amount);
    }

    function snapshot() public returns (uint256) {
        require(
            hasRole(SNAPSHOTTER_ROLE, _msgSender()),
            "Must have snapshoter role to mint"
        );
        return _snapshot();
    }

    // GOVERNANCE PART
    /**
     * notice Delegate votes from `msg.sender` to `delegatee`
     * param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];

        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    //  This function is made to delegate the votes to some other address
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        if (currentDelegate == address(0)) {
            currentDelegate = msg.sender;
        }
        // Checks how many votes does the delegator have currently available?
        // The amount of the votes depends on the balance of the tokens you have.
        uint256 delegatorBalance = balanceOf(delegator);
        // Set the new address the delegate who will making the votes.
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        // The balance balance of the one who is delegating are moved to the balance of the delegatee.
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            //   WE ARE SETTING THE CHECKPOINT WHERE WE SPECIFY THE BLOCK number
            //   THE GOAL IS TO NOT LET PEOPLE VOTE WHEN THEIR BLOCK NUMBER IS AFTER WHEN THE VOTE BLIOCK STARTED.
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                block.number,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _moveDelegates(
        address from,
        address to,
        uint256 amount
    ) public {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint256 fromNum = numCheckpoints[from];
                uint256 fromOld =
                    fromNum > 0 ? checkpoints[from][fromNum - 1].votes : 0;
                uint256 fromNew = fromOld.sub(amount);
                _writeCheckpoint(from, fromNum, fromOld, fromNew);
            }
            if (to != address(0)) {
                uint256 toNum = numCheckpoints[to];
                uint256 toOld =
                    toNum > 0 ? checkpoints[to][toNum - 1].votes : 0;
                uint256 toNew = toOld.add(amount);
                _writeCheckpoint(to, toNum, toOld, toNew);
            }
        }
    }

    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "Grail::getPriorVotes: not yet determined"
        );

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
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
}
