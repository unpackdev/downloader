//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";


abstract contract Cino {
    function balanceOf(address account) public view virtual returns(uint256);
    function transfer(address recipient, uint256 amount) public virtual returns (bool);
    function approve(address spender, uint256 amount) public virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);

}

contract CinoStakingV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private value;
    event ValueChanged(uint256 newValue);
    event ContractLocked(uint256 unlockTime);
    uint256 private startTime;
    uint256 private constant unixWeek = 604800;
    uint256 private constant unixMinute =  60;
    uint256 public unlockTime;
    uint256 public _totalStaked;
    uint256 public pendingForDistribution;

    struct StakingInfo {
        uint256 amountStaked;
        uint256 unixUnlockTime;
    }

    mapping(address => uint256) public addressUnlockTime;
    mapping(address => uint256) public addressTotalStaked;
    mapping(address => uint256) public ethRewards;
    address[] public currentStakers; 
    Cino private cino;
    address private cinoContract;
    event TokensStaked(uint256 amount, uint256 unlockTime);
    mapping(address => bool) public hasStaked;

    event Withdraw(address withdrawee, uint256 amountWithdrawn);
    mapping(address => uint256) private stakerIndex;

    bool public contractLock;
    uint256 public distributionIterations; 
    uint256 public lockPeriod;
    

    modifier isLocked {
        require(!contractLock, "Contract is locked for staking reward distribution");
        _;
    }

    function unlockTokens(uint256 _startIndex) external onlyOwner returns (uint256 index){
        if(currentStakers.length > 0){
            uint256 i = _startIndex;
            for(i; i < currentStakers.length && i < _startIndex + distributionIterations; i++){
                if(addressTotalStaked[currentStakers[i]] > 0){
                   addressUnlockTime[currentStakers[i]] = block.timestamp;
                }
                if(i == currentStakers.length - 1){
                }
            }
            return i;
        } 
    }
    
    function initialize(uint256 newValue) initializer public {
        value = newValue;
        emit ValueChanged(newValue);
        startTime = startTime + block.timestamp;
        

        unlockTime = startTime + (unixMinute * 5);
        _totalStaked = 0;
        pendingForDistribution = 0;
        __Ownable_init_unchained();
        __Context_init_unchained();
        transferOwnership(0x44d7FE987b8e8eB56FA4CE05C461850B754945c8);
        cinoContract = 0xb2733Eba27537da9285e5CfB94AcCa0A3606F2d9;
        cino = Cino(cinoContract);
        contractLock = false;
        distributionIterations = 100;
        lockPeriod = unixWeek;

        
        
    }

    function setLockPeriod(uint256 _timePeriod) external onlyOwner returns (uint256 newLockPeriod){
        lockPeriod = _timePeriod;
        return lockPeriod;
    }


    function stakeTokens(uint256 _amount) external isLocked returns (bool success, uint256 amountStaked, uint256 unlockTimestamp){
        cino.transferFrom(_msgSender(), address(this), _amount);
        uint256 unlockDate = block.timestamp + lockPeriod;
        addressUnlockTime[_msgSender()] = unlockDate; 
        if(addressTotalStaked[_msgSender()] == 0){
            addressTotalStaked[_msgSender()] = addressTotalStaked[_msgSender()] + _amount;
            stakerIndex[_msgSender()] = currentStakers.length;
            currentStakers.push(_msgSender());
        } else {
             addressTotalStaked[_msgSender()] = addressTotalStaked[_msgSender()] + _amount;
        }

        _totalStaked = _totalStaked + _amount;
        emit TokensStaked(_amount, unlockDate);
        return (true, _amount, unlockDate);
    }

    function checkTimeUntilUnlock(address _address) public view returns (bool isUnlocked, uint256 untilUnlock ){
        uint256 _unlockTime = addressUnlockTime[_address];

        bool _isUnlocked = block.timestamp >= _unlockTime;
        uint256 timeTilUnlock;
        if(block.timestamp >= _unlockTime){
            timeTilUnlock = 0;
        } else {

            timeTilUnlock = _unlockTime - block.timestamp; 
        }
        return (_isUnlocked, timeTilUnlock);
    }

    function removeStaker(address _toRemove ) internal returns (address) {
        uint256 stakerI = stakerIndex[_toRemove];
        currentStakers[stakerI] = currentStakers[currentStakers.length - 1]; 
        stakerIndex[currentStakers[stakerI]] = stakerI;
        currentStakers.pop();
        return _toRemove;
    }

    function withdrawTokens(uint256 _amount) external isLocked returns (uint256 amountWithdrawn) {
        uint256 _unlockTime = addressUnlockTime[_msgSender()];

        bool _isUnlocked = block.timestamp >= _unlockTime;
        if(_isUnlocked && _amount <= addressTotalStaked[_msgSender()]){
            addressTotalStaked[_msgSender()] = addressTotalStaked[_msgSender()] - _amount;
            _totalStaked = _totalStaked - _amount;
            if(addressTotalStaked[_msgSender()] == 0){
                removeStaker(_msgSender());
            }
            cino.transfer(_msgSender(), _amount);

        } else {
            return 0;
        }
        return _amount;

    }

    receive() external payable {
        pendingForDistribution = pendingForDistribution + msg.value;

    }

    function getTotalStakers() external view returns (uint256 stakersLength){
        return currentStakers.length;
    }

    function lockContract() external onlyOwner returns (bool _isLocked){
        contractLock = true; 
        return contractLock;
    }

    function unlockContract() external onlyOwner returns (bool _isLocked){
        contractLock = false; 
        return contractLock;
    }


    function distribute(uint256 _startIndex) external onlyOwner returns (uint256 lastIndex) {
        uint256 _toDistrib = pendingForDistribution;
        if(currentStakers.length > 0){
            uint256 i = _startIndex;
            for(i; i < currentStakers.length && i < _startIndex + distributionIterations; i++){
                if(addressTotalStaked[currentStakers[i]] > 0){
                    uint256 holdingsRatio = percent(addressTotalStaked[currentStakers[i]], _totalStaked, 4);                    
                    uint256 payoutRatio = _toDistrib * holdingsRatio;
                    uint256 payout = payoutRatio / 10000;
                    ethRewards[currentStakers[i]] = ethRewards[currentStakers[i]] + payout;
                }
                if(i == currentStakers.length - 1){
                    pendingForDistribution = 0;
                }
            }
            return i;
        } 
    }

    function setDistributionIterations(uint256 _newIterations) external onlyOwner returns (uint256){
        distributionIterations = _newIterations; 
        return distributionIterations;
    }

    function withdrawEarnings() isLocked external {
        if(ethRewards[_msgSender()] > 0){
            uint256 amountToPay = ethRewards[_msgSender()];
            ethRewards[_msgSender()] = 0;
            payable(_msgSender()).transfer(amountToPay);
            emit Withdraw(_msgSender(), amountToPay);

        }
    }


    function percent(uint256 numerator, uint256 denominator, uint256 precision) internal pure returns(uint256 quotient) {

         // caution, check safe-to-multiply here
        uint256 _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator)) / 10;
        return ( _quotient);
     }



    function _authorizeUpgrade(address) internal override onlyOwner {}

    function checkCinoBalance(address addyToCheck) public view returns (uint256){
        return cino.balanceOf(addyToCheck);
    }

    function checkLock() public view returns (bool){
        return (contractLock);
    }

    function checkTime() public view returns (uint256){
        return block.timestamp;
    }

}
 