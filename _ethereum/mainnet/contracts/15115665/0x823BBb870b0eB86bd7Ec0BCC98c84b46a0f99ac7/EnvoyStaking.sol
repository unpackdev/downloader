// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract EnvoyStaking is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant EMBARGOES_ROLE = keccak256("EMBARGOES_ROLE");
    bytes32 public constant LOCKINGS_ROLE = keccak256("LOCKINGS_ROLE");
    bytes32 public constant RATES_ROLE = keccak256("RATES_ROLE");

    event NewStake(address indexed user, uint256 totalStaked, uint256 lockupPeriod, bool isEmbargo);
    event StakeFinished(address indexed user, uint256 totalRewards);
    event LockingIncreased(address indexed user, uint256 total);
    event LockingReleased(address indexed user, uint256 total);
    event APYSet(uint256 indexed _lockupPeriod, uint256 _from, uint256 _to, uint256 _apy);
    event APYRemoved(uint256 indexed _lockupPeriod, uint256 _from, uint256 _to);
    
    IERC20 token = IERC20(0x2Ac8172D8Ce1C5Ad3D869556FD708801a42c1c0E);

    uint256 public constant APY_1 = 500; //5%
    uint256 public constant APY_3 = 800; //8%
    uint256 public constant APY_6 = 1100; //11%
    uint256 public constant APY_9 = 1300; //13%
    uint256 public constant APY_12 = 1500; //15%
    
    uint256 public totalStakes;
    uint256 public totalActiveStakes;
    uint256 public totalActiveStaked;
    uint256 public totalStaked;
    uint256 public totalStakeClaimed;
    uint256 public totalRewardsClaimed;
    uint256 public minimumStake = 1e18;

    struct APY {
        uint256 from;
        uint256 to;
        uint256 apy;
        bool enabled;
    }
    
    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        uint256 lockupPeriod;
        uint256 apy;
        bool isEmbargo;
    }
    
    mapping(address => Stake) stakes;
    mapping(address => uint256) public lockings;
    mapping(uint256 => APY[]) public apys;

    function _getTotalAPYs(uint256 lockup) public view returns(uint256) {
        return apys[lockup].length;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(EMBARGOES_ROLE, msg.sender);
        _grantRole(LOCKINGS_ROLE, msg.sender);
        _grantRole(RATES_ROLE, msg.sender);
    }

    function createStake(uint256 _totalStake, uint256 _lockupPeriod, uint256 _forceAPY) public {
        require(_totalStake >= minimumStake, "Total stake below minimum");

        _addStake(msg.sender, _totalStake, _lockupPeriod, false, _forceAPY);
    }

    function calculateAPY(uint256 _lockupPeriod) public view returns(uint256) {
        uint256 currentAPY = APY_1;
        if (_lockupPeriod == 3) {
            currentAPY = APY_3;
        }
        else if (_lockupPeriod == 6) {
            currentAPY = APY_6;
        }
        else if (_lockupPeriod == 9) {
            currentAPY = APY_9;
        }
        else if (_lockupPeriod == 12) {
            currentAPY = APY_12;
        }
        else if (_lockupPeriod != 1) {
            revert();
        }

        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from <= totalActiveStaked && totalActiveStaked <= apys[_lockupPeriod][i].to && currentAPY < apys[_lockupPeriod][i].apy) {
                currentAPY = apys[_lockupPeriod][i].apy;
            } 
        }

        return currentAPY;
    }
    
    function _addStake(address _beneficiary, uint256 _totalStake, uint256 _lockupPeriod, bool _isEmbargo, uint256 _forceAPY) internal whenNotPaused {
        require(!stakes[_beneficiary].exists, "Stake already created");
        require(_lockupPeriod == 1 || _lockupPeriod == 3 || _lockupPeriod == 6 || _lockupPeriod == 9 || _lockupPeriod == 12, "Invalid lockup period");
        require(IERC20(token).transferFrom(msg.sender, address(this), _totalStake), "Couldn't take the tokens");

        uint256 apy = calculateAPY(_lockupPeriod);
        if (_forceAPY > 0) {
            require(apy == _forceAPY, "APY changed");
        }
        
        Stake memory stake = Stake({exists:true,
                                    createdOn: block.timestamp, 
                                    initialAmount:_totalStake, 
                                    lockupPeriod:_lockupPeriod, 
                                    apy: apy,
                                    isEmbargo:_isEmbargo
        });
        
        stakes[_beneficiary] = stake;
                                    
        totalActiveStakes++;
        totalStakes++;
        totalStaked += _totalStake;
        totalActiveStaked += _totalStake;
        
        emit NewStake(_beneficiary, _totalStake, _lockupPeriod, _isEmbargo);
    }
    
    function finishStake() public {
        require(!stakes[msg.sender].isEmbargo, "This is an embargo");
        totalStakes--;
        _finishStake(msg.sender);
    }
    
    function _finishStake(address _account) internal {
        require(stakes[_account].exists, "Invalid stake");

        Stake storage stake = stakes[_account];
        
        uint256 finishesOn = _calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        require(block.timestamp > finishesOn, "Can't be finished yet");
        
        stake.exists = false;
        
        uint256 totalRewards = calculateRewards(stake.initialAmount, stake.lockupPeriod, stake.apy);

        totalActiveStakes -= 1;
        totalActiveStaked -= stake.initialAmount;
        totalStakeClaimed += stake.initialAmount;
        totalRewardsClaimed += totalRewards;
        
        require(token.transfer(msg.sender, totalRewards), "Couldn't transfer the tokens");
        
        emit StakeFinished(msg.sender, totalRewards);
    }
    
    function calculateRewards(uint256 initialAmount, uint256 lockupPeriod, uint256 apy) public pure returns (uint256) {
        return initialAmount * apy * lockupPeriod / 120000;
    }
    
    function calculateFinishTimestamp(address _account) public view returns (uint256) {
        return _calculateFinishTimestamp(stakes[_account].createdOn, stakes[_account].lockupPeriod);
    }
    
    function _calculateFinishTimestamp(uint256 _timestamp, uint256 _lockupPeriod) internal pure returns (uint256) {
        return _timestamp + _lockupPeriod * 30 days;
    }

    //If minimum stake is set to zero, no minimum stake will be required
    function setMinimumStake(uint256 _minimumStake) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not allowed");
        require(_minimumStake >= 1e18, "Minimum stake is 1 VOY");

        minimumStake = _minimumStake;
    }
    
    function increaseLocking(address _beneficiary, uint256 _total) public {
        require(hasRole(LOCKINGS_ROLE, msg.sender), "Not allowed");
        require(_beneficiary != address(0), "Invalid address");
        require(_total > 0, "Invalid value");

        require(IERC20(token).transferFrom(msg.sender, address(this), _total), "Couldn't take the tokens");
        
        lockings[_beneficiary] += _total;
        
        emit LockingIncreased(_beneficiary, _total);
    }
    
    function releaseFromLocking(address _beneficiary, uint256 _total) public {
        require(hasRole(LOCKINGS_ROLE, msg.sender), "Not allowed");
        require(_total > 0, "Invalid value");
        require(lockings[_beneficiary] >= _total, "Not enough locked tokens");

        lockings[_beneficiary] -= _total;

        require(IERC20(token).transfer(_beneficiary, _total), "Couldn't send the tokens");
        
        emit LockingReleased(_beneficiary, _total);
    }

    function createEmbargo(address _account, uint256 _totalStake, uint256 _lockupPeriod, uint256 _forceAPY) public {
        require(hasRole(EMBARGOES_ROLE, msg.sender), "Not allowed");
        require(_account != address(0), "Invalid address");
        require(_totalStake > 1e18, "Invalid value");
        _addStake(_account, _totalStake, _lockupPeriod, true, _forceAPY);
    }

    function _setAPY(uint256 _lockupPeriod, uint256 _from, uint256 _to, uint256 _apy) public {
        require(hasRole(RATES_ROLE, msg.sender), "Not allowed");
        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from == _from && apys[_lockupPeriod][i].to == _to) {
                apys[_lockupPeriod][i].apy = _apy;
                apys[_lockupPeriod][i].enabled = true;
                return;
            }
        }

        APY memory apy = APY({from:_from, to:_to, apy:_apy, enabled:true});
        apys[_lockupPeriod].push(apy);
        emit APYSet(_lockupPeriod, _from, _to, _apy);
    }

    function _removeAPY(uint256 _lockupPeriod, uint256 _from, uint256 _to) public {
        require(hasRole(RATES_ROLE, msg.sender), "Not allowed");

        for (uint i = 0; i < apys[_lockupPeriod].length; i++) {
            if (apys[_lockupPeriod][i].from == _from && apys[_lockupPeriod][i].to == _to) {
                apys[_lockupPeriod][i].enabled = false;
                emit APYRemoved(_lockupPeriod, _from, _to);
                return;
            }
        }

        return revert();
    }
    
    function finishEmbargo(address _account) public {
        require(hasRole(EMBARGOES_ROLE, msg.sender), "Not allowed");
        require(stakes[_account].isEmbargo, "Not an embargo");

        _finishStake(_account);
    }

    function _setupInitialAPYs() public {
        _setAPY(1, 0, 500000 * 1e18, 1000);
        _setAPY(1, 500000 * 1e18, 1000000 * 1e18, 900);
        _setAPY(1, 1000000 * 1e18, 5000000 * 1e18, 800);
        _setAPY(1, 5000000 * 1e18, 10000000 * 1e18, 700);
        _setAPY(1, 10000000 * 1e18, 50000000 * 1e18, 625);
        _setAPY(1, 50000000 * 1e18, 100000000 * 1e18, 575);
        _setAPY(1, 100000000 * 1e18, 10000000000 * 1e18, 500);

        _setAPY(3, 0, 500000 * 1e18 * 1e18, 1600);
        _setAPY(3, 500000 * 1e18, 1000000 * 1e18, 1440);
        _setAPY(3, 1000000 * 1e18, 5000000 * 1e18, 1280);
        _setAPY(3, 5000000 * 1e18, 10000000 * 1e18, 1120);
        _setAPY(3, 10000000 * 1e18, 50000000 * 1e18, 1000);
        _setAPY(3, 50000000 * 1e18, 100000000 * 1e18, 920);
        _setAPY(3, 100000000 * 1e18, 10000000000 * 1e18, 800);

        _setAPY(6, 0, 500000 * 1e18, 2200);
        _setAPY(6, 500000 * 1e18, 1000000 * 1e18, 1980);
        _setAPY(6, 1000000 * 1e18, 5000000 * 1e18, 1760);
        _setAPY(6, 5000000 * 1e18, 10000000 * 1e18, 1540);
        _setAPY(6, 10000000 * 1e18, 50000000 * 1e18, 1375);
        _setAPY(6, 50000000 * 1e18, 100000000 * 1e18, 1265);
        _setAPY(6, 100000000 * 1e18, 10000000000 * 1e18, 1100);

        _setAPY(9, 0, 500000 * 1e18 * 1e18, 2600);
        _setAPY(9, 500000 * 1e18, 1000000 * 1e18, 2340);
        _setAPY(9, 1000000 * 1e18, 5000000 * 1e18, 2080);
        _setAPY(9, 5000000 * 1e18, 10000000 * 1e18, 1820);
        _setAPY(9, 10000000 * 1e18, 50000000 * 1e18, 1625);
        _setAPY(9, 50000000 * 1e18, 100000000 * 1e18, 1495);
        _setAPY(9, 100000000 * 1e18, 10000000000 * 1e18, 1300);

        _setAPY(12, 0, 500000 * 1e18, 3000);
        _setAPY(12, 500000 * 1e18, 1000000 * 1e18, 2700);
        _setAPY(12, 1000000 * 1e18, 5000000 * 1e18, 2400);
        _setAPY(12, 5000000 * 1e18, 10000000 * 1e18, 2100);
        _setAPY(12, 10000000 * 1e18, 50000000 * 1e18, 1875);
        _setAPY(12, 50000000 * 1e18, 100000000 * 1e18, 1725);
        _setAPY(12, 100000000 * 1e18, 10000000000 * 1e18, 1500);
    }
    
    function _extract(uint256 amount, address _sendTo) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not allowed");
        require(token.transfer(_sendTo, amount));
    }
    
    function getStake(address _account) external view returns (bool _exists, uint256 _createdOn, uint256 _initialAmount, uint256 _lockupPeriod, uint256 _apy, bool _isEmbargo, uint256 _finishesOn, uint256 _totalRewards) {
        Stake memory stake = stakes[_account];
        if (!stake.exists) {
            return (false, 0, 0, 0, 0, false, 0, 0);
        }
        uint256 finishesOn = calculateFinishTimestamp(_account);
        uint256 totalRewards = calculateRewards(stake.initialAmount, stake.lockupPeriod, stake.apy);
        return (stake.exists, stake.createdOn, stake.initialAmount, stake.lockupPeriod, stake.apy, stake.isEmbargo, finishesOn, totalRewards);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

