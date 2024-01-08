// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./LPFarm.sol";
import "./Ownable.sol";
import "./IRewardDistributionRecipientTokenOnly.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract FarmController is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    // constant does not occupy the storage slot
    address public constant stakerReward = 0x1337DEF1B1Ae35314b40e5A4b70e216A499b0E37;

    address public constant borrowerReward = 0x1337DEF172152f2fF82d9545Fd6f79fE38dF15ce;

    uint256 public constant INITIAL_DISTRIBUTED = 1638687600;

    IRewardDistributionRecipientTokenOnly[] public farms;
    mapping(address => address) public lpFarm;
    mapping(address => uint256) public rate;
    uint256 public weightSum;
    IERC20 public rewardToken;

    mapping(address => bool) public blackListed;

    // rewards
    uint256 public lastRewardDistributed;

    uint256 public lpRewards;

    uint256 public stakerRewards;

    uint256 public borrowerRewards;

    function initialize(address token) external {
        Ownable.initializeOwnable();
        rewardToken = IERC20(token);
    }

    function addFarm(address _lptoken) external onlyOwner returns(address farm){
        require(lpFarm[_lptoken] == address(0), "farm exist");
        bytes memory bytecode = type(LPFarm).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_lptoken));
        assembly {
            farm := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        LPFarm(farm).initialize(_lptoken, address(this));
        farms.push(IRewardDistributionRecipientTokenOnly(farm));
        rewardToken.approve(farm, uint256(-1));
        lpFarm[_lptoken] = farm;
        // it will just set the rates to zero before it get's it's own rate
    }

    function setRates(uint256[] memory _rates) external onlyOwner {
        require(_rates.length == farms.length);
        uint256 sum = 0;
        for(uint256 i = 0; i<_rates.length; i++){
            sum += _rates[i];
            rate[address(farms[i])] = _rates[i];
        }
        weightSum = sum;
    }

    function setRateOf(address _farm, uint256 _rate) external onlyOwner {
        weightSum -= rate[_farm];
        weightSum += _rate;
        rate[_farm] = _rate;
    }

    function setRewards(uint256 _lpRewards, uint256 _stakerRewards, uint256 _borrowerRewards) external onlyOwner {
        // deposit armor before this
        lpRewards = _lpRewards;
        stakerRewards = _stakerRewards;
        borrowerRewards = _borrowerRewards;
    }

    function withdrawToken(address _token) external onlyOwner {
        //withdraw can disable the rewards
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function initializeRewardDistribution() external onlyOwner {
        require(lastRewardDistributed == 0, "initialized");
        lastRewardDistributed = INITIAL_DISTRIBUTED;
    }

    function flushRewards() external {
        require(block.timestamp >= lastRewardDistributed + 7 days, "wait");
        IRewardDistributionRecipientTokenOnly[] memory lpFarms = farms;
        uint256 cacheLpReward = lpRewards;
        uint256 cacheSum = weightSum;
        for(uint256 i = 0; i<lpFarms.length; i++){
            IRewardDistributionRecipientTokenOnly farm = lpFarms[i];
            uint256 amount = cacheLpReward.mul(rate[address(farm)]).div(cacheSum);
            if(amount > 0) {
                rewardToken.approve(address(farm), amount);
                farm.notifyRewardAmount(amount);
            }
        }

        uint256 cacheStakerReward = stakerRewards;
        if(cacheStakerReward > 0) {
            IRewardDistributionRecipientTokenOnly stakerFarm = IRewardDistributionRecipientTokenOnly(stakerReward);
            rewardToken.approve(address(stakerFarm), cacheStakerReward);
            stakerFarm.notifyRewardAmount(cacheStakerReward);
        }
        
        uint256 cacheBorrowerReward = borrowerRewards;
        if(cacheBorrowerReward > 0) {
            IRewardDistributionRecipientTokenOnly borrowerFarm = IRewardDistributionRecipientTokenOnly(borrowerReward);
            rewardToken.approve(address(borrowerFarm), cacheBorrowerReward);
            borrowerFarm.notifyRewardAmount(cacheBorrowerReward);
        }

        // this will make sure lastRewardDistributed to set in order
        while(block.timestamp - lastRewardDistributed > 7 days) {
            lastRewardDistributed += 7 days;
        }
    }

    // should transfer rewardToken prior to calling this contract
    // this is implemented to take care of the out-of-gas situation
    function notifyRewardsPartial(uint256 amount, uint256 from, uint256 to) external onlyOwner {
        require(from < to, "from should be smaller than to");
        require(to <= farms.length, "to should be smaller or equal to farms.length");
        for(uint256 i = from; i < to; i++){
            IRewardDistributionRecipientTokenOnly farm = farms[i];
            farm.notifyRewardAmount(amount.mul(rate[address(farm)]).div(weightSum));
        }
    }

    function blockUser(address target) external onlyOwner {
        blackListed[target] = true;
    }

    function unblockUser(address target) external onlyOwner {
        blackListed[target] = false;
    }
}
