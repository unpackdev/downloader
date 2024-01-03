pragma solidity ^0.6.0;

import "./hotpotinterface.sol";
import "./ILoan.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IInvite.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public tokenAddr;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        tokenAddr.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        tokenAddr.safeTransfer(msg.sender, amount);
    }
}

contract StakePool is
    LPTokenWrapper,
    IRewardDistributionRecipient,
    Pausable,
    ReentrancyGuard
{
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public erc20;
    IHotPot public hotpot;
    IERC721 public erc721;
    ILoan public loan;
    IInvite public invite;

    address public rewardContract;
    uint256 public DURATION = 86400 * 7;

    uint256 public starttime = 1601391600;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public lastRewardTime;

    uint256 public freeRewardRatio = 20;
    uint256 public grade1RewardRatio = 20;
    uint256 public grade2RewardRatio = 25;
    uint256 public grade3RewardRatio = 30;

    uint256 public rewardRatio = 30;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardChanged(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward, uint256 percent);
    event Rescue(address indexed dst, uint256 sad);
    event RescueToken(address indexed dst, address indexed token, uint256 sad);

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        _nofityReward(reward);
    }

    function _nofityReward(uint256 reward) internal {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
                _decreaseRewardRatio();
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardChanged(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardChanged(reward);
        }
    }

    constructor(
        address _stakeERC20,
        address _hotpotNFT,
        address _hotpotERC20,
        address _loan,
        address _reward,
        address _invite,
        uint256 _starttime,
        uint256 duration,
        uint256 _rewardAmount
    ) public {
        tokenAddr = IERC20(_stakeERC20);
        hotpot = IHotPot(_hotpotNFT);
        invite = IInvite(_invite);
        erc721 = IERC721(_hotpotNFT);
        erc20 = IERC20(_hotpotERC20);
        loan = ILoan(_loan);
        rewardContract = _reward;
        rewardDistribution = _msgSender();
        starttime = _starttime;
        DURATION = duration;
        _nofityReward(_rewardAmount);
    }

    function setLoan(address _addr) external onlyOwner {
        require(_addr.isContract(), "Must be contract");
        loan = ILoan(_addr);
    }

    function setInvite(address _addr) external onlyOwner {
        require(_addr.isContract(), "Must be contract");
        invite = IInvite(_addr);
    }

    function getPoolBalance() external view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function setRewardContract(address _addr) external onlyOwner {
        require(_addr.isContract(), "It is not contract address!");
        rewardContract = _addr;
    }

    function getBlockTime() external view returns (uint256) {
        return block.timestamp;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, "not start");
        _;
    }

    modifier validToken(uint256 _tokenId) {
        require(erc721.ownerOf(_tokenId) != address(0), "This is not a token!");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
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

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
        nonReentrant
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function _getReward(uint256 _percent) internal checkStart {
        require(_percent < 1000, "cal reward error!");
        uint256 trueReward = earned(msg.sender);
        if (trueReward > 0) {
            uint256 reward = trueReward.mul(_percent).div(1000);

            rewards[msg.sender] = trueReward.sub(reward);

            erc20.safeTransfer(
                rewardContract,
                reward.mul(rewardRatio).div(100)
            );
            erc20.safeTransfer(
                msg.sender,
                reward.mul(100 - rewardRatio).div(100)
            );

            emit RewardPaid(msg.sender, reward, _percent);
        }
    }

    function getRewardFree()
        public
        updateReward(msg.sender)
        checkStart
        nonReentrant
        whenNotPaused
    {
        require(
            lastRewardTime[msg.sender] + 24 * 60 * 60 < now,
            "You get reward within 24 hours!"
        );
        lastRewardTime[msg.sender] = now;
        uint256 ratioUpdate = invite.calRatioUpdate(msg.sender);
        uint256 ratio = freeRewardRatio * 10 + ratioUpdate;
        _getReward(ratio);
    }

    function getRewardByNFT(uint256 _tokenId)
        public
        updateReward(msg.sender)
        checkStart
        nonReentrant
        validToken(_tokenId)
        whenNotPaused
    {
        //1.check the NFT is used?
        uint256 time = hotpot.getUseTime(_tokenId);
        require(
            time + 24 * 60 * 60 < now,
            "This ticket is used within 24 hours!"
        );

        require(
            loan.checkPrivilege(msg.sender, _tokenId, now),
            "You do not have right to use this token!"
        );

        uint256 grade = hotpot.getGrade(_tokenId);
        uint256 percent = grade1RewardRatio;
        if (grade == 1) {
            percent = grade1RewardRatio;
        } else if (grade == 2) {
            percent = grade2RewardRatio;
        } else if (grade == 3) {
            percent = grade3RewardRatio;
        }
        hotpot.setUse(_tokenId);
        _getReward(percent * 10);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        nonReentrant
        checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function _decreaseRewardRatio() internal {
        if (freeRewardRatio >= 10) {
            freeRewardRatio = freeRewardRatio / 2;
        }
        if (grade1RewardRatio == 20) {
            grade1RewardRatio = grade1RewardRatio - 5;
            grade2RewardRatio = grade2RewardRatio - 5;
            grade3RewardRatio = grade3RewardRatio - 5;
        }
    }

    function rescue(address payable to_, uint256 amount_) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }

    function rescue(
        address to_,
        IERC20 token_,
        uint256 amount_
    ) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        require(token_ != erc20, "must not erc20");
        require(token_ != tokenAddr, "must not this plToken");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
