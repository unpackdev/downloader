// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MuonClientBase.sol";
import "./SchnorrSECP256K1VerifierV2.sol";
import "./IMuonNodeManager.sol";
import "./IBondedToken.sol";

contract MuonNodeStaking is
    Initializable,
    AccessControlUpgradeable,
    MuonClientBase
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct User {
        uint256 balance;
        uint256 paidReward;
        uint256 paidRewardPerToken;
        uint256 pendingRewards;
        uint256 tokenId;
    }

    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");

    uint256 public totalStaked;

    uint256 public notPaidRewards;

    uint256 public exitPendingPeriod;

    uint256 public minStakeAmount;

    uint256 public periodFinish;

    uint256 public rewardRate;

    uint256 public lastUpdateTime;

    uint256 public rewardPerTokenStored;

    mapping(address => User) public users;

    IMuonNodeManager public nodeManager;

    IERC20Upgradeable public muonToken;

    // stakerAddress => bool
    mapping(address => bool) public lockedStakes;

    // address public vePion;
    IBondedToken public bondedToken;

    // token address => index + 1
    mapping(address => uint16) public isStakingToken;

    address[] public stakingTokens;

    // token => multiplier * 1e18
    mapping(address => uint256) public stakingTokensMultiplier;

    // tier => maxStakeAmount
    mapping(uint8 => uint256) public tiersMaxStakeAmount;

    // function name => paused
    mapping(string => bool) public functionPauseStatus;

    SchnorrSECP256K1VerifierV2 public verifier;


    uint256 public rewardPeriod;

    // ======== Events ========
    event Staked(address indexed stakerAddress, uint256 amount);
    event Withdrawn(address indexed stakerAddress, uint256 tokenId);
    event RewardGot(bytes reqId, address indexed stakerAddress, uint256 amount);
    event ExitRequested(address indexed stakerAddress);
    event MuonNodeAdded(
        address indexed nodeAddress,
        address indexed stakerAddress,
        string peerId
    );
    event RewardsDistributed(
        uint256 reward,
        uint256 indexed periodStart,
        uint256 _rewardPeriod
    );
    event ExitPendingPeriodUpdated(uint256 exitPendingPeriod);
    event MinStakeAmountUpdated(uint256 minStakeAmount);
    event MuonAppIdUpdated(uint256 muonAppId);
    event MuonPublicKeyUpdated(PublicKey muonPublicKey);
    event StakeLockStatusChanged(address indexed stakerAddress, bool locked);
    event StakingTokenUpdated(address indexed token, uint256 multiplier);
    event TierMaxStakeUpdated(uint8 indexed tier, uint256 maxStakeAmount);
    event FunctionPauseStatusChanged(
        string indexed functionName,
        bool isPaused
    );
    event VerifierUpdated(address verifierAddress);

    // ======== Modifiers ========
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenFunctionNotPaused(string memory functionName) {
        require(!functionPauseStatus[functionName], "Function is paused.");
        _;
    }

    /**
     * @dev Modifier that updates the reward parameters
     * before all of the functions that can change the rewards.
     *
     * `stakerAddress` should be address(0) when new rewards are distributing.
     */
    modifier updateReward(address stakerAddress) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (stakerAddress != address(0)) {
            users[stakerAddress].pendingRewards = earned(stakerAddress);
            users[stakerAddress].paidRewardPerToken = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Initializes the contract.
     * @param _muonTokenAddress The address of the Muon token.
     * @param _nodeManagerAddress The address of the Muon Node Manager contract.
     * @param _muonAppId The Muon app ID.
     * @param _muonPublicKey The Muon public key.
     * @param _bondedTokenAddress The address of the BondedToken contract.
     */
    function initialize(
        address _muonTokenAddress,
        address _nodeManagerAddress,
        uint256 _muonAppId,
        PublicKey memory _muonPublicKey,
        address _bondedTokenAddress
    ) external initializer {
        __MuonNodeStakingUpgradeable_init(
            _muonTokenAddress,
            _nodeManagerAddress,
            _muonAppId,
            _muonPublicKey,
            _bondedTokenAddress
        );
    }

    function __MuonNodeStakingUpgradeable_init(
        address _muonTokenAddress,
        address _nodeManagerAddress,
        uint256 _muonAppId,
        PublicKey memory _muonPublicKey,
        address _bondedTokenAddress
    ) internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ROLE, msg.sender);

        muonToken = IERC20Upgradeable(_muonTokenAddress);
        nodeManager = IMuonNodeManager(_nodeManagerAddress);
        bondedToken = IBondedToken(_bondedTokenAddress);

        exitPendingPeriod = 7 days;
        minStakeAmount = 500 ether;

        rewardPeriod = 7 days;

        validatePubKey(_muonPublicKey.x);
        muonPublicKey = _muonPublicKey;
        muonAppId = _muonAppId;
    }

    function __MuonNodeStakingUpgradeable_init_unchained()
        internal
        initializer
    {}

    /**
     * @dev Updates the list of staking tokens and their multipliers.
     * Only callable by the DAO_ROLE.
     * @param tokens The array of staking token addresses.
     * @param multipliers The array of corresponding multipliers for each token.
     */
    function updateStakingTokens(
        address[] calldata tokens,
        uint256[] calldata multipliers
    ) external onlyRole(DAO_ROLE) {
        uint256 tokensLength = tokens.length;

        require(tokensLength == multipliers.length, "Arrays length mismatch.");

        for (uint256 i = 0; i < tokensLength; i++) {
            address token = tokens[i];
            uint256 multiplier = multipliers[i];

            if (isStakingToken[token] > 0) {
                if (multiplier == 0) {
                    uint16 tokenIndex = isStakingToken[token] - 1;
                    address lastToken = stakingTokens[stakingTokens.length - 1];

                    stakingTokens[tokenIndex] = lastToken;
                    isStakingToken[lastToken] = isStakingToken[token];
                    stakingTokens.pop();
                    isStakingToken[token] = 0;
                }

                stakingTokensMultiplier[token] = multiplier;
            } else {
                require(multiplier > 0, "Invalid multiplier.");
                stakingTokens.push(token);
                stakingTokensMultiplier[token] = multiplier;
                isStakingToken[token] = uint16(stakingTokens.length);
            }
            emit StakingTokenUpdated(token, multiplier);
        }
    }

    /**
     * @dev Locks the specified tokens in the BondedToken contract for a given tokenId.
     * The staker must first approve the contract to transfer the tokens on their behalf.
     * Only the staker can call this function.
     * @param tokens The array of token addresses to be locked.
     * @param amounts The corresponding array of token amounts to be locked.
     */
    function lockToBondedToken(
        address[] memory tokens,
        uint256[] memory amounts
    ) external whenFunctionNotPaused("lockToBondedToken") {
        uint256 tokensLength = tokens.length;

        require(tokensLength == amounts.length, "Arrays length mismatch.");

        uint256 tokenId = users[msg.sender].tokenId;
        require(tokenId != 0, "No staking found.");
        require(
            bondedToken.ownerOf(tokenId) == address(this),
            "Staking contract is not the owner of the NFT."
        );

        for (uint256 i = 0; i < tokensLength; i++) {
            uint256 balance = IERC20Upgradeable(tokens[i]).balanceOf(
                address(this)
            );

            IERC20Upgradeable(tokens[i]).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[i]
            );

            uint256 receivedAmount = IERC20Upgradeable(tokens[i]).balanceOf(
                address(this)
            ) - balance;
            require(
                amounts[i] == receivedAmount,
                "The discrepancy between the received amount and the claimed amount."
            );

            IERC20Upgradeable(tokens[i]).safeApprove(
                address(bondedToken),
                amounts[i]
            );
        }

        bondedToken.lock(tokenId, tokens, amounts);

        _updateStaking(msg.sender);
    }

    /**
     * @dev Merges two bonded tokens in the BondedToken contract.
     * The staker must first approve the contract to transfer the tokenIdA on their behalf.
     * @param tokenIdA The id of the first token to be merged.
     */
    function mergeBondedTokens(
        uint256 tokenIdA
    ) external whenFunctionNotPaused("mergeBondedTokens") {
        require(
            bondedToken.ownerOf(tokenIdA) == msg.sender,
            "Caller is not token owner."
        );

        uint256 tokenIdB = users[msg.sender].tokenId;
        require(tokenIdB != 0, "No staking found.");
        require(
            bondedToken.ownerOf(tokenIdB) == address(this),
            "Staking contract is not token owner."
        );

        bondedToken.safeTransferFrom(msg.sender, address(this), tokenIdA);
        bondedToken.approve(address(bondedToken), tokenIdA);

        bondedToken.merge(tokenIdA, tokenIdB);

        _updateStaking(msg.sender);
    }

    /**
     * @dev Updates the staking status for the staker.
     * This function calculates the staked amount based on the locked tokens and their multipliers,
     * and updates the balance and total staked amount accordingly.
     * Only callable by staker.
     */
    function updateStaking() external {
        _updateStaking(msg.sender);
    }

    /**
     * @dev Allows the stakers to withdraw their rewards.
     * @param amount The amount of tokens to withdraw.
     * @param reqId The id of the withdrawal request.
     * @param signature A tss signature that proves the authenticity of the withdrawal request.
     */
    function getReward(
        uint256 amount,
        uint256 paidRewardPerToken,
        bytes calldata reqId,
        SchnorrSign calldata signature
    ) external whenFunctionNotPaused("getReward") {
        require(amount > 0, "Invalid amount.");

        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            msg.sender
        );
        require(node.id != 0, "Node not found.");

        User memory user = users[msg.sender];
        require(
            user.paidRewardPerToken <= paidRewardPerToken &&
                paidRewardPerToken <= rewardPerToken(),
            "Invalid paidRewardPerToken."
        );

        // Verify the authenticity of the withdrawal request.
        bytes32 hash = keccak256(
            abi.encodePacked(
                muonAppId,
                reqId,
                msg.sender,
                user.paidReward,
                paidRewardPerToken,
                amount
            )
        );

        bool verified = verifier.verifySignature(
            muonPublicKey.x,
            muonPublicKey.parity,
            signature.signature,
            uint256(hash),
            signature.nonce
        );
        require(verified, "Invalid signature.");

        uint256 maxReward = (user.balance *
            (paidRewardPerToken - user.paidRewardPerToken)) /
            1e18 +
            user.pendingRewards;
        require(amount <= maxReward, "Invalid withdrawal amount.");
        notPaidRewards += (maxReward - amount);

        require(amount <= earned(msg.sender), "Invalid withdrawal amount.");

        users[msg.sender].pendingRewards = 0;
        users[msg.sender].paidReward += amount;
        users[msg.sender].paidRewardPerToken = paidRewardPerToken;
        muonToken.safeTransfer(msg.sender, amount);
        emit RewardGot(reqId, msg.sender, amount);
    }

    /**
     * @dev Allows stakers to request to exit from the network.
     * Stakers can withdraw the staked amount after the exit pending period has passed.
     */
    function requestExit() external {
        _deactiveMuonNode(msg.sender);

        emit ExitRequested(msg.sender);
    }

    /**
     * @dev Allows DAO_ROLE to deactive a node.
     * @param stakerAddress The address of the staker.
     */
    function deactiveMuonNode(
        address stakerAddress
    ) external onlyRole(DAO_ROLE) {
        _deactiveMuonNode(stakerAddress);
    }

    /**
     * @dev Allows stakers to withdraw their staked amount after exiting the network and exit pending period has passed.
     */
    function withdraw() external whenFunctionNotPaused("withdraw") {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            msg.sender
        );
        require(node.id != 0, "Node not found.");

        require(
            !node.active &&
                (node.endTime + exitPendingPeriod) < block.timestamp,
            "The exit time has not been reached yet."
        );

        require(!lockedStakes[msg.sender], "Stake is locked.");

        uint256 tokenId = users[msg.sender].tokenId;
        require(tokenId != 0, "No staking found.");

        if (users[msg.sender].balance > 0) {
            totalStaked -= users[msg.sender].balance;
            users[msg.sender].balance = 0;
        }

        users[msg.sender].tokenId = 0;
        bondedToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }

    /**
     * @dev Allows users to add a Muon node.
     * The user must have a sufficient staking amount in the BondedToken contract to run a node.
     * @param nodeAddress The address of the Muon node.
     * @param peerId The peer ID of the node.
     * @param tokenId The id of the staking token.
     */
    function addMuonNode(
        address nodeAddress,
        string calldata peerId,
        uint256 tokenId
    ) external whenFunctionNotPaused("addMuonNode") {
        require(users[msg.sender].tokenId == 0, "Already staked an NFT.");

        uint256 amount = valueOfBondedToken(tokenId);
        require(amount >= minStakeAmount, "Insufficient staking.");

        users[msg.sender].tokenId = tokenId;

        bondedToken.safeTransferFrom(msg.sender, address(this), tokenId);
        require(
            bondedToken.ownerOf(tokenId) == address(this),
            "Not received the NFT."
        );

        nodeManager.addNode(
            nodeAddress,
            msg.sender, // stakerAddress
            peerId,
            true // active
        );
        emit MuonNodeAdded(nodeAddress, msg.sender, peerId);
    }

    /**
     * @dev Distributes the specified reward amount to the stakers.
     * Only callable by the REWARD_ROLE.
     * @param reward The reward amount to be distributed.
     */
    function distributeRewards(
        uint256 reward
    ) external updateReward(address(0)) onlyRole(REWARD_ROLE) {
        if (block.timestamp >= periodFinish) {
            rewardRate = (reward + notPaidRewards) / rewardPeriod;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover + notPaidRewards) / rewardPeriod;
        }

        notPaidRewards = 0;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardPeriod;
        emit RewardsDistributed(reward, block.timestamp, rewardPeriod);
    }

    /**
     * @dev Locks or unlocks the specified staker's stake.
     * Only callable by the REWARD_ROLE.
     * @param stakerAddress The address of the staker.
     * @param lockStatus Boolean indicating whether to lock (true) or unlock (false) the stake.
     */
    function setStakeLockStatus(
        address stakerAddress,
        bool lockStatus
    ) external onlyRole(REWARD_ROLE) {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            stakerAddress
        );
        require(node.id != 0, "Node not found.");

        bool currentLockStatus = lockedStakes[stakerAddress];
        require(
            currentLockStatus != lockStatus,
            lockStatus ? "Already locked." : "Already unlocked."
        );

        lockedStakes[stakerAddress] = lockStatus;
        emit StakeLockStatusChanged(stakerAddress, lockStatus);
    }

    /**
     * @dev ERC721 token receiver function.
     *
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ======== DAO functions ========

    function setExitPendingPeriod(
        uint256 _exitPendingPeriod
    ) external onlyRole(DAO_ROLE) {
        exitPendingPeriod = _exitPendingPeriod;
        emit ExitPendingPeriodUpdated(_exitPendingPeriod);
    }

    function setRewardPeriod(
        uint256 period
    ) external updateReward(address(0)) onlyRole(DAO_ROLE) {
        require(
            block.timestamp >= periodFinish,
            "old period is still active"
        );
        rewardPeriod = period;
    }

    function setMinStakeAmount(
        uint256 _minStakeAmount
    ) external onlyRole(DAO_ROLE) {
        minStakeAmount = _minStakeAmount;
        emit MinStakeAmountUpdated(_minStakeAmount);
    }

    function setMuonAppId(uint256 _muonAppId) external onlyRole(DAO_ROLE) {
        muonAppId = _muonAppId;
        emit MuonAppIdUpdated(_muonAppId);
    }

    function setMuonPublicKey(
        PublicKey memory _muonPublicKey
    ) external onlyRole(DAO_ROLE) {
        verifier.validatePubKey(_muonPublicKey.x);

        muonPublicKey = _muonPublicKey;
        emit MuonPublicKeyUpdated(_muonPublicKey);
    }

    function setVerifier(
        address _verifierAddress
    ) external onlyRole(DAO_ROLE) {
        verifier = SchnorrSECP256K1VerifierV2(_verifierAddress);
        emit VerifierUpdated(_verifierAddress);
    }

    function setTierMaxStakeAmount(
        uint8 tier,
        uint256 maxStakeAmount
    ) external onlyRole(DAO_ROLE) {
        tiersMaxStakeAmount[tier] = maxStakeAmount;
        emit TierMaxStakeUpdated(tier, maxStakeAmount);
    }

    function setMuonNodeTier(address stakerAddress, uint8 tier)
        public
        onlyRole(DAO_ROLE)
        updateReward(stakerAddress)
    {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            stakerAddress
        );
        nodeManager.setTier(node.id, tier);
        _updateStaking(stakerAddress);
    }

    function setFunctionPauseStatus(
        string memory functionName,
        bool pauseStatus
    ) external onlyRole(DAO_ROLE) {
        bool currentStatus = functionPauseStatus[functionName];
        require(
            currentStatus != pauseStatus,
            pauseStatus ? "Already paused." : "Already unpaused."
        );

        functionPauseStatus[functionName] = pauseStatus;
        emit FunctionPauseStatusChanged(functionName, pauseStatus);
    }

    /**
     * @dev Calculates the total value of a bonded token in terms of the staking tokens.
     * @param tokenId The id of the bonded token.
     * @return amount The total value of the bonded token.
     */
    function valueOfBondedToken(
        uint256 tokenId
    ) public view returns (uint256 amount) {
        uint256[] memory lockedAmounts = bondedToken.getLockedOf(
            tokenId,
            stakingTokens
        );

        amount = 0;
        uint256 lockedAmountsLength = lockedAmounts.length;
        for (uint256 i = 0; i < lockedAmountsLength; i++) {
            address token = stakingTokens[i];
            uint256 multiplier = stakingTokensMultiplier[token];
            amount += (multiplier * lockedAmounts[i]) / 1e18;
        }
        return amount;
    }

    /**
     * @dev Calculates the current reward per token.
     * The reward per token is the amount of reward earned per staking token until now.
     * @return The current reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        } else {
            return
                rewardPerTokenStored +
                ((lastTimeRewardApplicable() - lastUpdateTime) *
                    rewardRate *
                    1e18) /
                totalStaked;
        }
    }

    /**
     * @dev Calculates the total rewards earned by a node.
     * @param stakerAddress The staker address of a node.
     * @return The total rewards earned by a node.
     */
    function earned(address stakerAddress) public view returns (uint256) {
        User memory user = users[stakerAddress];
        return
            (user.balance * (rewardPerToken() - user.paidRewardPerToken)) /
            1e18 +
            user.pendingRewards;
    }

    /**
     * @dev Returns the last time when rewards were applicable.
     * @return The last time when rewards were applicable.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function _updateStaking(
        address stakerAddress
    ) private updateReward(stakerAddress) {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            stakerAddress
        );
        require(node.id != 0 && node.active, "No active node found.");

        uint256 tokenId = users[stakerAddress].tokenId;
        require(tokenId != 0, "No staking found.");

        uint256 amount = valueOfBondedToken(tokenId);
        require(amount >= minStakeAmount, "Insufficient staking.");

        uint256 maxStakeAmount = tiersMaxStakeAmount[node.tier];
        if (amount > maxStakeAmount) {
            amount = maxStakeAmount;
        }

        if (users[stakerAddress].balance != amount) {
            totalStaked -= users[stakerAddress].balance;
            users[stakerAddress].balance = amount;
            totalStaked += amount;
            emit Staked(stakerAddress, amount);
        }
    }

    function _deactiveMuonNode(
        address stakerAddress
    ) private updateReward(stakerAddress) {
        IMuonNodeManager.Node memory node = nodeManager.stakerAddressInfo(
            stakerAddress
        );

        totalStaked -= users[stakerAddress].balance;
        users[stakerAddress].balance = 0;
        nodeManager.deactiveNode(node.id);
    }
}
