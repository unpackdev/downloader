pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./IUniswapV3Pool.sol";
import "./IMiningPool.sol";
import "./IWETH.sol";

// type(uintXXX).max is not available in solc 0.6.6, so copy source code and change it
// If newer version of solc is used in future, please use npm package directly
import "./OracleLibrary.sol";

contract MiningPool is OwnableUpgradeable, AccessControlUpgradeable, ERC165Upgradeable, IMiningPool {
    using SafeMath for uint256;

    bytes32 private constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    bytes4 private constant ERC1363RECEIVER_RETURN = bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
    uint8 private constant NOT_ENTERED = 1;
    uint8 private constant ENTERED = 2;

    uint8 private constant USDC_DECIMALS = 6;
    uint8 private constant MST_DECIMALS = 18;

    struct User {
        uint256 flexibleStake;
        uint64 stakeStart;
        uint64 stakeLast;
        uint64 stakeRewardsStart;
        uint64 stakeRewardsLast;
        uint64 redemptionStart;
        uint64 redemptionLast;
        bool isInList;
    }

    struct Node {
        uint256 amount;
        uint256 initialStakeAmount; // Used by fixed stake
        uint256 stakeRewardsAmount; // Used by fixed stake
        uint64 timestamp;
        uint64 next;
    }

    struct History {
        uint256 amount;
        uint64 timestamp;
    }

    mapping(address => User) private users;

    mapping(uint64 => Node) nodes;

    address[] userAddrList;

    History[] private poolHistory;

    mapping(address => History[]) private userHistory;

    IERC20 private tokenToStake;

    IERC20 private tokenToReward;

    IUniswapV3Pool private referenceUniswapV3Pool;

    uint256 private totalAnnualRewards;

    uint256 private fixedPoolCapacityUSD;

    uint256 private fixedPoolUsageUSD;

    uint64 private lockPeriod;

    uint64 private rewardPeriod;

    uint64 private redeemWaitPeriod;

    uint64 private nextNodeID;

    uint8 private directCalling;

    bool private isToken1;

    uint32 private priceConsultSeconds;

    uint256 private totalRequestedToRedeem;

    bool private isTokenToStakeWETH;

    function initialize(
        IERC20 _tokenToStake,
        IERC20 _tokenToReward,
        IUniswapV3Pool _referenceUniswapV3Pool,
        uint256 _totalAnnualRewards,
        uint256 _fixedPoolCapacityUSD,
        uint64 _lockPeriod,
        uint64 _rewardPeriod,
        uint64 _redeemWaitPeriod,
        bool _isTokenToStakeWETH
    ) external override initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __ERC165_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize values
        tokenToStake = _tokenToStake;
        tokenToReward = _tokenToReward;
        referenceUniswapV3Pool = _referenceUniswapV3Pool;
        totalAnnualRewards = _totalAnnualRewards;
        fixedPoolCapacityUSD = _fixedPoolCapacityUSD;
        fixedPoolUsageUSD = 0;
        lockPeriod = _lockPeriod;
        rewardPeriod = _rewardPeriod;
        redeemWaitPeriod = _redeemWaitPeriod;
        isTokenToStakeWETH = _isTokenToStakeWETH;
        nextNodeID = 1;
        directCalling = NOT_ENTERED;
        priceConsultSeconds = 1 hours;

        // Save whether the token to stake is token0 or token1 in Uniswap, then no need to get again next time
        if (address(_referenceUniswapV3Pool) != address(0)) {
            address addr = address(_tokenToStake);
            if (addr == _referenceUniswapV3Pool.token0()) {
                isToken1 = false;
            } else if (addr == _referenceUniswapV3Pool.token1()) {
                isToken1 = true;
            } else {
                revert("Invalid UniswapV3Pool");
            }
        }

        // Add an extra all 0 entry as first item, to make logic simpler
        poolHistory.push(History(0, 0));
        poolHistory.push(History(0, nextTimeSlot()));

        // ERC223, ERC677, ERC1363 recipient
        IMiningPool i;
        _registerInterface(i.tokenReceived.selector);
        _registerInterface(i.onTokenTransfer.selector);
        _registerInterface(i.onTransferReceived.selector);
    }

    function owner() public view override(OwnableUpgradeable, IOwnable) returns (address) {
        return OwnableUpgradeable.owner();
    }

    function renounceOwnership() public override(OwnableUpgradeable, IOwnable) {
        address _owner = owner();
        OwnableUpgradeable.renounceOwnership();
        revokeRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function transferOwnership(address newOwner) public override(OwnableUpgradeable, IOwnable) {
        address _owner = owner();
        require(_owner != newOwner, "Ownable: self ownership transfer");

        OwnableUpgradeable.transferOwnership(newOwner);
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165) returns (bool) {
        return ERC165Upgradeable.supportsInterface(interfaceId);
    }

    function tokenReceived(
        address from,
        uint256 amount,
        bytes calldata
    ) external override onlyAcceptableTokens {
        if (directCalling != ENTERED && msg.sender == address(tokenToStake)) {
            _stakeToken(from, amount);
        }
    }

    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata
    ) external override onlyAcceptableTokens returns (bool) {
        if (directCalling != ENTERED && msg.sender == address(tokenToStake)) {
            _stakeToken(from, amount);
        }

        return true;
    }

    function onTransferReceived(
        address,
        address from,
        uint256 value,
        bytes calldata
    ) external override onlyAcceptableTokens returns (bytes4) {
        if (directCalling != ENTERED && msg.sender == address(tokenToStake)) {
            _stakeToken(from, value);
        }

        return ERC1363RECEIVER_RETURN;
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() private {
        require(isTokenToStakeWETH, "Not WETH pool");

        if (directCalling != ENTERED) {
            uint256 amount = msg.value;
            IWETH(address(tokenToStake)).deposit{value: amount}();
            _stakeToken(msg.sender, amount);
        }
    }

    function getTokenToStake() external view override returns (address) {
        return address(tokenToStake);
    }

    function getTokenToReward() external view override returns (address) {
        return address(tokenToReward);
    }

    function getReferenceUniswapV3Pool() external view override returns (address) {
        return address(referenceUniswapV3Pool);
    }

    function getTotalAnnualRewards() external view override returns (uint256) {
        return totalAnnualRewards;
    }

    function getFixedPoolCapacityUSD() external view override returns (uint256) {
        return fixedPoolCapacityUSD;
    }

    function getFixedPoolUsageUSD() external view override returns (uint256) {
        return fixedPoolUsageUSD;
    }

    function getLockPeriod() external view override returns (uint64) {
        return lockPeriod;
    }

    function getRewardPeriod() external view override returns (uint64) {
        return rewardPeriod;
    }

    function getRedeemWaitPeriod() external view override returns (uint64) {
        return redeemWaitPeriod;
    }

    function getPoolStake() external view override returns (uint256) {
        return poolHistory[poolHistory.length - 1].amount;
    }

    function getPoolStakeAt(uint64 timestamp) public view override returns (Record memory) {
        // This function returns pool stake of passed time slot, which the value should be fixed
        // Therefore if query time slot of future, just return 0 to indicate fail
        uint64 timeSlot = timeSlotOf(timestamp);
        if (timeSlot > currentTimeSlot()) {
            return Record(0, 0);
        }

        // poolHistory stores pool stake at different time in order
        // So iterate from the end, find the history which is nearest to the time slot
        uint256 index = poolHistory.length - 1;
        while (index > 0) {
            if (poolHistory[index].timestamp <= timeSlot) {
                return Record(poolHistory[index].amount, timeSlot);
            }

            index--;
        }

        // To prevent underflow, while loop stops at index == 0
        // The amount of poolHistory[0] is hardcoded to 0
        return Record(0, timeSlot);
    }

    function getPoolRequestedToRedeem() external view override returns (uint256) {
        return totalRequestedToRedeem;
    }

    function getUserStake(address userAddr) external view override returns (uint256) {
        // Latest stake value is stored for rewards calculation, so no need to iterate linked list
        uint256 len = userHistory[userAddr].length;
        if (len == 0) {
            return 0;
        }

        return userHistory[userAddr][len - 1].amount;
    }

    function getUserStakeAt(address userAddr, uint64 timestamp) public view override returns (Record memory) {
        // Similar to getPoolStakeAt(), this function also gets data of the past
        uint64 timeSlot = timeSlotOf(timestamp);
        if (timeSlot > currentTimeSlot()) {
            return Record(0, 0);
        }

        History[] storage user = userHistory[userAddr];
        if (user.length == 0) {
            // This happens if user does not have any stake history
            return Record(0, timeSlot);
        }

        // Then the logic is also similar to getPoolStakeAt()
        uint256 index = user.length - 1;
        while (index > 0) {
            if (user[index].timestamp <= timeSlot) {
                return Record(user[index].amount, timeSlot);
            }

            index--;
        }

        return Record(0, timeSlot);
    }

    function getUserStakeLocked(address userAddr) external view override returns (uint256) {
        return sumListLocked(users[userAddr].stakeStart, lockPeriod);
    }

    function getUserStakeUnlocked(address userAddr) external view override returns (uint256) {
        // Also include flexible stake as it is always unlocked
        uint256 ret = sumListUnlocked(users[userAddr].stakeStart, lockPeriod);
        ret = ret.add(users[userAddr].flexibleStake);
        return ret;
    }

    function getUserStakeDetails(address userAddr) external view override returns (StakeRecord[] memory) {
        User memory user = users[userAddr];
        (uint64 nodeID, uint256 flexibleStake) = (user.stakeStart, user.flexibleStake);
        uint256 count = countList(nodeID);

        // If user has flexible stake, include it as first element
        StakeRecord[] memory ret;
        uint256 offset;
        if (flexibleStake != 0) {
            ret = new StakeRecord[](count + 1);
            offset = 1;
            ret[0] = StakeRecord(flexibleStake, flexibleStake, 0, 0);
        } else {
            ret = new StakeRecord[](count);
            offset = 0;
        }

        for (uint256 i = 0; i < count; i++) {
            Node memory n = nodes[nodeID];
            ret[i + offset] = StakeRecord(n.amount, n.initialStakeAmount, n.stakeRewardsAmount, n.timestamp);
            nodeID = n.next;
        }

        return ret;
    }

    function getUserStakeRewards(address userAddr) external view override returns (uint256) {
        return sumList(users[userAddr].stakeRewardsStart);
    }

    function getUserStakeRewardsDetails(address userAddr) external view override returns (Record[] memory) {
        User memory user = users[userAddr];
        uint64 nodeID = user.stakeRewardsStart;
        uint256 count = countList(nodeID);

        Record[] memory ret = new Record[](count);

        copyFromList(nodeID, count, ret, 0);
        return ret;
    }

    function getUserRewardsAt(
        address userAddr,
        uint64 timestamp,
        int256 price,
        uint8 decimals
    ) external view override returns (Record memory) {
        uint64 timeSlot = timeSlotOf(timestamp);
        if (timeSlot > currentTimeSlot()) {
            return Record(0, 0);
        }

        Record memory pool = getPoolStakeAt(timestamp);
        Record memory user = getUserStakeAt(userAddr, timestamp);

        // Trivial case
        if (pool.amount == 0 || user.amount == 0) {
            return Record(0, timeSlot);
        }

        // This is the capped total rewards can be given, if pool stake at that time (in USDC equivalent) >= pool capacity
        // If pool stake does not have so much, total rewards is proportional to pool stake
        // And then rewards of each user is proportional to their stake compared to the whole pool stake
        uint256 maxRewardsPerPeriod = totalAnnualRewards.mul(rewardPeriod).div(365 days);

        // Get the pool size in terms of USDC at that time, no need to do if token to stake is already USDC
        uint256 poolSize = pool.amount;
        if (address(referenceUniswapV3Pool) != address(0)) {
            uint256 tokenDecimals = uint256(ERC20(address(tokenToStake)).decimals());
            poolSize = poolSize.mul(uint256(price)).mul(10**uint256(USDC_DECIMALS)).div(10**(tokenDecimals.add(decimals)));
        }

        if (poolSize >= fixedPoolCapacityUSD) {
            return Record(user.amount.mul(maxRewardsPerPeriod).div(pool.amount), timeSlot);
        } else {
            return Record(user.amount.mul(maxRewardsPerPeriod).mul(poolSize).div(pool.amount.mul(fixedPoolCapacityUSD)), timeSlot);
        }
    }

    function getUserRequestedToRedeem(address userAddr) external view override returns (uint256) {
        return sumList(users[userAddr].redemptionStart);
    }

    function getUserCanRedeemNow(address userAddr) external view override returns (uint256) {
        return sumListUnlocked(users[userAddr].redemptionStart, redeemWaitPeriod);
    }

    function getUserRedemptionDetails(address userAddr) external view override returns (Record[] memory) {
        User memory user = users[userAddr];
        uint64 nodeID = user.redemptionStart;
        uint256 count = countList(nodeID);

        Record[] memory ret = new Record[](count);

        copyFromList(nodeID, count, ret, 0);
        return ret;
    }

    function stakeToken(uint256 amount) external override skipTransferCallback {
        SafeERC20.safeTransferFrom(tokenToStake, msg.sender, address(this), amount);
        _stakeToken(msg.sender, amount);
    }

    function stakeETH() external payable override {
        // Even if the boolean is incorrectly set to true, normal ERC20 probably does not have deposit() and revert anyway
        require(isTokenToStakeWETH, "Not WETH pool");

        uint256 amount = msg.value;
        IWETH(address(tokenToStake)).deposit{value: amount}();
        _stakeToken(msg.sender, amount);
    }

    function _stakeToken(address userAddr, uint256 amount) private {
        require(userAddr != address(0), "Invalid sender");
        require(amount > 0, "Invalid amount");

        User storage ptr = users[userAddr];
        User memory user = ptr;

        if (user.isInList == false) {
            ptr.isInList = true;
            userAddrList.push(userAddr);
        }

        uint256 remainAmount = amount;

        // In this liquidity mining, all tokens go to fixed pool first, until capacity is full
        // Then remaining tokens will go to flexible pool
        // Even after lock period has passed and tokens in fixed pool are redeemed, usage will not be decreased, so no new tokens can go to it anymore
        if (fixedPoolUsageUSD < fixedPoolCapacityUSD) {
            // Usage is calculated in equivalent USD at that time, so same amount of token can have different usage at different time
            // For USD stablecoin, just simply fix it at 1:1
            uint256 equivUSD = toEquivalentUSD(amount);
            uint256 tokenAmount = amount;

            if (fixedPoolUsageUSD.add(equivUSD) > fixedPoolCapacityUSD) {
                equivUSD = fixedPoolCapacityUSD.sub(fixedPoolUsageUSD);
                tokenAmount = toEquivalentToken(equivUSD);
            }

            addFixedStake(userAddr, tokenAmount, equivUSD);
            fixedPoolUsageUSD = fixedPoolUsageUSD.add(equivUSD);
            remainAmount = remainAmount.sub(tokenAmount);
        }

        if (remainAmount > 0) {
            ptr.flexibleStake = user.flexibleStake.add(remainAmount);
            emit StakeToken(userAddr, remainAmount);
        }

        updateHistory(userAddr, amount, true);
    }

    function claimStakeRewards() external override {
        User storage ptr = users[msg.sender];
        User memory user = ptr;
        uint256 amount = 0;
        uint64 nodeID = user.stakeRewardsStart;

        // No need to lock stake rewards, so simply clear the whole list
        while (nodeID != 0) {
            Node memory node = nodes[nodeID];
            delete nodes[nodeID];
            amount = amount.add(node.amount);
            nodeID = node.next;
        }

        require(amount > 0, "No stake rewards can be claimed");

        ptr.stakeRewardsStart = 0;
        ptr.stakeRewardsLast = 0;

        // Rewards can be transferred without any wait period
        SafeERC20.safeTransfer(tokenToReward, msg.sender, amount);
        emit ClaimStakeRewards(msg.sender, amount);
    }

    function requestRedemption(uint256 amount) external override {
        require(amount > 0, "Invalid amount");

        // Always redeem from unlocked fixed stake first, then flexible
        User storage ptr = users[msg.sender];
        User memory user = ptr;
        uint64 _lockPeriod = lockPeriod;
        uint256 remain = amount;
        uint64 nodeID;

        // Find how many tokens can be redeemed from fixed stake
        {
            nodeID = user.stakeStart;

            while (nodeID != 0) {
                Node memory node = nodes[nodeID];

                if ((node.timestamp + _lockPeriod) > block.timestamp) {
                    break;
                }

                if (node.amount > remain) {
                    // Stake is larger than remaining request amount, so just change the stake size and break the loop
                    nodes[nodeID].amount = node.amount.sub(remain);
                    remain = 0;
                    break;
                } else {
                    // The whole stake is requested, remove it from linked list
                    delete nodes[nodeID];
                    remain = remain.sub(node.amount);
                    nodeID = node.next;
                }
            }

            ptr.stakeStart = nodeID;
            if (nodeID == 0) {
                ptr.stakeLast = 0;
            }
        }

        // Then any remaining tokens should be deduced in flexible stake
        require(remain <= user.flexibleStake, "Not enough unlocked tokens");
        ptr.flexibleStake = user.flexibleStake.sub(remain);

        // Add new node to redemption list
        {
            nodeID = newNode(amount);

            if (user.redemptionStart == 0) {
                ptr.redemptionStart = nodeID;
            } else {
                nodes[user.redemptionLast].next = nodeID;
            }

            ptr.redemptionLast = nodeID;
        }

        totalRequestedToRedeem = totalRequestedToRedeem.add(amount);
        updateHistory(msg.sender, amount, false);
        emit RequestRedemption(msg.sender, amount);
    }

    function redeemToken() external override {
        uint256 amount = _redeemToken();
        SafeERC20.safeTransfer(tokenToStake, msg.sender, amount);
    }

    function redeemETH() external override skipTransferCallback {
        // Even if the boolean is incorrectly set to true, normal ERC20 probably does not have withdraw() and revert anyway
        require(isTokenToStakeWETH, "Not WETH pool");

        uint256 amount = _redeemToken();
        IWETH(address(tokenToStake)).withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function _redeemToken() private returns (uint256 amount) {
        User storage ptr = users[msg.sender];
        User memory user = ptr;
        uint64 _redeemWaitPeriod = redeemWaitPeriod;
        amount = 0;

        // Remove nodes from redemption linked list
        {
            uint64 nodeID = user.redemptionStart;

            while (nodeID != 0) {
                Node memory node = nodes[nodeID];

                if ((node.timestamp + _redeemWaitPeriod) > block.timestamp) {
                    break;
                }

                delete nodes[nodeID];
                amount = amount.add(node.amount);
                nodeID = node.next;
            }

            require(amount > 0, "No token can be redeemed");

            ptr.redemptionStart = nodeID;
            if (nodeID == 0) {
                ptr.redemptionLast = 0;
            }
        }

        totalRequestedToRedeem = totalRequestedToRedeem.sub(amount);
        emit RedeemToken(msg.sender, amount);
    }

    function getAllUsers() external view override returns (address[] memory) {
        return userAddrList;
    }

    function setPriceConsultSeconds(uint32 _priceConsultSeconds) external override onlyOwner {
        priceConsultSeconds = _priceConsultSeconds;
    }

    function getWithdrawer() external view override returns (address[] memory) {
        return getMembers(WITHDRAWER_ROLE);
    }

    function grantWithdrawer(address withdrawerAddr) external override onlyOwner {
        grantRole(WITHDRAWER_ROLE, withdrawerAddr);
    }

    function revokeWithdrawer(address withdrawerAddr) external override onlyOwner {
        revokeRole(WITHDRAWER_ROLE, withdrawerAddr);
    }

    function poolDeposit(uint256 amount) external override skipTransferCallback {
        SafeERC20.safeTransferFrom(tokenToStake, msg.sender, address(this), amount);
    }

    function poolWithdraw(uint256 amount) external override onlyWithdrawer {
        // Token is transferred to sender
        SafeERC20.safeTransfer(tokenToStake, msg.sender, amount);
    }

    function getMembers(bytes32 role) private view returns (address[] memory) {
        uint256 count = getRoleMemberCount(role);
        address[] memory members = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            members[i] = getRoleMember(role, i);
        }
        return members;
    }

    function timeSlotOf(uint64 time) internal view returns (uint64) {
        return uint64(uint256(time).div(uint256(rewardPeriod)).mul(uint256(rewardPeriod)));
    }

    function currentTimeSlot() internal view returns (uint64) {
        return uint64(block.timestamp.div(uint256(rewardPeriod)).mul(uint256(rewardPeriod)));
    }

    function nextTimeSlot() internal view returns (uint64) {
        return uint64(block.timestamp.div(uint256(rewardPeriod)).mul(uint256(rewardPeriod))) + rewardPeriod;
    }

    function countList(uint64 nodeStart) private view returns (uint256) {
        uint256 count;
        uint64 nodeID = nodeStart;

        while (nodeID != 0) {
            count++;
            nodeID = nodes[nodeID].next;
        }

        return count;
    }

    function sumList(uint64 nodeStart) private view returns (uint256) {
        uint256 amount = 0;
        uint64 nodeID = nodeStart;

        while (nodeID != 0) {
            Node memory node = nodes[nodeID];
            amount = amount.add(node.amount);
            nodeID = node.next;
        }

        return amount;
    }

    function sumListLocked(uint64 nodeStart, uint64 period) private view returns (uint256) {
        uint256 amount = 0;
        uint64 nodeID = nodeStart;

        while (nodeID != 0) {
            Node memory node = nodes[nodeID];

            if ((node.timestamp + period) > block.timestamp) {
                amount = amount.add(node.amount);
            }

            nodeID = node.next;
        }

        return amount;
    }

    function sumListUnlocked(uint64 nodeStart, uint64 period) private view returns (uint256) {
        uint256 amount = 0;
        uint64 nodeID = nodeStart;

        while (nodeID != 0) {
            Node memory node = nodes[nodeID];

            if ((node.timestamp + period) > block.timestamp) {
                break;
            }

            amount = amount.add(node.amount);
            nodeID = node.next;
        }

        return amount;
    }

    function copyFromList(
        uint64 nodeStart,
        uint256 count,
        Record[] memory array,
        uint256 indexStart
    ) private view {
        uint64 nodeID = nodeStart;
        for (uint256 i = 0; i < count; i++) {
            Node memory n = nodes[nodeID];
            array[i + indexStart] = Record(n.amount, n.timestamp);
            nodeID = n.next;
        }
    }

    function pseudoReferenceTokenAddr() private view returns (address) {
        // Just for OracleLibrary to use, no need to be real address
        return isToken1 ? address(0) : address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    }

    function toEquivalentUSD(uint256 tokenAmount) private view returns (uint256) {
        return toEquivalent(tokenAmount, address(tokenToStake), pseudoReferenceTokenAddr());
    }

    function toEquivalentToken(uint256 usdAmount) private view returns (uint256) {
        return toEquivalent(usdAmount, pseudoReferenceTokenAddr(), address(tokenToStake));
    }

    function toEquivalent(
        uint256 baseAmount,
        address baseToken,
        address quoteToken
    ) private view returns (uint256) {
        // If staking USD stablecoin, no need to get price from Uniswap pool and simply return the same value
        if (address(referenceUniswapV3Pool) == address(0)) {
            return baseAmount;
        }

        int24 tick;
        if (priceConsultSeconds == 0) {
            // consult function in OracleLibrary does not accept seconds == 0
            // In this case directly get the tick from pool
            (, tick, , , , , ) = referenceUniswapV3Pool.slot0();
        } else {
            (tick, ) = OracleLibrary.consult(address(referenceUniswapV3Pool), priceConsultSeconds);
        }

        return OracleLibrary.getQuoteAtTick(tick, uint128(baseAmount), baseToken, quoteToken);
    }

    function newNode(uint256 amount) private returns (uint64) {
        uint64 nodeID = nextNodeID++;
        nodes[nodeID] = Node(amount, 0, 0, uint64(block.timestamp), 0);
        return nodeID;
    }

    function getStakeRewardsAmount(uint256 equivUSD) private pure returns (uint256) {
        // Stake rewards of fixed pool is calculated using equivalent USD value of tokens
        // Stake 1 USD to fixed pool = get 1 MST, however their decimals are different so need to do some conversion
        return equivUSD * 10**uint256(MST_DECIMALS - USDC_DECIMALS);
    }

    function addFixedStake(
        address userAddr,
        uint256 amount,
        uint256 equivUSD
    ) private {
        User storage ptr = users[userAddr];
        User memory user = ptr;
        uint64 nodeID;
        uint256 stakeRewardsAmount = getStakeRewardsAmount(equivUSD);

        // This is the stake node
        {
            nodeID = newNode(amount);

            // InitialStakeAmount does not change when just redeem part of the stake
            nodes[nodeID].initialStakeAmount = amount;

            // Also save stakeRewardsAmount so that user can check the stake rewards received from this stake
            nodes[nodeID].stakeRewardsAmount = stakeRewardsAmount;

            if (user.stakeStart == 0) {
                ptr.stakeStart = nodeID;
            } else {
                nodes[user.stakeLast].next = nodeID;
            }

            ptr.stakeLast = nodeID;
        }

        // This is stake rewards node
        {
            nodeID = newNode(stakeRewardsAmount);

            if (user.stakeRewardsStart == 0) {
                ptr.stakeRewardsStart = nodeID;
            } else {
                nodes[user.stakeRewardsLast].next = nodeID;
            }

            ptr.stakeRewardsLast = nodeID;
        }

        emit StakeToken(userAddr, amount);
        emit FixedPoolStaking(userAddr, amount, equivUSD);
    }

    function updateHistory(
        address userAddr,
        uint256 amount,
        bool isAddAmount
    ) private {
        uint64 _nextTimeSlot = nextTimeSlot();
        uint256 len;
        uint256 newAmount;

        // Update pool history
        {
            len = poolHistory.length;
            History memory history = poolHistory[len - 1];
            newAmount = isAddAmount ? history.amount.add(amount) : history.amount.sub(amount);

            if (history.timestamp == _nextTimeSlot) {
                poolHistory[len - 1].amount = newAmount;
            } else {
                poolHistory.push(History(newAmount, _nextTimeSlot));
            }
        }

        // Update user history
        {
            History[] storage ptr = userHistory[userAddr];
            len = ptr.length;

            if (len == 0) {
                ptr.push(History(0, 0));
                ptr.push(History(amount, _nextTimeSlot));
                return;
            }

            History memory history = ptr[len - 1];
            newAmount = isAddAmount ? history.amount.add(amount) : history.amount.sub(amount);

            if (history.timestamp == _nextTimeSlot) {
                ptr[len - 1].amount = newAmount;
            } else {
                ptr.push(History(newAmount, _nextTimeSlot));
            }
        }
    }

    modifier onlyWithdrawer() {
        require(hasRole(WITHDRAWER_ROLE, msg.sender), "Withdrawer only");
        _;
    }

    modifier onlyAcceptableTokens() {
        // If token uses ERC223 / ERC677 / ERC1363, only accept tokens we are concerning
        require(msg.sender == address(tokenToStake) || msg.sender == address(tokenToReward), "Not acceptable token");
        _;
    }

    modifier skipTransferCallback() {
        directCalling = ENTERED;
        _;
        directCalling = NOT_ENTERED;
    }
}
