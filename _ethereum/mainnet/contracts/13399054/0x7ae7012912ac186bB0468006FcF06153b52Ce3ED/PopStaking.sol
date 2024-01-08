// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract PopStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 rewardMultiplier; // Reward Block Count.
        uint256 lastRewardBlock;  // Last block number that tokens distribution occurs.
    }

    // The POP TOKEN!
    IERC20 public pop;
    // Dev address.
    address public devaddr;
    // POP tokens created per block.
    uint256 [] public popPerBlockAllCycles;
    uint8 cycleLen;

    mapping (address => UserInfo) public userInfo;
    
    // The block number when POP mining starts.
    uint256 public startBlock;
    uint256 public startTime;
    uint256 public claimableBlock;
    uint256 public constant stakeUnit = 50000*1e18;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IERC20 _pop,
        address _devaddr,
        uint256 _startTime,
        uint256 _popPerBlock
    ) public {
        pop = _pop;
        devaddr = _devaddr;
        while (cycleLen < 4) {
            popPerBlockAllCycles.push(_popPerBlock);
            _popPerBlock /= 2;
            cycleLen ++;
        }
        startTime = _startTime;
        startBlock = block.number; 
        claimableBlock = block.number;
    }

    function getPopPerBlock() public view returns (uint256) {
        if(block.timestamp < startTime) return 0;
        
        uint256 cycle = (block.timestamp - startTime) / 90 days;
        if(cycle > cycleLen) cycle = cycleLen - 1;
        return popPerBlockAllCycles[cycle];
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= _from) {
            return 0;
        } else {
            return _to.sub(_from);
        }
    }

    // View function to see pending POPs on frontend.
    function claimablePop(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.amount.mul(getPopPerBlock()).mul(user.rewardMultiplier).div(1e18);
    }

    // Deposit tokens to PopStaking for POP allocation.
    function deposit(uint256 _amount) public {
        uint256 amount = _amount.sub(_amount % stakeUnit);
        require(amount >= 50000, "deposit: not good");
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 claimable = user.amount.mul(getPopPerBlock()).mul(user.rewardMultiplier).div(1e18);
            safePopTransfer(msg.sender, claimable);
        }
        pop.transferFrom(address(msg.sender), address(this), amount);
        user.amount = user.amount.add(amount);
        user.lastRewardBlock = block.number;
        user.rewardMultiplier = 0;
        emit Deposit(msg.sender, amount);
    }

    // Withdraw tokens from PopStaking.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "withdraw: can’t withdraw 0");
        require(user.amount >= _amount, "withdraw: not good");
        uint256 claimable = user.amount.mul(getPopPerBlock()).mul(user.rewardMultiplier).div(1e18);
        safePopTransfer(msg.sender, claimable);
        user.amount = user.amount.sub(_amount);
        user.lastRewardBlock = block.number;
        user.rewardMultiplier = 0;
        pop.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        user.amount = 0;
        user.lastRewardBlock = block.number;
        user.rewardMultiplier = 0;
        pop.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        
    }

    // Safe pop transfer function, just in case if rounding error causes pool to not have enough POPs.
    function safePopTransfer(address _to, uint256 _amount) internal {
        uint256 popBal = pop.balanceOf(address(this));
        if (_amount > popBal) {
            pop.transfer(_to, popBal);
        } else {
            pop.transfer(_to, _amount);
        }
    }

    // Update pending info
    function updatePendingInfo(address[] memory _addresses, uint16[] memory _multiplier) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(_addresses.length == _multiplier.length, "pendingInfo: length?");
        
        for (uint i = 0; i < _addresses.length; i++) {
            UserInfo storage user = userInfo[_addresses[i]];
            user.rewardMultiplier = user.rewardMultiplier.add(_multiplier[i]);
        }

        claimableBlock = block.number;
    }
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}