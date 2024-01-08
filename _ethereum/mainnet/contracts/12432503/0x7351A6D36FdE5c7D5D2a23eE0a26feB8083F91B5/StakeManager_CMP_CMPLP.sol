// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Address.sol";
import "./IVault.sol";

contract LPTokenWrapper is ERC20 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable lp;
    
    constructor (address _lpToken) ERC20 ("Staked CMP-LP", "SCMP-LP") {
        require(_lpToken != address(0), "ZERO_ADDRESS");
        lp = IERC20(_lpToken);
    }

    function deposit(uint amount) public virtual {
        _mint(msg.sender, amount);
        lp.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint amount) public virtual {
        _burn(msg.sender, amount);
        lp.safeTransfer(msg.sender, amount);
    }
}

contract StakeManager_CMP_CMPLP is LPTokenWrapper, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public immutable cmp;
    IVault public immutable unitVault;
    
    uint public immutable DURATION;

    uint public periodFinish;
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) public vaultDeposit;

    event Airdrop(uint amount);
    event Claim(address indexed user, uint reward);

    modifier updateReward(address user) {
        _updateReward(user);
        _;
    }

    modifier updateRewardOnTransfer(address from, address to) {
        _updateReward(from);
        _updateReward(to);
        if (to == address(unitVault)) {
            vaultDeposit[from] = unitVault.collaterals(address(this), from);
        } else if (from == address(unitVault)) {
            vaultDeposit[to] = unitVault.collaterals(address(this), to);
        }
        _;
    }
    
    constructor(address _lpToken, address _cmp, address _vault, uint _duration) LPTokenWrapper(_lpToken) Ownable() {
        cmp = IERC20(_cmp);
        unitVault = IVault(_vault);
        DURATION = _duration;
    }

    function _updateReward(address user) internal {
        if (user != address(unitVault)) {
            rewardPerTokenStored = rewardPerToken();
            lastUpdateTime = lastTimeRewardApplicable();
            if (user != address(0)) {
                rewards[user] = earned(user);
                userRewardPerTokenPaid[user] = rewardPerTokenStored;
            }
        }
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address user) public view returns (uint) {
        if (user == address(unitVault)) return 0;
        return
            balanceOf(user).add(vaultDeposit[user])
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[user]))
                .div(1e18)
                .add(rewards[user]);
    }

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

    function multiClaim(address[] calldata users) public {
        for (uint i; i < users.length; i++) {
            _claim(users[i]);
        }
    }
    
    function _claim(address user) internal updateReward(user) {
        require(user != address(0), "ZERO_ADDRESS");
        uint reward = earned(user);
        if (reward > 0) {
            rewards[user] = 0;
            cmp.safeTransfer(user, reward);
            emit Claim(user, reward);
        }
    }

    function addReward(uint reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        cmp.safeTransferFrom(owner(), address(this), reward);
        emit Airdrop(reward);
    }
}
