// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract DeficliqStaking is AccessControl {
    using SafeMath for uint256;

    string public constant NAME = "Deficliq Staking Contract";
    bytes32 public constant REWARD_PROVIDER = keccak256("REWARD_PROVIDER"); // i upgraded solc and used REWARD_PROVIDER instead of whitelist role and DEFAULT_ADMIN_ROLE instead of whiteloist admin
    uint256 private constant TIME_UNIT = 86400;
    // we can improve this with a "unstaked:false" flag when the user force withdraws the funds
    // so he can collect the reward later
    struct Stake {
        uint256 _amount;
        uint256 _timestamp;
        bytes32 _packageName;
        uint256 _withdrawnTimestamp;
        uint16 _stakeRewardType; // 0 for native coin reward, 1 for CLIQ stake reward
    }

    struct YieldType {
        bytes32 _packageName;
        uint256 _daysLocked;
        uint256 _daysBlocked;
        uint256 _packageInterest;
        uint256 _packageCliqReward; // the number of cliq token received for each native token staked
    }

    IERC20 public tokenContract;
    IERC20 public CLIQ;

    bytes32[] public packageNames;
    uint256 decimals = 18;
    mapping(bytes32 => YieldType) public packages;
    mapping(address => uint256) public totalStakedBalance;
    mapping(address => Stake[]) public stakes;
    mapping(address => bool) public hasStaked;
    address private owner;
    address[] stakers;
    uint256 rewardProviderTokenAllowance = 0;
    uint256 public totalStakedFunds = 0;
    uint256 cliqRewardUnits = 1000000; // ciq reward for 1.000.000 tokens staked
    bool public paused = false;

    event NativeTokenRewardAdded(address indexed _from, uint256 _val);
    event NativeTokenRewardRemoved(address indexed _to, uint256 _val);
    event StakeAdded(
        address indexed _usr,
        bytes32 _packageName,
        uint256 _amount,
        uint16 _stakeRewardType,
        uint256 _stakeIndex
    );
    event Unstaked(address indexed _usr, uint256 stakeIndex);
    event ForcefullyWithdrawn(address indexed _usr, uint256 stakeIndex);
    event Paused();
    event Unpaused();

    modifier onlyRewardProvider() {
        require(
            hasRole(REWARD_PROVIDER, _msgSender()),
            "caller does not have the REWARD_PROVIDER role"
        );
        _;
    }

    modifier onlyMaintainer() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "caller does not have the Maintainer role"
        );
        _;
    }

    constructor(address _stakedToken, address _CLIQ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenContract = IERC20(_stakedToken);
        CLIQ = IERC20(_CLIQ);
        //define packages here
        _definePackage("Silver Package", 45, 45, 5198950, 0); // in 30 days you receive: 1.740084% of staked token OR 0 cliq for 1 token staked || 6 decimals
        _definePackage("Gold Package", 60, 60, 8148374, 0); // 0 cliq for 1 token staked
        _definePackage("Platinum Package", 90, 90, 15829218, 0); // 0 cliq for 1 token staked
    }

    function stakesLength(address _address) external view returns (uint256) {
        return stakes[_address].length;
    }

    function packageLength() external view returns (uint256) {
        return packageNames.length;
    }

    function stakeTokens(
        uint256 _amount,
        bytes32 _packageName,
        uint16 _stakeRewardType
    ) public {
        require(paused == false, "Staking is  paused");
        require(_amount > 0, " stake a positive number of tokens ");
        require(
            packages[_packageName]._daysLocked > 0,
            "there is no staking package with the declared name, or the staking package is poorly formated"
        );
        require(
            _stakeRewardType == 0 || _stakeRewardType == 1,
            "reward type not known: 0 is native token, 1 is CLIQ"
        );

        //add to stake sum of address
        totalStakedBalance[msg.sender] = totalStakedBalance[msg.sender].add(
            _amount
        );

        //add to stakes
        Stake memory currentStake;
        currentStake._amount = _amount;
        currentStake._timestamp = block.timestamp;
        currentStake._packageName = _packageName;
        currentStake._stakeRewardType = _stakeRewardType;
        currentStake._withdrawnTimestamp = 0;
        stakes[msg.sender].push(currentStake);

        //if user is not declared as a staker, push him into the staker array
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //update the bool mapping of past and current stakers
        hasStaked[msg.sender] = true;
        totalStakedFunds = totalStakedFunds.add(_amount);

        //transfer from (need allowance)
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        StakeAdded(
            msg.sender,
            _packageName,
            _amount,
            _stakeRewardType,
            stakes[msg.sender].length - 1
        );
    }

    function checkStakeReward(address _address, uint256 stakeIndex)
        public
        view
        returns (uint256 yieldReward, uint256 timeDiff)
    {
        require(
            stakes[_address][stakeIndex]._stakeRewardType == 0,
            "use checkStakeCliqReward for stakes accumulating reward in CLIQ if available"
        );

        uint256 currentTime = block.timestamp;
        if (stakes[_address][stakeIndex]._withdrawnTimestamp != 0) {
            currentTime = stakes[_address][stakeIndex]._withdrawnTimestamp;
        }

        uint256 stakingTime = stakes[_address][stakeIndex]._timestamp;
        uint256 daysLocked =
            packages[stakes[_address][stakeIndex]._packageName]._daysLocked;
        uint256 packageInterest =
            packages[stakes[_address][stakeIndex]._packageName]
                ._packageInterest;

        timeDiff = currentTime.sub(stakingTime).div(TIME_UNIT);

        uint256 yieldPeriods = timeDiff.div(daysLocked); 
        yieldReward = 0;
        uint256 totalStake = stakes[_address][stakeIndex]._amount;

        // for each period of days defined in the package, compound the interest
        while (yieldPeriods > 0) {
            uint256 currentReward =
                totalStake.mul(packageInterest).div(100000000); //6 decimals to package interest percentage

            totalStake = totalStake.add(currentReward);

            yieldReward = yieldReward.add(currentReward);

            yieldPeriods--;
        }
    }

    // function checkStakeCliqReward(address _address, uint256 stakeIndex)
    //     public
    //     view
    //     returns (uint256 yieldReward, uint256 timeDiff)
    // {
    //     require(
    //         stakes[_address][stakeIndex]._stakeRewardType == 1,
    //         "use checkStakeReward for stakes accumulating reward in the Native Token"
    //     );

    //     uint256 currentTime = block.timestamp;
    //     if (stakes[_address][stakeIndex]._withdrawnTimestamp != 0) {
    //         currentTime = stakes[_address][stakeIndex]._withdrawnTimestamp;
    //     }

    //     uint256 stakingTime = stakes[_address][stakeIndex]._timestamp;
    //     uint256 daysLocked =
    //         packages[stakes[_address][stakeIndex]._packageName]._daysLocked;
    //     uint256 packageCliqInterest =
    //         packages[stakes[_address][stakeIndex]._packageName]
    //             ._packageCliqReward;

    //     timeDiff = currentTime.sub(stakingTime).div(TIME_UNIT);

    //     uint256 yieldPeriods = timeDiff.div(daysLocked);

    //     yieldReward = stakes[_address][stakeIndex]._amount.mul(
    //         packageCliqInterest
    //     );

    //     yieldReward = yieldReward.div(cliqRewardUnits);

    //     yieldReward = yieldReward.mul(yieldPeriods);
    // }

    function unstake(uint256 stakeIndex) public {
        require(
            stakeIndex < stakes[msg.sender].length,
            "The stake you are searching for is not defined"
        );
        require(
            stakes[msg.sender][stakeIndex]._withdrawnTimestamp == 0,
            "Stake already withdrawn"
        );

        // decrease total balance
        totalStakedFunds = totalStakedFunds.sub(
            stakes[msg.sender][stakeIndex]._amount
        );

        //decrease user total staked balance
        totalStakedBalance[msg.sender] = totalStakedBalance[msg.sender].sub(
            stakes[msg.sender][stakeIndex]._amount
        );

        //close the staking package (fix the withdrawn timestamp)
        stakes[msg.sender][stakeIndex]._withdrawnTimestamp = block.timestamp;

        if (stakes[msg.sender][stakeIndex]._stakeRewardType == 0) {
            (uint256 reward, uint256 daysSpent) =
                checkStakeReward(msg.sender, stakeIndex);

            require(
                rewardProviderTokenAllowance > reward,
                "Token creators did not place enough liquidity in the contract for your reward to be paid"
            );

            require(
                daysSpent >
                    packages[stakes[msg.sender][stakeIndex]._packageName]
                        ._daysBlocked,
                "cannot unstake sooner than the blocked time time"
            );

            rewardProviderTokenAllowance = rewardProviderTokenAllowance.sub(
                reward
            );

            uint256 totalStake =
                stakes[msg.sender][stakeIndex]._amount.add(reward);

            tokenContract.transfer(msg.sender, totalStake);
        }
        // else if (stakes[msg.sender][stakeIndex]._stakeRewardType == 1) {
        //     (uint256 cliqReward, uint256 daysSpent) =
        //         checkStakeCliqReward(msg.sender, stakeIndex);
        //     require(
        //         CLIQ.balanceOf(address(this)) >= cliqReward,
        //         "the isn't enough CLIQ in this contract to pay your reward right now"
        //     );
        //     require(
        //         daysSpent >
        //             packages[stakes[msg.sender][stakeIndex]._packageName]
        //                 ._daysBlocked,
        //         "cannot unstake sooner than the blocked time time"
        //     );
        //     CLIQ.transfer(msg.sender, cliqReward);
        //     tokenContract.transfer(
        //         msg.sender,
        //         stakes[msg.sender][stakeIndex]._amount
        //     );
        // }
        else {
            revert();
        }

        emit Unstaked(msg.sender, stakeIndex);
    }

    function forceWithdraw(uint256 stakeIndex) public {
        require(
            stakes[msg.sender][stakeIndex]._amount > 0,
            "The stake you are searching for is not defined"
        );
        require(
            stakes[msg.sender][stakeIndex]._withdrawnTimestamp == 0,
            "Stake already withdrawn"
        );

        stakes[msg.sender][stakeIndex]._withdrawnTimestamp = block.timestamp;
        totalStakedFunds = totalStakedFunds.sub(
            stakes[msg.sender][stakeIndex]._amount
        );
        totalStakedBalance[msg.sender] = totalStakedBalance[msg.sender].sub(
            stakes[msg.sender][stakeIndex]._amount
        );

        uint256 daysSpent =
            block.timestamp.sub(stakes[msg.sender][stakeIndex]._timestamp).div(
                TIME_UNIT
            ); //86400

        require(
            daysSpent >
                packages[stakes[msg.sender][stakeIndex]._packageName]
                    ._daysBlocked,
            "cannot unstake sooner than the blocked time time"
        );

        tokenContract.transfer(
            msg.sender,
            stakes[msg.sender][stakeIndex]._amount
        );

        emit ForcefullyWithdrawn(msg.sender, stakeIndex);
    }

    function pauseStaking() public onlyMaintainer {
        paused = true;
        emit Paused();
    }

    function unpauseStaking() public onlyMaintainer {
        paused = false;
        emit Unpaused();
    }

    function addStakedTokenReward(uint256 _amount)
        public
        onlyRewardProvider
        returns (bool)
    {
        //transfer from (need allowance)
        rewardProviderTokenAllowance = rewardProviderTokenAllowance.add(
            _amount
        );
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        emit NativeTokenRewardAdded(msg.sender, _amount);
        return true;
    }

    function removeStakedTokenReward(uint256 _amount)
        public
        onlyRewardProvider
        returns (bool)
    {
        require(
            _amount <= rewardProviderTokenAllowance,
            "you cannot withdraw this amount"
        );
        rewardProviderTokenAllowance = rewardProviderTokenAllowance.sub(
            _amount
        );
        tokenContract.transfer(msg.sender, _amount);
        emit NativeTokenRewardRemoved(msg.sender, _amount);
        return true;
    }

    function _definePackage(
        bytes32 _name,
        uint256 _days,
        uint256 _daysBlocked,
        uint256 _packageInterest,
        uint256 _packageCliqReward
    ) private {
        YieldType memory package;
        package._packageName = _name;
        package._daysLocked = _days;
        package._packageInterest = _packageInterest;
        package._packageCliqReward = _packageCliqReward;
        package._daysBlocked = _daysBlocked;
        packages[_name] = package;
        packageNames.push(_name);
    }
}
