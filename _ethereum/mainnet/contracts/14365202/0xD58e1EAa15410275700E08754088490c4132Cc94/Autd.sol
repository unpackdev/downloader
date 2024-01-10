// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;



import "./Address.sol";
import "./ISutd.sol";
import "./IAutd.sol";
import "./ERC20.sol";
import "./UnitedAccessControl.sol";



contract Autd is IAutd, ERC20, UnitedAccessControl {

    /* ========== DEPENDENCIES ========== */

    using Address for address;
    using SafeMath for uint256;

    /* ========== MODIFIERS ========== */

    modifier onlyStaking() {
        require(msg.sender == staking, "Only staking");
        _;
    }

    /* ========== EVENTS ========== */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ========== DATA STRUCTURES ========== */

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /* ========== STATE VARIABLES ========== */

    ISutd public immutable sUTD;
    address public immutable initializer; // minter
    address public staking; // minter

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    mapping(address => uint256) public numCheckpoints;
    mapping(address => address) public delegates;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _initializer, address _sUTD, address authority, uint256 _pledgeLockupDuration)
        ERC20("Allies UTD", "aUTD", 18)
        UnitedAccessControl(IUnitedAuthority(authority))
    {
        require(_initializer != address(0), "Zero address: Initializer");
        initializer = _initializer;
        require(_sUTD != address(0), "Zero address: sUTD");
        sUTD = ISutd(_sUTD);

        pledgeLockupDuration = _pledgeLockupDuration;
        emit SetPledgeLockupDuration(_pledgeLockupDuration);
    }

    function setStaking(address _staking) external {
        require(msg.sender == initializer, "not initializer");
        require(_staking != address(0), "Zero address: Staking");
        staking = _staking;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
        @notice mint aUTD
        @param _to address
        @param _amount uint
     */
    function mint(address _to, uint256 _amount) external override onlyStaking {
        _mint(_to, _amount);
    }

    /**
        @notice burn aUTD
        @param _from address
        @param _amount uint
     */
    function burn(address _from, uint256 _amount) external override onlyStaking {
        _burn(_from, _amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice pull index from sUTD token
     */
    function index() public view override returns (uint256) {
        return sUTD.index();
    }

    /**
        @notice converts aUTD amount to UTD
        @param _amount uint
        @return uint
     */
    function balanceFrom(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(index()).div(10**decimals());
    }

    /**
        @notice converts UTD amount to aUTD
        @param _amount uint
        @return uint
     */
    function balanceTo(uint256 _amount) public view override returns (uint256) {
        return _amount.mul(10**decimals()).div(index());
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "aUTD::getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
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

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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

    /* ========== INTERNAL FUNCTIONS ========== */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
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
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(block.number, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(IERC20, ERC20) returns (bool) {
        // Staking contract has permissions to transfer all sUTD
        // Check if it is other senders
        if (msg.sender == staking) {
            _transfer(sender, recipient, amount);
            return true;
        } else {
            _transfer(sender, recipient, amount);
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
    }

    /**
        @notice Ensure delegation moves when token is transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _moveDelegates(delegates[from], delegates[to], amount);
    }

    function _afterTokenTransfer(
        address from,
        address,
        uint256
    ) internal view override {
        if (from != address(0)) {
            require (pledgeAccountData[from].amount <= _balances[from], "balance less than pledged");
        }
    }

    // # Pledging
    // ----------

    struct AutdPledgeAccountData {
        uint96 amount;
        uint48 lockupExpiry;
    }
    uint256 public pledgeLockupDuration;
    mapping(address => AutdPledgeAccountData) public pledgeAccountData;

    event SetPledgeLockupDuration(uint256 newPledgeLockupDuration);
    event Pledge(address account, uint256 amount);
    event Claim(address account, uint256 amount);

    function setPledgeLockupDuration(uint256 newPledgeLockupDuration) external onlyPolicy {
        pledgeLockupDuration = newPledgeLockupDuration;
        emit SetPledgeLockupDuration(newPledgeLockupDuration);
    }

    function pledge(uint256 amount) external {
        emit Pledge(msg.sender, amount);
        pledgeAccountData[msg.sender].amount += uint96(amount);
        require(pledgeAccountData[msg.sender].amount <= balanceOf(msg.sender), "autd balance too low");
        pledgeAccountData[msg.sender].lockupExpiry = uint48(block.timestamp + pledgeLockupDuration);
    }

    function claim(uint256 amount) external {
        require(block.timestamp >= pledgeAccountData[msg.sender].lockupExpiry, "autd is locked up");
        emit Claim(msg.sender, amount);
        pledgeAccountData[msg.sender].amount -= uint96(amount);
    }
}