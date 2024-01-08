// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./ISupportingExternalReflection.sol";
import "./IAutomatedExternalReflector.sol";
import "./Ownable.sol";
import "./LockableSwap.sol";

abstract contract  AutomatedExternalReflector is Context, LockableSwap, Ownable, IAutomatedExternalReflector {
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event TransactionRegistered(address indexed sender, address indexed recipient);
    event AirdropDelivered(uint256 numberOfPayouts, uint256 totalAmount, uint256 indexAt);
    event RoundSnapshotTaken(uint256 totalUsersUpdated);

    struct User {
        uint256 tokenBalance;
        uint256 totalPayouts;
        uint256 pendingPayouts;
        bool exists;
        uint256 lastPayoutRound;
    }

    mapping(uint256 => uint256) public poolForRound;

    uint256 public currentRound;
    uint256 internal totalEthDeposits;
    uint256 public currentQueueIndex;
    uint256 internal totalRewardsSent;
    uint256 public totalCirculatingTokens;
    uint256 public totalExcludedTokenHoldings = 0;

    bool public takeSnapshot = true;
    bool public snapshotPending;

    uint256 public maxGas;
    uint256 public minGas;
    uint256 public gasRequirement = 75000;
    uint256 public maxReflectionsPerRound;
    uint256 public timeBetweenRounds;
    uint256 public nextRoundStart;

    bool public reflectionsEnabled = true;

    IUniswapV2Router02 public uniswapV2Router;
    ISupportingExternalReflection public tokenContract;
    EnumerableSet.AddressSet private excludedList;

    EnumerableSet.AddressSet private privateQueue;
    address payable[] internal queue;

    mapping(address => mapping(uint256 => User)) internal dynaHodler;
    mapping(address => bool) public override isExcludedFromReflections;

    receive() external payable {
        totalEthDeposits = totalEthDeposits.add(msg.value);
    }

    fallback() external payable {
        totalEthDeposits = totalEthDeposits.add(msg.value);
    }

    function depositEth() public payable override returns(bool success) {
        totalEthDeposits = totalEthDeposits.add(msg.value);
        success = true;
    }

    function addNewUser(address newUserAddress, uint256 bal) private {
        dynaHodler[newUserAddress][currentRound+1] = User(bal, 0, 0, true, currentRound);
        dynaHodler[newUserAddress][currentRound] = User(bal, 0, 0, true, currentRound);
    }

    function logTransactionEvent(address from, address to) external override returns (bool) {
        require(_msgSender() == _owner || _msgSender() == address(tokenContract), "Only Owner or Token Contract may call this function");
        if(from != address(0)) {
            (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSignature("balanceOf(address)",from));
            if(success){
                uint256 bal = abi.decode(data, (uint256));
                logUserTransaction(from, bal, true);
            }
        }
        if(to != address(0)) {
            (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSignature("balanceOf(address)",to));
            if(success){
                uint256 bal = abi.decode(data, (uint256));
                logUserTransaction(to, bal, false);
            }
        }

        emit TransactionRegistered(from, to);
        return true;
    }

    function logUserTransaction(address user, uint256 value, bool isSender) private {
        if(!privateQueue.contains(user)){
            privateQueue.add(user);
            queue.push(payable(user));
        }
        // Dont double up and waste gas if snapshotting is enabled.
        if(takeSnapshot) { return; }
        uint256 prevUserBal = dynaHodler[user][currentRound].tokenBalance;

        dynaHodler[user][currentRound+1] = User({
            tokenBalance: value,
            totalPayouts: dynaHodler[user][currentRound].totalPayouts,
            pendingPayouts: dynaHodler[user][currentRound].pendingPayouts,
            exists: true,
            lastPayoutRound: dynaHodler[user][currentRound].lastPayoutRound
        });

        if(isExcludedFromReflections[user]){
            if(isSender){
                totalExcludedTokenHoldings = totalExcludedTokenHoldings.sub(prevUserBal.sub(value));
            } else {
                totalExcludedTokenHoldings = totalExcludedTokenHoldings.add(value.sub(prevUserBal));
            }
        }
    }

    function reflectRewards() external override returns (bool) {
        require(gasleft() > gasRequirement, "More gas is required for this function");
        if(!inSwapAndLiquify)
            return _reflectRewards();
        return false;
    }

    function snapshot() private returns (uint256){
        uint256 stopProcessingAt = currentQueueIndex.add(maxReflectionsPerRound);
        uint256 queueLength = queue.length;
        uint256 startingGas = gasleft();
        uint256 endGas = 0;
        uint256 queueStart = currentQueueIndex;
        uint256 gasLeft = startingGas;
        if(startingGas > maxGas){
            endGas = startingGas.sub(maxGas);
        } else {
            endGas = minGas;
        }
        uint256 minGasIncReturns = minGas.div(2).add(minGas);
        IERC20 controllingToken = IERC20(address(tokenContract));
        uint256 excludedTokensSnapshotted;
        if(currentQueueIndex == 0){
            excludedTokensSnapshotted = 0;
        } else {
            excludedTokensSnapshotted = totalExcludedTokenHoldings;
        }
        while(gasLeft > minGasIncReturns && gasLeft > endGas && currentQueueIndex < stopProcessingAt && currentQueueIndex < queueLength){
            address payable user = queue[currentQueueIndex];
            (bool success, bytes memory data) = address(controllingToken).call(abi.encodeWithSignature("balanceOf(address)",user));
            if(success){
                uint256 bal = abi.decode(data, (uint256));
                dynaHodler[user][currentRound] = User({
                    tokenBalance: bal,
                    totalPayouts: dynaHodler[user][currentRound-1].totalPayouts,
                    pendingPayouts: dynaHodler[user][currentRound-1].pendingPayouts,
                    exists: true,
                    lastPayoutRound: dynaHodler[user][currentRound-1].lastPayoutRound
                });

                dynaHodler[user][currentRound+1] = dynaHodler[user][currentRound];

                if(isExcludedFromReflections[queue[currentQueueIndex]]){
                    excludedTokensSnapshotted = excludedTokensSnapshotted.add(bal);
                }
            }
            currentQueueIndex++;
        }
        emit RoundSnapshotTaken(currentQueueIndex.sub(queueStart));

        rewardInstigator(currentQueueIndex.sub(queueStart));

        if(currentQueueIndex >= queueLength){
            currentQueueIndex = 0;
            snapshotPending = false;
        }
        return excludedTokensSnapshotted;
    }

    function rewardInstigator(uint256 shares) private {
        if(address(this).balance > poolForRound[currentRound].add(1000)){
            // Reward initiator of this call some eth for their gas contribution.
            uint256 instigatorReward = address(this).balance.sub(poolForRound[currentRound]);

            if(instigatorReward > 1000 && tx.origin != address(uniswapV2Router)){
                instigatorReward = instigatorReward.mul(shares).div(1000);
                payable(address(tx.origin)).call{value: instigatorReward}("");
            }
        }
    }

    function _reflectRewards() private lockTheSwap returns(bool allComplete) {
        allComplete = false;
        if(takeSnapshot && snapshotPending){
            if(currentQueueIndex == 0){ totalExcludedTokenHoldings = 0; }
            uint256 newExcludedTally = snapshot();
            if(newExcludedTally != 0 && newExcludedTally != totalExcludedTokenHoldings)
                totalExcludedTokenHoldings = totalExcludedTokenHoldings.add(newExcludedTally);

            return allComplete;
        }

        if(block.timestamp < nextRoundStart || address(this).balance == 0){
            return allComplete;
        }

        uint256 stopProcessingAt = currentQueueIndex.add(maxReflectionsPerRound);
        uint256 queueLength = queue.length;
        uint256 payeeCount = 0;
        uint256 payeeAmount = 0;
        uint256 startingGas = gasleft();
        uint256 endGas = 0;
        uint256 gasLeft = startingGas;
        if(startingGas > maxGas){
            endGas = startingGas.sub(maxGas);
        } else {
            endGas = minGas;
        }
        uint256 minGasIncReturns = minGas.div(2).add(minGas);

        while(gasLeft > minGasIncReturns && gasLeft > endGas && currentQueueIndex < stopProcessingAt && currentQueueIndex < queueLength){
            address payable hodler = payable(queue[currentQueueIndex]);
            payeeAmount = payeeAmount.add(_sendEthTo(hodler));
            payeeCount++;
            currentQueueIndex++;
            gasLeft = gasleft();
        }

        rewardInstigator(payeeCount);

        if(currentQueueIndex >= queueLength || poolForRound[currentRound] == 0){
            currentQueueIndex = 0;
            allComplete = true;
            nextRoundStart = block.timestamp.add(timeBetweenRounds);
            currentRound++;
            poolForRound[currentRound] = address(this).balance;
            if(takeSnapshot){
                snapshotPending = true;
            }
        }
        totalRewardsSent = totalRewardsSent.add(payeeAmount);
        emit AirdropDelivered(payeeCount, payeeAmount, currentQueueIndex);
    }

    function enableSnapshotting(bool enable) external onlyOwner {
        takeSnapshot = enable;
    }

    function _sendEthTo(address payable hodler) private returns(uint256 reward) {
        if(!dynaHodler[hodler][currentRound].exists || dynaHodler[hodler][currentRound].tokenBalance == 0) { return 0; }
        if(dynaHodler[hodler][currentRound].lastPayoutRound == currentRound || isExcludedFromReflections[hodler]){ return 0; }

        reward = reward.add(simplePayoutCalc(hodler));
        if (reward > 1000) {
            (bool success, ) = hodler.call{value: reward}("");
            if (success){
                dynaHodler[hodler][currentRound].totalPayouts = dynaHodler[hodler][currentRound].totalPayouts.add(reward);
                dynaHodler[hodler][currentRound+1].totalPayouts = dynaHodler[hodler][currentRound].totalPayouts;
                dynaHodler[hodler][currentRound].lastPayoutRound = currentRound;
                dynaHodler[hodler][currentRound+1].lastPayoutRound = currentRound;
            } else { reward = 0; }
        }
        return reward;
    }

    function simplePayoutCalc(address hodler) private view returns (uint256) {
        return poolForRound[currentRound].mul(dynaHodler[hodler][currentRound].tokenBalance).div(totalCirculatingTokens.sub(totalExcludedTokenHoldings));
    }

    function getRemainingPayeeCount() external view override returns(uint256 count) {
        count = queue.length.sub(currentQueueIndex);
    }

    function enableReflections(bool enable) public override onlyOwner {
        require(enable != reflectionsEnabled, "Reflections already set to this value");
        reflectionsEnabled = enable;
    }

    function _excludeFromReflections(address target, bool exclude) internal {
        isExcludedFromReflections[target] = exclude;
        if(!privateQueue.contains(target)){
            privateQueue.add(target);
            queue.push(payable(target));
        }
        if(exclude){
            excludedList.add(target);
        } else {
            excludedList.remove(target);
        }
    }

    function excludeFromReflections(address target, bool exclude) public override onlyOwner {
        _excludeFromReflections(target, exclude);
    }

    function updateTokenAddress(address token, bool andPair) public onlyOwner {
        tokenContract = ISupportingExternalReflection(token);
        _excludeFromReflections(token, true);
        if(andPair){
            address pair = address(IUniswapV2Factory(uniswapV2Router.factory()).getPair(token, uniswapV2Router.WETH()));
            _excludeFromReflections(pair, true);
        }
        totalCirculatingTokens = IERC20(token).totalSupply();
    }

    function updateTotalSupply(uint256 newTotal) public override {
        require(_msgSender() == _owner || _msgSender() == address(tokenContract), "Only Owner or Token Contract may call this function");
        _updateTotalSupply(newTotal);
    }

    function _updateTotalSupply(uint256 newTotal) private {
        totalCirculatingTokens = newTotal;
    }

    function updateGasRange(uint256 _minGas, uint256 _maxGas) public onlyOwner {
        minGas = _minGas;
        maxGas = _maxGas;
    }

    function updateMaxPayoutsPerTransaction(uint256 roundLimit) external onlyOwner {
        require(roundLimit > 0, "Payout cap must be greater than one");
        maxReflectionsPerRound = roundLimit;
    }

    function updateDelayBetweenRounds(uint256 delayInMinutes) external onlyOwner {
        timeBetweenRounds = delayInMinutes * 1 minutes;
    }

    function enrollAddress(address hodlerAddress) external {
        if(!privateQueue.contains(hodlerAddress)){
            privateQueue.add(hodlerAddress);
            queue.push(payable(hodlerAddress));
        }
    }

    function enrollMultiple(address[] memory addressList) external {
        for(uint256 i = 0; i < addressList.length; i++){
            if(!privateQueue.contains(addressList[i])){
                privateQueue.add(addressList[i]);
                queue.push(payable(addressList[i]));
            }
        }
    }

    function ethSentToUserSoFar(address userAddress) external view returns(uint256) {
        return dynaHodler[userAddress][currentRound].totalPayouts.div(1 ether);
    }

    function totalEthAirdropped() external view returns(uint256){
        return totalRewardsSent.div(1 ether);
    }

    function amIEnrolledForETHDrops() external view returns(bool){
        return isAddressEnrolled(_msgSender());
    }

    function isAddressEnrolled(address ad) public view returns(bool){
        return privateQueue.contains(ad);
    }

    function collectShare() external lockTheSwap {
        _sendEthTo(payable(_msgSender()));
    }
}
