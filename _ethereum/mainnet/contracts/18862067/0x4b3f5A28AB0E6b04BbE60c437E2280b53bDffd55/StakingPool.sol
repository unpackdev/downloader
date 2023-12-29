// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract StakingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Stake {
    uint256 amount;
    uint256 stakedTime;
    }

    address public token;
    uint256 public apr;
    uint256 public startTime;
    uint256 public lockupPeriod;
    uint256 public totalStakedUsers;
    uint256 public totalDeposited;
    uint256 public capacity;
    bool public isClaimed;
    bool public isStaked = true;

    mapping(address => Stake) public stakes;
    mapping(address => bool) public admin;
    mapping(address => bool) public blacklist;

    constructor(address _token, uint256 _apr, uint256 _startTime, uint256 _lockupPeriod, uint256 _capacity) {
        token = _token;
        apr = _apr;
        startTime = _startTime;
        lockupPeriod = _lockupPeriod;
        capacity = _capacity;
        admin[msg.sender] = true;
    }
    receive() external payable {}

    function stake(uint256 amount) external nonReentrant {
        require(isStaked, "isStaked");
        require(!blacklist[_msgSender()], "blacklist");
        require(block.timestamp >= startTime, "startTime");
        require(totalDeposited + amount <= capacity, "capacity");
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        uint256 sharesBefore = stakes[_msgSender()].amount;
        totalDeposited += amount;
        stakes[_msgSender()].amount += amount;
        stakes[_msgSender()].stakedTime = block.timestamp;
        if (sharesBefore == 0 && stakes[_msgSender()].amount > 0) {
            totalStakedUsers++;
        }
        emit StakeToken(_msgSender(), amount, block.timestamp);
    }

    function unStake() external nonReentrant {
        require(isClaimed, "isClaimed");
        require(block.timestamp > stakes[_msgSender()].stakedTime + lockupPeriod, "timelock");
        require(stakes[_msgSender()].amount > 0, "amount");
        totalDeposited -= stakes[_msgSender()].amount;
        totalStakedUsers--;
        uint reward = (stakes[_msgSender()].amount * apr * lockupPeriod) / 365 days / 100;
        uint amount = reward + stakes[_msgSender()].amount;
        stakes[_msgSender()].amount = 0;
        stakes[_msgSender()].stakedTime = block.timestamp;
        IERC20(token).safeTransfer(_msgSender(), amount);
        emit UnstakeToken(_msgSender(), amount, block.timestamp);
    }

    function rewardOf(address user) public view returns(uint256) {
        if(stakes[user].stakedTime + lockupPeriod > block.timestamp){
            return 0;
        }
        uint256 reward = (stakes[user].amount * apr * lockupPeriod) / 365 days / 100;
        return reward;

    }

    function setAdmin(address _admin, bool _status) external onlyOwner {
        admin[_admin] =  _status;
        emit SetAdmin(_admin, _status, block.timestamp);
    }

    function setClaim(bool status) external onlyOwner {
        isClaimed = status;
        emit SetClaim(status, block.timestamp);
    }

    function setStake(bool status) external onlyOwner {
        isStaked = status;
        emit SetStake(status, block.timestamp);
    }

    function setTime(uint256 _start) external onlyOwner {
        startTime = _start;
        emit SetTime(_start, block.timestamp);
    }

    function setAPR(uint8 _newAPR) external onlyOwner {
        apr = _newAPR;
    }

    function setBlacklist(address[] memory _acc, bool[]  memory _status) external {
        require(admin[msg.sender], "onlyAdmin");
        require(_acc.length == _status.length, "length");
        for(uint i = 0; i < _acc.length; i++){
            blacklist[_acc[i]] = _status[i];
            emit SetBlacklist(_acc[i], _status[i], block.timestamp);
        }
    }

    function setCapacity(uint _cap) external onlyOwner {
        capacity = _cap;
        emit SetCap(_cap, block.timestamp);
    }

    function withdrawEther() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function setLockupPeriod(uint256 _seconds) external onlyOwner {
        require(_seconds < 365 days, 'lte 1 year');
        lockupPeriod = _seconds;
    }

    event SetAdmin(address admin, bool status, uint blockTime);
    event SetBlacklist(address user, bool status, uint blockTime);
    event SetCap(uint capacity, uint blockTime);
    event SetClaim(bool status, uint blockTime);
    event SetStake(bool status, uint blockTime);
    event StakeToken(address user, uint amount, uint blockTime);
    event UnstakeToken(address user, uint amount, uint blockTime);
    event SetTime(uint startTime, uint blockTime);
}