// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

import "./IMinter.sol";
import "./IVoter.sol";
import "./Status.sol";
import "./ISolidlyV3PoolMinimal.sol";

error AlreadyClaimed();
error BufferPeriod();
error InvalidIncentiveAmount();
error InvalidIncentiveDistributionPeriod();
error PoolNotWhitelisted();
error InvalidProof();
error NotClaimsPauser();
error NotOwner();
error NotOperator();
error NotVoter();
error NotRootSetter();

struct Root {
    bytes32 value;
    uint256 lastUpdatedAt;
}

struct Claim {
    uint256 amount;
    uint256 timestamp;
}

enum RewardType {
    STORED,
    EARNED
}

enum StoredRewardType {
    LP_SOLID_EMISSIONS,
    LP_TOKEN_INCENTIVE,
    POOL_FEES,
    VOTE_INCENTIVE
}

struct StoredReward {
    StoredRewardType _type;
    address pool;
    address token;
}

enum EarnedRewardType {
    LP_POOL_FEES,
    LP_SOLID_EMISSIONS,
    LP_TOKEN_INCENTIVE,
    PROTOCOL_POOL_FEES,
    VOTER_POOL_FEES,
    VOTER_VOTE_INCENTIVE
}

struct EarnedReward {
    EarnedRewardType _type;
    address pool;
    address token;
}

contract RewardsDistributor is Initializable {
    using Status for mapping(address => uint256);
    using SafeERC20 for IERC20;

    uint256 private constant EPOCH_DURATION = 1 weeks;
    address public solidlyMinter;
    address public solidlyVoter;
    address public solidlyToken;
    address public owner;
    Root public root;
    mapping(address setter => uint256 status) public isRootSetter;
    mapping(address pauser => uint256 status) public isClaimsPauser;
    mapping(address token => uint256 amount) public approvedIncentiveAmounts;
    uint256 public claimDelay;
    uint256 public activePeriod;
    uint256 public maxIncentivePeriods;

    mapping(address earner => mapping(bytes32 rewardKey => Claim claim))
        public claims;
    mapping(uint256 period => mapping(bytes32 rewardKey => uint256 rewardAmount))
        public periodRewards;

    event OwnerChanged(address newOwner);
    event ClaimDelayChanged(uint256 newClaimDelay);
    event MaxIncentivePeriodsChanged(uint256 newMaxIncentivePeriods);
    event RootChanged(address setter, bytes32 newRoot);
    event RootSetterStatusToggled(address setter, uint256 newStatus);
    event ClaimsPaused(address pauser);
    event ClaimsPauserStatusToggled(address pauser, uint256 newStatus);
    event PoolFeesCollected(address pool, uint256 amount0, uint256 amount1);
    event ApprovedIncentiveAmountsChanged(address token, uint256 newAmount);
    event LPSolidEmissionsDeposited(
        address pool,
        uint256 amount,
        uint256 period
    );
    event LPTokenIncentiveDeposited(
        address depositor,
        address pool,
        address token,
        uint256 amount,
        uint256 periodReceived,
        uint256 distributionStart,
        uint256 distributionEnd
    );
    event VoteIncentiveDeposited(
        address depositor,
        address pool,
        address token,
        uint256 amount,
        uint256 periodReceived,
        uint256 distributionStart,
        uint256 distributionEnd
    );
    event RewardStored(
        uint256 periodReceived,
        StoredRewardType _type,
        address pool,
        address token,
        uint256 amount
    );
    event RewardClaimed(
        address earner,
        EarnedRewardType _type,
        address pool,
        address token,
        uint256 amount
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _solidlyMinter,
        address _solidlyVoter
    ) external {
        owner = msg.sender;
        solidlyMinter = _solidlyMinter;
        solidlyVoter = _solidlyVoter;
        solidlyToken = IMinter(solidlyMinter)._token();
        activePeriod = IMinter(solidlyMinter).active_period();
        claimDelay = 1 hours;
        maxIncentivePeriods = 4;
    }

    struct MultiProof {
        bytes32[] path;
        bool[] flags;
    }

    struct ClaimParams {
        address[] earners;
        EarnedRewardType[] types;
        address[] pools;
        address[] tokens;
        uint256[] amounts;
        MultiProof proof;
    }

    function claimAll(ClaimParams calldata params) external {
        if (block.timestamp < root.lastUpdatedAt + claimDelay)
            revert BufferPeriod();
        uint256 numClaims = params.earners.length;

        // verify claim against merkle root
        _verifyProof(params);

        // iterate over each token to be claimed
        for (uint256 i = 0; i < numClaims; ) {
            _claimSingle(
                params.earners[i],
                params.types[i],
                params.pools[i],
                params.tokens[i],
                params.amounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    function _claimSingle(
        address earner,
        EarnedRewardType _type,
        address pool,
        address token,
        uint256 amount
    ) private {
        // get already claimed amounts
        bytes32 rewardKey = getRewardKey(
            RewardType.EARNED,
            uint8(_type),
            pool,
            token
        );
        uint256 previouslyClaimed = claims[earner][rewardKey].amount;

        // calc owed amounts (delta vs already claimed)
        uint256 amountDelta = amount - previouslyClaimed;
        if (amountDelta == 0) revert AlreadyClaimed();

        // replace old claimed amount w/ new amount
        claims[earner][rewardKey] = Claim(amount, block.timestamp);

        // check if this contract has enough tokens to satisfy the claim
        // only relevant for claims on pool fees, for which this contract cannot receive the funds in advance
        if (
            (_type == EarnedRewardType.LP_POOL_FEES ||
                _type == EarnedRewardType.PROTOCOL_POOL_FEES ||
                _type == EarnedRewardType.VOTER_POOL_FEES) &&
            _balance(token) < amountDelta
        ) {
            _collectPoolFees(pool);
        }

        // send tokens and emit claimed event
        IERC20(token).safeTransfer(earner, amountDelta);
        emit RewardClaimed(earner, _type, pool, token, amount);
    }

    function _verifyProof(ClaimParams calldata params) private view {
        bytes32[] memory leaves = _generateLeaves(
            params.earners,
            params.types,
            params.pools,
            params.tokens,
            params.amounts
        );
        if (
            !MerkleProof.multiProofVerify(
                params.proof.path,
                params.proof.flags,
                root.value,
                leaves
            )
        ) revert InvalidProof();
    }

    function _generateLeaves(
        address[] calldata earners,
        EarnedRewardType[] calldata types,
        address[] calldata pools,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) private pure returns (bytes32[] memory) {
        uint256 numLeaves = earners.length;
        bytes32[] memory leaves = new bytes32[](numLeaves);
        for (uint256 i; i < earners.length; ) {
            bytes32 leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            earners[i],
                            types[i],
                            pools[i],
                            tokens[i],
                            amounts[i]
                        )
                    )
                )
            );
            leaves[i] = leaf;
            unchecked {
                ++i;
            }
        }
        return leaves;
    }

    function depositLPSolidEmissions(address pool, uint256 amount) external {
        if (msg.sender != solidlyVoter) revert NotVoter();

        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.LP_SOLID_EMISSIONS,
            pool: pool,
            token: solidlyToken
        });
        uint256 _activePeriod = _syncActivePeriod();
        _depositLPIncentive(reward, amount, _activePeriod);

        emit LPSolidEmissionsDeposited(pool, amount, _activePeriod);
    }

    function depositLPTokenIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {
        _validateIncentive(
            token,
            amount,
            distributionStart,
            numDistributionPeriods
        );

        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.LP_TOKEN_INCENTIVE,
            pool: pool,
            token: token
        });
        uint256 periodReceived = _syncActivePeriod();
        _depositLPIncentive(reward, amount, periodReceived);

        emit LPTokenIncentiveDeposited(
            msg.sender,
            pool,
            token,
            amount,
            periodReceived,
            distributionStart,
            distributionStart + (EPOCH_DURATION * numDistributionPeriods)
        );
    }

    function _depositLPIncentive(
        StoredReward memory reward,
        uint256 amount,
        uint256 periodReceived
    ) private {
        IERC20(reward.token).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _storeReward(periodReceived, reward, amount);
    }

    function depositVoteIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {
        if (!IVoter(solidlyVoter).isWhitelisted(pool))
            revert PoolNotWhitelisted();
        _validateIncentive(
            token,
            amount,
            distributionStart,
            numDistributionPeriods
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        StoredReward memory reward = StoredReward({
            _type: StoredRewardType.VOTE_INCENTIVE,
            pool: pool,
            token: token
        });
        uint256 periodReceived = _syncActivePeriod();
        _storeReward(periodReceived, reward, amount);

        emit VoteIncentiveDeposited(
            msg.sender,
            pool,
            token,
            amount,
            periodReceived,
            distributionStart,
            distributionStart + (EPOCH_DURATION * numDistributionPeriods)
        );
    }

    function _storeReward(
        uint256 period,
        StoredReward memory reward,
        uint256 amount
    ) private {
        bytes32 rewardKey = getRewardKey(
            RewardType.STORED,
            uint8(reward._type),
            reward.pool,
            reward.token
        );
        periodRewards[period][rewardKey] += amount;
        emit RewardStored(
            period,
            reward._type,
            reward.pool,
            reward.token,
            amount
        );
    }

    function _validateIncentive(
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) private view {
        // distribution must start on future epoch flip and last for [1, max] periods
        if (
            numDistributionPeriods == 0 ||
            numDistributionPeriods > maxIncentivePeriods ||
            distributionStart % EPOCH_DURATION != 0 ||
            distributionStart < block.timestamp
        ) revert InvalidIncentiveDistributionPeriod();

        uint256 minAmount = approvedIncentiveAmounts[token] *
            numDistributionPeriods;
        if (minAmount == 0 || amount < minAmount)
            revert InvalidIncentiveAmount();
    }

    function collectPoolFees(
        address pool
    ) external returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _collectPoolFees(pool);
    }

    // pulls trading fees from pools and stores amounts in periodRewards
    function _collectPoolFees(
        address pool
    ) private returns (uint256 amount0, uint256 amount1) {
        (uint128 amount0As128, uint128 amount1As128) = ISolidlyV3PoolMinimal(
            pool
        ).collectProtocol(address(this), type(uint128).max, type(uint128).max);
        (amount0, amount1) = (uint256(amount0As128), uint256(amount1As128));
        uint256 _activePeriod = _syncActivePeriod();
        if (amount0 > 0) {
            StoredReward memory r0 = StoredReward({
                _type: StoredRewardType.POOL_FEES,
                pool: pool,
                token: ISolidlyV3PoolMinimal(pool).token0()
            });
            _storeReward(_activePeriod, r0, amount0);
        }
        if (amount1 > 0) {
            StoredReward memory r1 = StoredReward({
                _type: StoredRewardType.POOL_FEES,
                pool: pool,
                token: ISolidlyV3PoolMinimal(pool).token1()
            });
            _storeReward(_activePeriod, r1, amount1);
        }

        emit PoolFeesCollected(pool, amount0, amount1);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    function toggleRootSetterStatus(address addr) external onlyOwner {
        uint256 newStatus = isRootSetter.toggle(addr);
        emit RootSetterStatusToggled(addr, newStatus);
    }

    function setRoot(bytes32 _root) external {
        if (isRootSetter[msg.sender] == 0) revert NotRootSetter();
        root = Root({value: _root, lastUpdatedAt: block.timestamp});
        emit RootChanged(msg.sender, _root);
    }

    function setClaimDelay(uint256 newClaimDelay) external onlyOwner {
        claimDelay = newClaimDelay;
        emit ClaimDelayChanged(newClaimDelay);
    }

    function setMaxIncentivePeriods(
        uint256 newMaxIncentivePeriods
    ) external onlyOwner {
        maxIncentivePeriods = newMaxIncentivePeriods;
        emit MaxIncentivePeriodsChanged(newMaxIncentivePeriods);
    }

    function updateApprovedIncentiveAmounts(
        address token,
        uint256 amount
    ) external {
        if (!IVoter(solidlyVoter).isOperator(msg.sender)) revert NotOperator();
        approvedIncentiveAmounts[token] = amount;
        emit ApprovedIncentiveAmountsChanged(token, amount);
    }

    function toggleClaimsPauserStatus(address addr) external onlyOwner {
        uint256 newStatus = isClaimsPauser.toggle(addr);
        emit ClaimsPauserStatusToggled(addr, newStatus);
    }

    function pauseClaims() external {
        if (isClaimsPauser[msg.sender] == 0) revert NotClaimsPauser();
        bytes32 zeroRoot = 0x0;
        root = Root({value: zeroRoot, lastUpdatedAt: block.timestamp});
        emit RootChanged(msg.sender, zeroRoot);
        emit ClaimsPaused(msg.sender);
    }

    function getRewardKey(
        RewardType _type,
        uint8 subtype,
        address pool,
        address token
    ) public pure returns (bytes32 key) {
        key = keccak256(abi.encodePacked(_type, subtype, pool, token));
    }

    function _syncActivePeriod() private returns (uint256 _activePeriod) {
        _activePeriod = activePeriod;
        if (block.timestamp >= _activePeriod + EPOCH_DURATION) {
            uint256 _minterActivePeriod = IMinter(solidlyMinter)
                .active_period();
            if (_activePeriod != _minterActivePeriod) {
                _activePeriod = _minterActivePeriod;
                activePeriod = _activePeriod;
            }
        }
    }

    /// @dev Get this contract's balance of a pool fee token
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    function _balance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
}
