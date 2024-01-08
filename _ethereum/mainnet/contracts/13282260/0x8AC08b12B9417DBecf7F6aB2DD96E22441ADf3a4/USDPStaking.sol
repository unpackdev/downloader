// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract TokenWrapper is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);
    
    constructor() ERC20 ("Staked USDP", "SUSDP") { }

    function deposit(uint amount) public virtual {
        _mint(msg.sender, amount);
        usdp.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint amount) public virtual {
        _burn(msg.sender, amount);
        usdp.safeTransfer(msg.sender, amount);
    }
}

contract USDPStaking is TokenWrapper, Ownable {
    using SafeERC20 for IERC20;

    uint public immutable DURATION = 7 days;

    uint public periodFinish;
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => bool) public collectors;

    event RewardDeposit(uint amount);
    event Claim(address indexed user, uint reward);
    event CollectorSet(address collector, bool isCollector);

    modifier updateReward(address user) {
        _updateReward(user);
        _;
    }

    modifier updateRewardOnTransfer(address from, address to) {
        _updateReward(from);
        _updateReward(to);
        _;
    }

    modifier onlyCollector() {
        require(collectors[msg.sender], "USDPStaking: !collector");
        _;
    }
    
    constructor() TokenWrapper() Ownable() {
        // transfer ownership to Unit multisig
        transferOwnership(0xae37E8f9a3f960eE090706Fa4db41Ca2f2C56Cb8);
    }

    function setCollector(address collector, bool isCollector) external onlyOwner {
        collectors[collector] = isCollector;
        emit CollectorSet(collector, isCollector);
    }

    function _updateReward(address user) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (user != address(0)) {
            rewards[user] = earned(user);
            userRewardPerTokenPaid[user] = rewardPerTokenStored;
        }
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (
            (lastTimeRewardApplicable() - lastUpdateTime) *
            rewardRate * 1e18 / totalSupply()
        );
    }

    function earned(address user) public view returns (uint) {
        return
            balanceOf(user)
                * (rewardPerToken() - userRewardPerTokenPaid[user])
                / 1e18
                + rewards[user];
    }

    // deposit visibility is public as overriding TokenWrapper's deposit() function
    function deposit(uint amount) public override updateReward(msg.sender) {
        require(amount != 0, "Cannot stake 0");
        super.deposit(amount);
    }

    function withdraw(uint amount) public override updateReward(msg.sender) {
        require(amount != 0, "Cannot withdraw 0");
        super.withdraw(amount);
    }

    function transfer(address to, uint amount) 
        public 
        override 
        updateRewardOnTransfer(msg.sender, to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint amount) 
        public 
        override 
        updateRewardOnTransfer(from, to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        claim();
    }

    function claim() public {
        _claim(msg.sender);
    }

    function claimAndDeposit() public {
        uint claimed = _claim(msg.sender);
        deposit(claimed);
    }

    function multiClaim(address[] calldata users) public {
        for (uint i; i < users.length; i++) {
            _claim(users[i]);
        }
    }
    
    function _claim(address user) internal updateReward(user) returns (uint) {
        require(user != address(0), "ZERO_ADDRESS");
        uint reward = rewards[user];
        if (reward > 0) {
            rewards[user] -= reward;
            usdp.safeTransfer(user, reward);
            emit Claim(user, reward);
        }
        return reward;
    }

    function addReward(uint reward)
        external
        onlyCollector
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / DURATION;
        } else {
            uint remaining = periodFinish - block.timestamp;
            uint leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + DURATION;
        usdp.safeTransferFrom(msg.sender, address(this), reward);
        emit RewardDeposit(reward);
    }
}
