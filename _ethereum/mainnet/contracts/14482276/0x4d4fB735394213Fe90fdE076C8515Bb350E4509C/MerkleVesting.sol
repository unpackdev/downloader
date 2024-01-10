// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Vesting
 * @author gotbit
 */

// base settings
//10% at TGE, 2 months cliff, and 7.5% monthly for 12 months

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

contract MerkleVesting is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public token;

    // CONSTANTS
    uint256 public MONTH = 30 days;
    uint256 public WEEK = 7 days;

    // MERKLE TREE ROOT
    bytes32 public root;

    // STORAGE
    uint256 public startTimestamp;

    EnumerableSet.AddressSet private _users;

    mapping(address => uint256) claimed;

    mapping(string => uint256) public _roundToId;
    mapping(uint256 => string) public _idToRound;
    // index zero is empty Setup!!!
    Setup[] public _setups;

    struct Factor {
        uint256 numerator;
        uint256 denominator;
    }

    // PERIODS
    // `LOCK PERIOD` -> ON `UNLOCK PERIOD`  -> `CLIFF` -> AFTER CLIFF LINEAR `UNLOCK`
    struct Setup {
        // LOCK PERIOD
        uint256 lockPeriod;
        // AFTER LOCK
        Factor amountOnUnlock;
        // CLIFF PERIOD
        uint256 cliffPeriod;
        // AFTER CLIFF LINEAR `UNLOCK`
        uint256 linearUnit;
        Factor amountPerUnit;
    }

    struct Allocations {
        string roundName;
        uint256 allocation;
    }

    //EVENTS
    event ChangeSetup(uint256 indexed timestamp, address indexed user, string round);
    event WithdrawToken(
        uint256 indexed timestamp,
        address indexed user,
        address token,
        uint256 amount
    );
    event ChangeToken(uint256 indexed timestamp, address indexed user, address newToken);
    event Start(uint256 indexed timestamp, address indexed user);
    event Claim(uint256 indexed timestamp, address indexed user, uint256 amount);
    event ChangeRoot(uint256 indexed timestamp, bytes32 newRoot, uint256 blockNumber);

    /// @dev reverts if called before start.
    modifier isStarted() {
        require(startTimestamp != 0, 'Vesting have not started');
        _;
    }

    constructor(address token_, address owner_) {
        token = IERC20(token_);

        Setup memory setup;
        _setups.push(setup);
        setSetup(
            'private',
            Setup({
                lockPeriod: 0,
                amountOnUnlock: Factor(10, 100),
                cliffPeriod: 0,
                linearUnit: 2 * WEEK,
                amountPerUnit: Factor(375, 10000)
            })
        );
        setSetup(
            'ambassadors',
            Setup({
                lockPeriod: MONTH,
                amountOnUnlock: Factor(0, 100),
                cliffPeriod: 0,
                linearUnit: MONTH,
                amountPerUnit: Factor(277, 10000)
            })
        );
        setSetup(
            'team',
            Setup({
                lockPeriod: MONTH,
                amountOnUnlock: Factor(0, 100),
                cliffPeriod: 0,
                linearUnit: 2 * WEEK,
                amountPerUnit: Factor(104, 10000)
            })
        );
        setSetup(
            'opsdev',
            Setup({
                lockPeriod: MONTH,
                amountOnUnlock: Factor(0, 100),
                cliffPeriod: 0,
                linearUnit: 2 * WEEK,
                amountPerUnit: Factor(104, 10000)
            })
        );
        setSetup(
            'advisory',
            Setup({
                lockPeriod: MONTH,
                amountOnUnlock: Factor(0, 100),
                cliffPeriod: 0,
                linearUnit: 2 * WEEK,
                amountPerUnit: Factor(104, 10000)
            })
        );

        transferOwnership(owner_);
    }

    // USER

    /// @dev claims for user all reward tokens
    function claim(bytes32[] memory proof_, Allocations[] memory allocations_)
        external
        isStarted
    {
        bytes32 _leaf = keccak256(
            abi.encode(allocations_, keccak256(abi.encode(msg.sender)))
        );

        require(verify(proof_, root, _leaf), 'claim: verify in merkle tree failed');
        uint256 unclaimed_ = unclaimed(msg.sender, allocations_);
        require(unclaimed_ > 0, 'Nothing to claim');
        require(
            token.balanceOf(address(this)) >= unclaimed_,
            'Contract doesnt have enough tokens'
        );

        claimed[msg.sender] += unclaimed_;
        token.safeTransfer(msg.sender, unclaimed_);

        emit Claim(block.timestamp, msg.sender, unclaimed_);
    }

    /// @dev returns amount to claim for user
    /// @param user address of user for calculating claim amount
    /// @param allocations_ array of all rounds and allocations of user
    /// @return unclaimed amount of unclaimed tokens
    function unclaimed(address user, Allocations[] memory allocations_)
        public
        view
        isStarted
        returns (uint256)
    {
        uint256 total = 0;
        uint256 allocationsLength = allocations_.length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            total += unclaimedInRound(user, allocations_[i]);
        }

        return total - claimed[user];
    }

    /// @dev returns amount to claim for user in specific round (if denominator of `amountOnUnlock` == 0 than returns 0)
    /// @param user address of user for calculating claim amount
    /// @param roundAllocation round name and allocation of user for this round
    /// @return unclaimed amount of unclaimed tokens in round
    function unclaimedInRound(address user, Allocations memory roundAllocation)
        public
        view
        isStarted
        returns (uint256)
    {
        uint256 roundId = _roundToId[roundAllocation.roundName];
        Setup memory setup = _setups[roundId];
        uint256 allocation = roundAllocation.allocation;
        if (setup.amountOnUnlock.denominator == 0) return 0;

        uint256 total = 0;
        uint256 timepassed = block.timestamp - startTimestamp;

        if (timepassed < setup.lockPeriod) return total;

        // on unlock
        uint256 amountOnUnlock = (allocation * setup.amountOnUnlock.numerator) /
            (setup.amountOnUnlock.denominator);
        total += amountOnUnlock;

        if ((timepassed - setup.lockPeriod) < setup.cliffPeriod) return total;

        // after cliff
        uint256 vestingTime = timepassed - setup.lockPeriod - setup.cliffPeriod;
        uint256 units = vestingTime / setup.linearUnit;
        uint256 vestingAmount = (allocation * units * setup.amountPerUnit.numerator) /
            (setup.amountPerUnit.denominator);

        total += vestingAmount;
        return total > allocation ? allocation : total;
    }

    // ADMINS

    /// @dev starts claiming
    function start() external onlyOwner {
        require(startTimestamp == 0, 'Vesting has been already started');
        startTimestamp = block.timestamp;
        emit Start(block.timestamp, msg.sender);
    }

    /// @dev sets `setup` for round with `name` (ONLY OWNER)
    /// @param round name of round
    /// @param setup setup for round
    function setSetup(string memory round, Setup memory setup) public onlyOwner {
        // _setups[name] = setup;
        if (_roundToId[round] == 0) {
            _roundToId[round] = _setups.length;
            _idToRound[_setups.length] = round;
            _setups.push(setup);
        } else {
            _setups[_roundToId[round]] = setup;
        }
        // setups tracker
        // for claimed
        emit ChangeSetup(block.timestamp, msg.sender, round);
    }

    /// @dev sets `setups` for each round with name from `names` (ONLY OWNER)
    /// @param rounds names of rounds
    /// @param setups setups for rounds
    function setSetups(string[] memory rounds, Setup[] memory setups) external onlyOwner {
        require(rounds.length == setups.length, 'Size of names and setup must be same');
        uint256 length = rounds.length;
        for (uint256 i = 0; i < length; i++) {
            setSetup(rounds[i], setups[i]);
        }
    }

    /// @dev setting merkle tree root, means setting wallets from backend
    /// @param _root new merkle tree root
    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
        emit ChangeRoot(block.timestamp, _root, block.number);
    }

    /// @dev verifies allocation for claim
    /// @param proof array of bytes for merkle tree verifing
    /// @param _root merkle tree's root
    /// @param leaf keccak256 of user address
    function verify(
        bytes32[] memory proof,
        bytes32 _root,
        bytes32 leaf
    ) public pure returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            hash = hash < proofElement
                ? keccak256(abi.encode(hash, proofElement))
                : keccak256(abi.encode(proofElement, hash));
        }
        return hash == _root;
    }

    /// @dev withdraws specific `token_` from contract (if amount greater than balance withdraws all balance) (ONLY OWNER)
    /// @param token_ address of token
    /// @param amount uint id which be minted
    function withdraw(IERC20 token_, uint256 amount) external onlyOwner {
        if (token_.balanceOf(address(this)) < amount)
            amount = token_.balanceOf(address(this));
        token_.safeTransfer(msg.sender, amount);

        emit WithdrawToken(block.timestamp, msg.sender, address(token_), amount);
    }

    /// @dev change token address on the contract (ONLY OWNER)
    /// @param token_ new token address
    function setToken(address token_) external onlyOwner {
        require(token_ != address(0), 'Token cant be zero address');
        require(token_ != address(token), 'New token cant be same');

        token = IERC20(token_);
        emit ChangeToken(block.timestamp, msg.sender, token_);
    }

    // VIEW

    struct Info {
        address user;
        uint256 allocation;
        uint256 unclaimed;
        uint256 claimed;
    }

    function userInfo(address user, Allocations[] memory allocations_)
        external
        view
        returns (Info memory)
    {
        Info memory info;
        info.user = user;

        uint256 allocationsLength = allocations_.length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            info.allocation += allocations_[i].allocation;
        }

        info.unclaimed = unclaimed(user, allocations_);
        info.claimed = claimed[user];

        return info;
    }
}
