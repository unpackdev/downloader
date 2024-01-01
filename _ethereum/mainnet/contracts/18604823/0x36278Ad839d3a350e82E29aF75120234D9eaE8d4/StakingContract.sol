//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import "./console.sol";
import "./INFTContract.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract StakingContract is Ownable {

    event Staked(uint256[] ids, address owner);
    event Unstaked(uint256[] ids, address owner);
    event Halved(uint256 newRewardsPerBlock, address operator);
    event Claimed(address owner, uint256 amount);

    uint256 constant startingRewardPerBlock = 50 * 10 ** 18;
    uint256 constant halvingInterval = 2100000;
    uint256 constant thresholdHR = 21000;

    INFTContract immutable nftProvider;
    IERC20 immutable token;
    address operator;

    mapping(uint256 => uint256) totalRewardPerHRatBlock;

    mapping(uint256 => address) public owners;
    mapping(uint256 => uint256) startBlock;
    mapping(uint256 => uint256) hrs;

    mapping(address => uint256) public userHR;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) rewardAcc;
    mapping(address => uint256) lastUpdateBlock;

    uint256 public currentActiveHR;
    uint256 public currentRewardsPerBlock;
    uint256 public nextHalvingTS;

    mapping(address => int256) public nftAmounts;

    int256 public nftStaked;
    uint256 public uniqStakers;
    uint256 public totalClaimed;

    uint256 lastChangedRewardBlock;
    uint256 totalMintedintedBeforeHalving;

    uint256 currentRewardsPerBHR;
    uint256 lastProcessedBlock;
    uint256 tokenBalance;

    constructor(
        address _initialOwner,
        address _nftProvider,
        address _token
    ) Ownable(_initialOwner) {
        token = IERC20(_token);
        nftProvider = INFTContract(_nftProvider);
        tokenBalance = token.balanceOf(address(this));
    }

    function getEarnedByVMM(uint256 id) public view returns (uint256) {
        return hrs[id] * (_currentTotalPerHR() - totalRewardPerHRatBlock[startBlock[id]]);
    }

    function getAvailableForClaim(address user) public view returns (uint256) {
        return getTotalReward(user) - getClaimed(user);
    }

    function getClaimed(address user) public view returns (uint256) {
        return claimed[user];
    }

    function getTotalReward(address user) public view returns (uint256) {
        return rewardAcc[user] + userHR[user] * (_currentTotalPerHR() - totalRewardPerHRatBlock[lastUpdateBlock[user]]);
    }

    function getAverageRewardPerBlock(address user) public view returns (uint256){
        uint256 bn = block.number;
        uint256 delta = bn - lastProcessedBlock;
        uint256 balance = token.balanceOf(address(this));
        uint256 feeIncome = balance - tokenBalance;
        return (userHR[user] * currentRewardsPerBHR) + (userHR[user] * feeIncome) / (delta * currentActiveHR);
    }

    function getMinted() public view returns (uint256){
        return totalMintedintedBeforeHalving + (block.number - lastChangedRewardBlock) * currentRewardsPerBlock;
    }

    function getRemainingBlockReward() public view returns (uint256){
        return 2 * startingRewardPerBlock * halvingInterval - getMinted();
    }

    function claim() public {
        address user = msg.sender;
        _updateRewards();
        _updateUser(user, 0);
        uint256 amount = rewardAcc[user] - claimed[user];
        claimed[user] += amount;
        totalClaimed += amount;
        tokenBalance -= amount;
        token.transfer(user, amount);
        emit Claimed(user, amount);
    }

    function stake(uint256[] memory ids) public {
        address receiver = nftProvider.ownerOf(ids[0]);
        require(
            receiver == msg.sender || operator == msg.sender,
            "E01: Only owner or operator allowed to stake"
        );
        uint8 len = uint8(ids.length);
        uint256 totalHR;
        uint256 bn = block.number;

        _updateRewards();
        _updateUser(receiver, int8(len));

        for (uint8 i = 0; i < len; ++i) {
            uint256 id = ids[i];
            address nftOwner = nftProvider.ownerOf(id);
            require(
                nftOwner == receiver,
                "E02: All VMMs staked within one request should have same owner"
            );
            require(startBlock[id] == 0, "E03: VMM already staked");
            owners[id] = nftOwner;
            uint256 hr = nftProvider.nftHashrate(id);
            totalHR += hr;
            hrs[id] = hr;
            startBlock[id] = bn;
        }

        userHR[receiver] += totalHR;
        uint256 newHR = currentActiveHR + totalHR;
        if ((currentRewardsPerBlock == 0) && (newHR >= thresholdHR)) {
            currentRewardsPerBlock = startingRewardPerBlock;
            nextHalvingTS = bn + halvingInterval;
            lastChangedRewardBlock = bn;
        }
        currentActiveHR = newHR;
        currentRewardsPerBHR = currentRewardsPerBlock / newHR;

        emit Staked(ids, receiver);
    }

    function unstake(uint256[] memory ids) public {
        address staker = owners[ids[0]];
        require(
            staker == msg.sender || operator == msg.sender,
            "E04: Only owner or operator allowed to unstake"
        );
        uint8 len = uint8(ids.length);
        uint256 totalHR;

        _updateRewards();
        _updateUser(staker, - int8(len));

        for (uint8 i = 0; i < len; ++i) {
            uint256 id = ids[i];
            require(startBlock[id] != 0, "E05: VMM is not staked");
            require(owners[id] == staker, "E06: All VMMs unstaked within one request should have same owner");
            totalHR += hrs[id];
            startBlock[id] = 0;
            hrs[id] = 0;
            owners[id] = address(0);
        }

        userHR[staker] -= totalHR;
        uint256 updatedActiveHR = currentActiveHR - totalHR;
        require(updatedActiveHR > 0, "E07: Last VMM could not be unstaked");
        currentActiveHR = updatedActiveHR;
        currentRewardsPerBHR = currentRewardsPerBlock / updatedActiveHR;

        emit Unstaked(ids, staker);
    }

    function restakeOnSell(uint256 id, address newOwner) public {
        require(startBlock[id] != 0, "E08: VMM is not staked");
        require(
            operator == msg.sender,
            "E09: Only operator allowed to restake"
        );

        _updateRewards();
        address nftOwner = owners[id];
        uint256 bn = block.number;
        uint256 hr = hrs[id];

        _updateUser(newOwner, 1);
        _updateUser(nftOwner, - 1);

        startBlock[id] = bn;

        userHR[nftOwner] -= hr;
        userHR[newOwner] += hr;

        owners[id] = newOwner;

        uint256[] memory t = new uint256[](1);
        t[0] = id;
        emit Unstaked(t, nftOwner);
        emit Staked(t, newOwner);
    }

    function halve() public {
        if ((block.number > nextHalvingTS) && (currentRewardsPerBlock != 0)) {
            _updateRewards();
            totalMintedintedBeforeHalving += (block.number - lastChangedRewardBlock) * currentRewardsPerBlock;
            lastChangedRewardBlock = block.number;
            nextHalvingTS = block.number + halvingInterval;
            currentRewardsPerBlock = currentRewardsPerBlock / 2;
            currentRewardsPerBHR = currentRewardsPerBlock / currentActiveHR;
            emit Halved(currentRewardsPerBlock, msg.sender);
        }
    }

    function setOperator(address _operator) public {
        _checkOwner();
        operator = _operator;
    }

    function _currentTotalPerHR() private view returns (uint256) {
        return
            totalRewardPerHRatBlock[lastProcessedBlock] +
            ((block.number - lastProcessedBlock) * currentRewardsPerBHR) +
            ((token.balanceOf(address(this)) - tokenBalance) / currentActiveHR);
    }

    function _updateRewards() private {
        unchecked {
            uint256 bn = block.number;
            uint256 delta = bn - lastProcessedBlock;
            uint256 balance = token.balanceOf(address(this));
            uint256 feeIncome = balance - tokenBalance;
            uint256 _currentActiveHR = currentActiveHR;
            uint256 feePerHR;
        // solhint-disable-next-line no-inline-assembly
            assembly {
            // black Solidity magic :)
                feePerHR := div(feeIncome, _currentActiveHR)
            }
            uint256 totalReward = totalRewardPerHRatBlock[lastProcessedBlock] +
                delta *
                currentRewardsPerBHR +
                        feePerHR;
            totalRewardPerHRatBlock[bn] = totalReward;
            lastProcessedBlock = bn;
            tokenBalance = balance;
        }
    }

    function _updateUser(address user, int8 amount) private {

        uint256 bn = block.number;
        rewardAcc[user] +=
            userHR[user] *
            (totalRewardPerHRatBlock[bn] -
                totalRewardPerHRatBlock[lastUpdateBlock[user]]);
        lastUpdateBlock[user] = bn;
        if (amount != 0) {
            nftStaked += amount;
            int256 oldAmount = nftAmounts[user];
            int256 newAmount = oldAmount + amount;
            if (oldAmount == 0) {
                ++uniqStakers;
            } else if (newAmount == 0) {
                --uniqStakers;
            }
            nftAmounts[user] = newAmount;
        }
    }
}
