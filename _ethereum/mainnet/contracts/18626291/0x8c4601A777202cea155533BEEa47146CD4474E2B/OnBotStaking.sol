// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract OnBotStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    bool public openStaking;
    bool public pauseStaking;
  
    uint256 public totalStakingAmount;
    uint256 public stopAtBlock;
    uint256 public constant BASIS_POINTS_DIVISOR = 1000;
    uint256 public constant STOP_BLOCK = 100000000;
    address public constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public onbotAddress;
    
    mapping(address => uint256) public stakingAmount;
    mapping(address => uint256) public stakingAtBlock;
    mapping(address => uint256) public savePoint;

    event RecoverToken(address token, uint256 amount);
    event Stake(address user, uint256 amount, uint256 blockNumber);
    event UnStake(address user, uint256 amount);

    constructor(address _onbotAddress) {
        openStaking = true;
        onbotAddress =  _onbotAddress;
        stopAtBlock = block.number + STOP_BLOCK;
    }

    function setStakingStatus(bool _openStaking, bool _pauseStaking) external onlyOwner {
        openStaking = _openStaking;
        pauseStaking = _pauseStaking;
    }

    function setStopAtBlock(uint256 _stopAtBlock) external onlyOwner {
        stopAtBlock = _stopAtBlock;
    }

    // Allows the owner to recover tokens sent to the contract by mistake
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != onbotAddress, "Operations: not allow");
        if (_token == NATIVE_ADDRESS) {
            require(_amount <= address(this).balance, "INSUFFICIENT BALANCE");
            payable(address(msg.sender)).transfer(_amount);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(_amount <= balance, "Operations: Cannot recover zero balance");

            IERC20(_token).safeTransfer(address(msg.sender), _amount);
        }
        emit RecoverToken(_token, _amount);
    }

    function stake(uint256 _amount) external nonReentrant {
        require(openStaking, "Operations: staking off");
        require(!pauseStaking, "Operations: stop staking");
        IERC20(onbotAddress).safeTransferFrom(address(msg.sender), address(this), _amount);
        
        if (stakingAmount[msg.sender] > 0) {
            _handlePoint();
        }

        stakingAmount[msg.sender] += _amount; 
        stakingAtBlock[msg.sender] = block.number;
        totalStakingAmount += _amount;

        emit Stake(msg.sender, _amount, block.number);
    }

    function unStake() external nonReentrant {
        require(openStaking, "Operations: staking off");
        uint256 amount = stakingAmount[msg.sender];
        require(amount > 0, "Operations: you haven't staked yet");

        IERC20(onbotAddress).safeTransfer(address(msg.sender), amount);
        stakingAmount[msg.sender] = 0;
        stakingAtBlock[msg.sender] = 0;
        totalStakingAmount -= amount;

        // reset point to 0
        savePoint[msg.sender] = 0;

        emit UnStake(msg.sender, amount);
    }

    function _handlePoint() internal {
        uint256 point = getCurrentPoint(msg.sender);

        if (point > 0) {
            savePoint[msg.sender] += point;
        }
    }

    function getCurrentPoint(address _user) public view returns(uint256) {
        uint256 amount = stakingAmount[_user];
        uint256 stakeAt = stakingAtBlock[_user];
        uint256 blockReward = block.number;

        if (amount == 0) {
            return 0;
        }

        if (blockReward >= stopAtBlock) {
            blockReward = stopAtBlock;
        }

        uint256 blockDuration;

        if (blockReward >= stakeAt) {
            blockDuration = blockReward - stakeAt;
        } else {
            blockDuration = 0;
        }

        return blockDuration * (amount / (1 * 10 ** ERC20(onbotAddress).decimals()));
    }

    function getPoint(address _user) public view returns(uint256) {
        uint256 amount = stakingAmount[_user];
        if (amount == 0) {
            return 0;
        }

        return savePoint[_user] + getCurrentPoint(_user);
    }
}
