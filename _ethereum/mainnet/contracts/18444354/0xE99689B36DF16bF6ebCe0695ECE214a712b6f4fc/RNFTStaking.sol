// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuard.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SignedSafeMath.sol";
import "./ISmartWalletWhitelist.sol";
import "./console.sol";

contract RNFTStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    struct UserInfo {
        uint256 amount;
        uint256[] tokenIds;
        mapping(uint256 => int256) rewardDebt;
        mapping(uint256 => uint256) tokenIndices;
    }

    uint256 public lastRewardTime;
    uint256[] public accRewardPerShare;
    mapping(address => bool) public isReward;
    address public smartWalletChecker;

    /// @notice Address of rewards contract.
    IERC20[] public rewards;
    /// @notice Address of the NFT token for each MCV2 pool.
    IERC721 public NFT;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice Info of each user that stakes nft tokens.
    mapping(address => UserInfo) public userInfo;

    /// @notice Keeper register. Return true if 'address' is a keeper.
    mapping(address => bool) public isKeeper;

    uint256[] public rewardPerSeconds;
    uint256 private ACC_REWARD_PRECISION;

    uint256 public distributePeriod;
    uint256[] public lastDistributedTimes;

    mapping(uint256 => uint256) public overDistributed;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256[] amount);
    event LogUpdatePool(uint256 lastRewardTime, uint256 nftSupply);
    event LogRewardPerSecond(uint256 rewardId, uint256 rewardPerSecond);

    modifier onlyKeeper() {
        require(msg.sender == owner() || isKeeper[msg.sender], "not keeper");
        _;
    }

    modifier onlyWhitelisted() {
        if (tx.origin != msg.sender) {
            require(
                address(smartWalletChecker) != address(0),
                "Not whitelisted"
            );
            require(
                ISmartWalletWhitelist(smartWalletChecker).check(msg.sender),
                "Not whitelisted"
            );
        }
        _;
    }

    constructor() {}

    function initialize(
        IERC721 _NFT,
        address _smartWalletChecker,
        uint256 _distributePeriod
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(address(_NFT) != address(0), "Zero Address");
        require(address(_smartWalletChecker) != address(0), "Zero Address");
        NFT = _NFT;
        distributePeriod = _distributePeriod;
        ACC_REWARD_PRECISION = 1e12;
        smartWalletChecker = _smartWalletChecker;
    }

    /// @notice add keepers
    function addKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for (i; i < len; i++) {
            address _keeper = _keepers[i];
            if (!isKeeper[_keeper]) {
                isKeeper[_keeper] = true;
            }
        }
    }

    /// @notice remove keepers
    function removeKeeper(address[] memory _keepers) external onlyOwner {
        uint256 i = 0;
        uint256 len = _keepers.length;

        for (i; i < len; i++) {
            address _keeper = _keepers[i];
            if (isKeeper[_keeper]) {
                isKeeper[_keeper] = false;
            }
        }
    }

    function setSmartWalletChecker(address _checker) public onlyOwner {
        smartWalletChecker = _checker;
    }

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardIds The amount of Reward to be distributed per second.
    /// @param _rewardPerSeconds The amount of Reward to be distributed per second.
    function setRewardPerSecond(
        uint256[] memory _rewardIds,
        uint256[] memory _rewardPerSeconds
    ) public onlyOwner {
        updatePool();
        for (uint256 i = 0; i < _rewardIds.length; i++) {
            rewardPerSeconds[_rewardIds[i]] = _rewardPerSeconds[i];
            emit LogRewardPerSecond(_rewardIds[i], _rewardPerSeconds[i]);
        }
    }

    function _setDistributionRate(uint256 rewardId, uint256 amount) internal {
        updatePool();
        uint256 _notDistributed;
        uint256 lastDistributedTime = lastDistributedTimes[rewardId];
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime.sub(block.timestamp);
            _notDistributed = rewardPerSeconds[rewardId].mul(timeLeft);
        }

        amount = amount.add(_notDistributed);

        uint256 _moreDistributed = overDistributed[rewardId];
        overDistributed[rewardId] = 0;

        if (lastDistributedTime > 0 && block.timestamp > lastDistributedTime) {
            uint256 timeOver = block.timestamp.sub(lastDistributedTime);
            _moreDistributed = _moreDistributed.add(
                rewardPerSeconds[rewardId].mul(timeOver)
            );
        }

        if (amount < _moreDistributed) {
            overDistributed[rewardId] = _moreDistributed.sub(amount);
            rewardPerSeconds[rewardId] = 0;
            lastDistributedTimes[rewardId] = block.timestamp.add(
                distributePeriod
            );
            updatePool();
            emit LogRewardPerSecond(rewardId, rewardPerSeconds[rewardId]);
        } else {
            amount = amount.sub(_moreDistributed);
            rewardPerSeconds[rewardId] = amount.div(distributePeriod);
            lastDistributedTimes[rewardId] = block.timestamp.add(
                distributePeriod
            );
            updatePool();
            emit LogRewardPerSecond(rewardId, rewardPerSeconds[rewardId]);
        }
    }

    function addReward(address _reward) external onlyKeeper {
        _addReward(_reward);
    }

    function _addReward(address _reward) internal {
        require(_reward != address(0), "Invalid address");
        require(!isReward[_reward], "Reward already added");
        rewards.push(IERC20(_reward));
        accRewardPerShare.push(0);
        rewardPerSeconds.push(0);
        lastDistributedTimes.push(0);
        isReward[_reward] = true;
    }

    function seedRewards(
        uint256[] memory _rewardIds,
        uint256[] memory _amounts
    ) external nonReentrant {
        for (uint256 i = 0; i < _rewardIds.length; i++) {
            rewards[_rewardIds[i]].safeTransferFrom(
                msg.sender,
                address(this),
                _amounts[i]
            );
            _setDistributionRate(_rewardIds[i], _amounts[i]);
        }
    }

    /// @notice View function to see pending WBNB on frontend.
    /// @param _user Address of user.
    /// @return pending WBNB reward for a given user.
    function pendingReward(
        address _user
    ) external view returns (uint256[] memory pending) {
        UserInfo storage user = userInfo[_user];
        uint256 nftSupply = NFT.balanceOf(address(this));
        pending = new uint256[](rewards.length);
        if (block.timestamp > lastRewardTime && nftSupply != 0) {
            uint256 time = block.timestamp.sub(lastRewardTime);
            for (uint256 i = 0; i < rewards.length; i++) {
                uint256 reward = time.mul(rewardPerSeconds[i]);
                uint256 _accRewardPerShare = accRewardPerShare[i];
                _accRewardPerShare = _accRewardPerShare.add(
                    reward.mul(ACC_REWARD_PRECISION) / nftSupply
                );
                pending[i] = int256(
                    user.amount.mul(_accRewardPerShare) / ACC_REWARD_PRECISION
                ).sub(user.rewardDebt[i]).toUInt256();
            }
        }
    }

    function rewardLength() external view returns (uint256 _length) {
        _length = rewards.length;
    }

    /// @notice View function to see token Ids on frontend.
    /// @param _user Address of user.
    /// @return tokenIds Staked Token Ids for a given user.
    function stakedTokenIds(
        address _user
    ) external view returns (uint256[] memory tokenIds) {
        tokenIds = userInfo[_user].tokenIds;
    }

    /// @notice Update reward variables of the given pool.
    function updatePool() public {
        if (block.timestamp > lastRewardTime) {
            uint256 nftSupply = NFT.balanceOf(address(this));
            if (nftSupply > 0) {
                uint256 time = block.timestamp.sub(lastRewardTime);
                for (uint256 i = 0; i < rewards.length; i++) {
                    uint256 reward = time.mul(rewardPerSeconds[i]);
                    accRewardPerShare[i] = accRewardPerShare[i].add(
                        reward.mul(ACC_REWARD_PRECISION).div(nftSupply)
                    );
                }
            }
            lastRewardTime = block.timestamp;
            emit LogUpdatePool(lastRewardTime, nftSupply);
        }
    }

    /// @notice Deposit nft tokens to MCV2 for WBNB allocation.
    /// @param tokenIds NFT tokenIds to deposit.
    function stake(
        uint256[] calldata tokenIds,
        address to
    ) public nonReentrant onlyWhitelisted {
        updatePool();
        UserInfo storage user = userInfo[to];

        // Effects
        user.amount = user.amount.add(tokenIds.length);

        for (uint256 i = 0; i < rewards.length; i++) {
            user.rewardDebt[i] = user.rewardDebt[i].add(
                int256(
                    tokenIds.length.mul(accRewardPerShare[i]) /
                        ACC_REWARD_PRECISION
                )
            );
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NFT.ownerOf(tokenIds[i]) == msg.sender,
                "This NTF does not belong to address"
            );

            user.tokenIndices[tokenIds[i]] = user.tokenIds.length;
            user.tokenIds.push(tokenIds[i]);
            tokenOwner[tokenIds[i]] = to;

            NFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit Deposit(msg.sender, tokenIds.length, to);
    }

    /// @notice Withdraw NFT tokens from MCV2.
    /// @param tokenIds NFT token ids to withdraw.
    function unstake(
        uint256[] calldata tokenIds,
        address to
    ) public nonReentrant onlyWhitelisted {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];

        // Effects
        for (uint256 i = 0; i < rewards.length; i++) {
            user.rewardDebt[i] = user.rewardDebt[i].sub(
                int256(
                    tokenIds.length.mul(accRewardPerShare[i]) /
                        ACC_REWARD_PRECISION
                )
            );
        }
        user.amount = user.amount.sub(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenOwner[tokenIds[i]] == msg.sender,
                "Nft Staking System: user must be the owner of the staked nft"
            );
            NFT.transferFrom(address(this), to, tokenIds[i]);
            uint256 lastTokenId = user.tokenIds[user.tokenIds.length - 1];
            user.tokenIds[user.tokenIndices[tokenIds[i]]] = lastTokenId;
            user.tokenIndices[lastTokenId] = user.tokenIndices[tokenIds[i]];
            user.tokenIds.pop();
            delete user.tokenIndices[tokenIds[i]];
            delete tokenOwner[tokenIds[i]];
        }

        emit Withdraw(msg.sender, tokenIds.length, to);
    }

    /// @notice Harvest proceeds for transaction sender.
    function claim(address to) public nonReentrant onlyWhitelisted {
        updatePool();
        UserInfo storage user = userInfo[msg.sender];
        uint256[] memory pendingRewards = new uint256[](rewards.length);

        for (uint256 i = 0; i < rewards.length; i++) {
            int256 accumulatedReward = int256(
                user.amount.mul(accRewardPerShare[i]) / ACC_REWARD_PRECISION
            );
            uint256 _pendingReward = accumulatedReward
                .sub(user.rewardDebt[i])
                .toUInt256();

            // Effects
            user.rewardDebt[i] = accumulatedReward;

            // Interactions
            uint256 _balance = rewards[i].balanceOf(address(this));
            require(_pendingReward <= _balance, "Not enough rewards");
            if (_pendingReward != 0) {
                rewards[i].safeTransfer(to, _pendingReward);
            }
            pendingRewards[i] = _pendingReward;
        }

        emit Harvest(msg.sender, pendingRewards);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
