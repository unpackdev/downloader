// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Water.sol";

/**
 * @title Staking
 */
contract Staking is Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when a user staked tokens.
     * @param sender User address.
     * @param amount The amount of staked tokens.
     * @param totalAmount Current user staked balance.
     */
    event Staked(
        address indexed sender,
        uint256 amount,
        uint256 totalAmount
    );

    /**
     * @dev Emitted when a user withdraws tokens.
     * @param sender User address.
     * @param amount The amount of withdrawn tokens.
     * @param reward Current user balance.
     */
    event Withdrawn(
        address indexed sender,
        uint256 amount,
        uint256 reward
    );

    /**
     * @dev Emitted when a new phase was activated.
     * @param startDate A new withdrawal lock duration value.
     * @param rate The owner address at the moment of value changing.
     */
    event PhaseActivated(uint256 startDate, uint256 rate);

    struct Phase {
        uint256 rate;
        bool isActive;
        uint256 startDate;
    }

    struct Stake {
        uint256 amount;
        uint256 startDate;
        uint256 reward;
    }

    // Mintable ERC20 Token
    Water public water;
    Phase[] public phases;
    mapping(address => address) public referrals;
    mapping(address => Stake) public pool;
    mapping(address => bool) private stakersIsActive;
    address[] private stakers;
    uint256 stakingFinishDate = 0;
    uint256 public totalStaked;
    uint256 private feePercentage;
    uint256 private referralPercentage;
    address payable private beneficiary;

    /**
     * @dev Initializes the contract.
     * @param _water WTR Token contract.
     */
    constructor(Water _water, uint256 _feePercantage, uint256 _referralPercentage, address payable _beneficiary) public {
        water = _water;
        feePercentage = _feePercantage;
        referralPercentage = _referralPercentage;
        beneficiary = _beneficiary;

        phases.push(Phase(100, true, now));
        phases.push(Phase(80, false, 0));
        phases.push(Phase(60, false, 0));

        stakers.push(msg.sender);
        stakersIsActive[msg.sender] = true;
    }

    /**
     * @param _referral referral.
     */
    function stake(address _referral) external payable {
        require(msg.value > 0, "amount cannot be 0");
    
        if (pool[msg.sender].amount > 0) {
            pool[msg.sender].reward = getTotalReward(msg.sender);
        } else {
            _addStaker(msg.sender);
        }

        pool[msg.sender].startDate = now;
        pool[msg.sender].amount = pool[msg.sender].amount.add(msg.value);

        totalStaked = totalStaked.add(msg.value);

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _referral;
        }

        emit Staked(msg.sender, msg.value, pool[msg.sender].amount);
    }

    /**
     * @dev eth and tokens withdrawing
     */
    function withdraw() external {
        require(pool[msg.sender].amount > 0, "insufficient funds");

        uint256 ethAmount = pool[msg.sender].amount;
        uint256 reward = getTotalReward(msg.sender);

        water.mint(address(this), reward.add(reward.div(referralPercentage)));

        totalStaked = totalStaked.sub(ethAmount);
        pool[msg.sender].amount = 0;
        pool[msg.sender].startDate = 0;
        pool[msg.sender].reward = 0;

        uint256 fees = ethAmount.div(feePercentage);
        msg.sender.transfer(ethAmount.sub(fees));
        beneficiary.transfer(fees);

        water.transfer(msg.sender, reward);
        if (referrals[msg.sender] != msg.sender) {
            water.transfer(referrals[msg.sender], reward.div(referralPercentage));
        }

        _deactivateUser(msg.sender);

        emit Withdrawn(msg.sender, ethAmount, reward);
    }

    /**
     * @return Returns true if user has any stakes.
     */
    function isActiveStaker(address _user) private view returns (bool) {
        return stakersIsActive[_user];
    }

    /** @dev add a user to stakers array
    * @param _user address of user to add to the list
    */
    function _addStaker(address _user) internal {
        if (!isActiveStaker(_user)){
            stakers.push(_user);
            stakersIsActive[_user] = true;
        }
    }

    /** 
     * @dev remove a user from stakers array
     * @param _user address of staker to remove from the list
     */
    function _deactivateUser(address _user) internal {
        stakersIsActive[_user] = false;
    }

    /**
    * @dev activate next staking Phase
    */
    function activateNextPhase() public onlyOwner {
        for (uint256 i = 0; i < phases.length; i++) {
            if (phases[i].isActive) {
                phases[i].isActive = false;

                if (i < phases.length - 1) {
                    phases[i + 1].isActive = true;
                    phases[i + 1].startDate = now;

                    emit PhaseActivated(getCurrentPhaseStartDate(), getCurrentPhaseRate());
                    break;
                } else {
                    stakingFinishDate = now;
                }
            }
        }
    }

    /**
     * @return Returns current phase rate.
     */
    function getCurrentPhaseRate() public view returns (uint256) {
        for (uint256 i = 0; i < phases.length; i++) {
            if (phases[i].isActive) {
                return phases[i].rate;
            }
        }

        return 0;
    }

    /**
     * @return Returns current phase start date.
     */
    function getCurrentPhaseStartDate() public view returns (uint256) {
        for (uint256 i = 0; i < phases.length; i++) {
            if (phases[i].isActive) {
                return phases[i].startDate;
            }
        }

        return 0;
    }

    /**
     * @return Returns current phase number.
     */
    function getCurrentPhaseNumber() public view returns (uint256) {
        for (uint256 i = 0; i < phases.length; i++) {
            if (phases[i].isActive) {
                return i + 1;
            }
        }

        return 0;
    }

    /**
     * @param _user address of user to add to the list
     * @return Returns user's stake amount.
     */
    function getStakeAmount(address _user) public view returns (uint256) {
        return pool[_user].amount;
    }

    /**
     * @param _user address of user to add to the list
     * @return Returns user's total calculated reward.
     */
    function getTotalReward(address _user) public view returns (uint256) {
        if (getStakeAmount(_user) == 0) {
            return 0;
        }
        
        uint256 totalReward = 0;
        uint256 dateFrom = stakingFinishDate != 0 ? stakingFinishDate : now;
        for (uint256 i = phases.length - 1; i >= 0; i--) {
            if (phases[i].startDate != 0) {
                bool firstUserPhase = pool[_user].startDate >= phases[i].startDate;
                uint256 dateTo = firstUserPhase ? pool[_user].startDate : phases[i].startDate;
                uint256 hoursStaked = (dateFrom.sub(dateTo)).div(3600);
                uint256 reward = getStakeAmount(_user).mul(phases[i].rate).mul(hoursStaked);
                totalReward = totalReward.add(reward);
                
                if (firstUserPhase) {
                    break;
                }

                dateFrom = phases[i].startDate;
            }
        }

        return totalReward.add(pool[_user].reward);
    }
}
