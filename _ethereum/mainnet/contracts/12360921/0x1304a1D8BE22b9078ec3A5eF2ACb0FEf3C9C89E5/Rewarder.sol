// SPDX-License-Identifier: MIT
/*

██████╗ ███████╗██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║█████╗  ██████╔╝███████║███████╗█████╗  
██║  ██║██╔══╝  ██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝███████╗██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                               

* Debase: ExpansionRewarder.sol
* Description:
* Pool that pool the issues rewards on expansions of debase supply
* Coded by: punkUnknown
*/

pragma solidity >=0.6.6;

import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public y;

    function setStakeToken(address _y) internal {
        y = IERC20(_y);
    }

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
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        y.safeTransfer(msg.sender, amount);
    }
}

contract Rewarder is Ownable, LPTokenWrapper, ReentrancyGuard {
    using Address for address;

    event LogEmergencyWithdraw(uint256 number);
    event LogSetRewardPercentage(uint256 rewardPercentage_);
    event LogSetBlockDuration(uint256 duration_);
    event LogSetPoolEnabled(bool poolEnabled_);
    event LogStartNewDistribtionCycle(
        uint256 amount_,
        uint256 rewardRateDebaseExpansion_,
        uint256 rewardRateDebaseContraction,
        uint256 cycleEnds_
    );
    event LogSetContractionRewardRatePercentage(
        uint256 contractionRewardRatePercentage_
    );

    event LogSetRewardRate(uint256 rewardRate_);
    event LogSetEnableUserLpLimit(bool enableUserLpLimit_);
    event LogSetEnablePoolLpLimit(bool enablePoolLpLimit_);
    event LogSetUserLpLimit(uint256 userLpLimit_);
    event LogSetPoolLpLimit(uint256 poolLpLimit_);

    event LogRewardAdded(uint256 reward);
    event LogStaked(address indexed user, uint256 amount);
    event LogWithdrawn(address indexed user, uint256 amount);
    event LogSetMultiSigPercentage(uint256 multiSigReward_);
    event LogSetMultiSigAddress(address multiSigAddress_);

    IERC20 public debase;
    IERC20 public mph88;
    IERC20 public crv;

    address public policy;
    uint256 public blockDuration;
    bool public poolEnabled;

    uint256 public periodFinish;
    uint256 rewardRateDebase;
    uint256 rewardRateDebaseExpansion;
    uint256 rewardRateDebaseContraction;
    uint256 public contractionRewardRatePercentage;

    uint256 rewardRateMPH;
    uint256 rewardRateCRV;
    uint256 lastUpdateBlock;
    uint256 rewardPerTokenStoredDebase;
    uint256 rewardPerTokenStoredMPH;
    uint256 rewardPerTokenStoredCRV;

    uint256 public rewardPercentage;
    uint256 public rewardDistributedDebase;
    uint256 public rewardDistributedMPH;
    uint256 public rewardDistributedCRV;
    uint256 public mph88Reward;
    uint256 public crvReward;

    uint256 public multiSigRewardPercentage;
    uint256 public multiSigRewardShare;
    address public multiSigRewardAddress;

    mapping(address => uint256) userRewardPerTokenPaidDebase;
    mapping(address => uint256) userRewardPerTokenPaidMPH;
    mapping(address => uint256) userRewardPerTokenPaidCRV;

    mapping(address => uint256) public rewardsDebase;
    mapping(address => uint256) public rewardsMPH;
    mapping(address => uint256) public rewardsCRV;

    modifier enabled() {
        require(poolEnabled, "Pool isn't enabled");
        _;
    }

    modifier updateReward(address account) {
        (
            rewardPerTokenStoredDebase,
            rewardPerTokenStoredMPH,
            rewardPerTokenStoredCRV
        ) = rewardPerToken();

        lastUpdateBlock = lastBlockRewardApplicable();
        if (account != address(0)) {
            (
                rewardsDebase[account],
                rewardsMPH[account],
                rewardsCRV[account]
            ) = earned(account);

            userRewardPerTokenPaidDebase[account] = rewardPerTokenStoredDebase;
            userRewardPerTokenPaidMPH[account] = rewardPerTokenStoredMPH;
            userRewardPerTokenPaidCRV[account] = rewardPerTokenStoredCRV;
        }
        _;
    }

    function setContractionRewardRatePercentage(
        uint256 contractionRewardRatePercentage_
    ) external onlyOwner {
        contractionRewardRatePercentage = contractionRewardRatePercentage_;
        emit LogSetContractionRewardRatePercentage(
            contractionRewardRatePercentage
        );
    }

    /**
     * @notice Function to set how much reward the stabilizer will request
     */
    function setRewardPercentage(uint256 rewardPercentage_) external onlyOwner {
        rewardPercentage = rewardPercentage_;
        emit LogSetRewardPercentage(rewardPercentage);
    }

    /**
     * @notice Function to set multiSig reward percentage
     */
    function setMultiSigReward(uint256 multiSigRewardPercentage_)
        external
        onlyOwner
    {
        multiSigRewardPercentage = multiSigRewardPercentage_;
        emit LogSetMultiSigPercentage(multiSigRewardPercentage);
    }

    /**
     * @notice Function to set multisig address
     */
    function setMultiSigAddress(address multiSigRewardAddress_)
        external
        onlyOwner
    {
        multiSigRewardAddress = multiSigRewardAddress_;
        emit LogSetMultiSigAddress(multiSigRewardAddress);
    }

    /**
     * @notice Function to set reward drop period
     */
    function setblockDuration(uint256 blockDuration_) external onlyOwner {
        require(blockDuration >= 1);
        blockDuration = blockDuration_;
        emit LogSetBlockDuration(blockDuration);
    }

    /**
     * @notice Function enabled or disable pool staking,withdraw
     */
    function setPoolEnabled(bool poolEnabled_) external onlyOwner {
        poolEnabled = poolEnabled_;
        emit LogSetPoolEnabled(poolEnabled);
    }

    function setMPH88Reward(uint256 mph88Reward_) external onlyOwner {
        mph88Reward = mph88Reward_;
    }

    function setCRVReward(uint256 crvReward_) external onlyOwner {
        crvReward = crvReward_;
    }

    constructor(
        IERC20 debase_,
        IERC20 mph88_,
        IERC20 crv_,
        address pairToken_,
        address policy_,
        uint256 rewardPercentage_,
        uint256 blockDuration_,
        uint256 multiSigRewardPercentage_,
        address multiSigRewardAddress_,
        uint256 contractionRewardRatePercentage_
    ) public {
        setStakeToken(pairToken_);
        debase = debase_;
        mph88 = mph88_;
        crv = crv_;

        policy = policy_;

        blockDuration = blockDuration_;
        rewardPercentage = rewardPercentage_;

        multiSigRewardPercentage = multiSigRewardPercentage_;
        multiSigRewardAddress = multiSigRewardAddress_;
        contractionRewardRatePercentage = contractionRewardRatePercentage_;
    }

    function checkStabilizerAndGetReward(
        int256 supplyDelta_,
        int256 rebaseLag_,
        uint256 exchangeRate_,
        uint256 debasePolicyBalance
    ) external returns (uint256 rewardAmount_) {
        require(
            msg.sender == policy,
            "Only debase policy contract can call this"
        );

        if (multiSigRewardShare != 0) {
            debase.safeTransfer(
                multiSigRewardAddress,
                debase.totalSupply().mul(multiSigRewardShare).div(10**18)
            );
            multiSigRewardShare = 0;
        }

        if (block.number >= periodFinish) {
            uint256 rewardAmount =
                debasePolicyBalance.mul(rewardPercentage).div(10**18);

            uint256 multiSigRewardClaim =
                rewardAmount.mul(multiSigRewardPercentage).div(10**18);

            multiSigRewardShare = multiSigRewardClaim.mul(10**18).div(
                debase.totalSupply()
            );

            uint256 totalRewardAmount = multiSigRewardClaim.add(rewardAmount);

            if (debasePolicyBalance >= totalRewardAmount) {
                startNewDistribtionCycle(supplyDelta_, rewardAmount);
                return totalRewardAmount;
            }
        } else {
            if (
                supplyDelta_ >= 0 &&
                rewardRateDebase != rewardRateDebaseExpansion
            ) {
                changeRewardRate(rewardRateDebaseExpansion);
            } else if (
                supplyDelta_ < 0 &&
                rewardRateDebase != rewardRateDebaseContraction
            ) {
                changeRewardRate(rewardRateDebaseContraction);
            }
        }
        return 0;
    }

    /**
     * @notice Function allows for emergency withdrawal of all reward tokens back into stabilizer fund
     */
    function emergencyWithdraw() external onlyOwner {
        debase.safeTransfer(policy, debase.balanceOf(address(this)));
        mph88.safeTransfer(policy, mph88.balanceOf(address(this)));
        crv.safeTransfer(policy, crv.balanceOf(address(this)));
        emit LogEmergencyWithdraw(block.number);
    }

    function lastBlockRewardApplicable() internal view returns (uint256) {
        return Math.min(block.number, periodFinish);
    }

    function rewardPerToken()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (totalSupply() == 0) {
            return (
                rewardPerTokenStoredDebase,
                rewardPerTokenStoredMPH,
                rewardPerTokenStoredCRV
            );
        }

        uint256 result = lastBlockRewardApplicable().sub(lastUpdateBlock);

        return (
            rewardPerTokenStoredDebase.add(
                result.mul(rewardRateDebase).mul(10**18).div(totalSupply())
            ),
            rewardPerTokenStoredMPH.add(
                result.mul(rewardRateMPH).mul(10**18).div(totalSupply())
            ),
            rewardPerTokenStoredCRV.add(
                result.mul(rewardRateCRV).mul(10**18).div(totalSupply())
            )
        );
    }

    function earned(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 balance = balanceOf(account);
        (
            uint256 rewardPerTokenDebase,
            uint256 rewardPerTokenMPH,
            uint256 rewardPerTokenCRV
        ) = rewardPerToken();

        return (
            calculateEarned(
                balance,
                rewardPerTokenDebase,
                userRewardPerTokenPaidDebase[account],
                rewardsDebase[account]
            ),
            calculateEarned(
                balance,
                rewardPerTokenMPH,
                userRewardPerTokenPaidMPH[account],
                rewardsMPH[account]
            ),
            calculateEarned(
                balance,
                rewardPerTokenCRV,
                userRewardPerTokenPaidCRV[account],
                rewardsCRV[account]
            )
        );
    }

    function calculateEarned(
        uint256 balance,
        uint256 rewardPerToken_,
        uint256 userRewardPerTokenPaid_,
        uint256 rewards_
    ) internal pure returns (uint256) {
        return
            balance
                .mul(rewardPerToken_.sub(userRewardPerTokenPaid_))
                .div(10**18)
                .add(rewards_);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
        enabled
    {
        require(
            !address(msg.sender).isContract(),
            "Caller must not be a contract"
        );
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit LogStaked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit LogWithdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public nonReentrant updateReward(msg.sender) enabled {
        (uint256 earnedDebase, uint256 earnedMPH, uint256 earnedCRV) =
            earned(msg.sender);

        if (earnedDebase > 0) {
            rewardsDebase[msg.sender] = 0;

            uint256 rewardToClaim =
                debase.totalSupply().mul(earnedDebase).div(10**18);

            debase.safeTransfer(msg.sender, rewardToClaim);
            rewardDistributedDebase = rewardDistributedDebase.add(earnedDebase);
        }

        if (earnedMPH > 0) {
            rewardsMPH[msg.sender] = 0;
            mph88.safeTransfer(msg.sender, earnedMPH);
            rewardDistributedMPH = rewardDistributedMPH.add(earnedMPH);
        }

        if (earnedCRV > 0) {
            rewardsCRV[msg.sender] = 0;
            crv.safeTransfer(msg.sender, earnedCRV);
            rewardDistributedCRV = rewardDistributedDebase.add(earnedCRV);
        }
    }

    function changeRewardRate(uint256 rewardRateDebase_)
        internal
        updateReward(address(0))
    {
        rewardRateDebase = rewardRateDebase_;
        emit LogSetRewardRate(rewardRateDebase);
    }

    function startNewDistribtionCycle(int256 supplyDelta_, uint256 amount)
        internal
        updateReward(address(0))
    {
        // https://sips.synthetix.io/sips/sip-77
        require(
            amount < uint256(-1) / 10**18,
            "Rewards: rewards too large, would lock"
        );

        uint256 rewardShare = amount.mul(10**18).div(debase.totalSupply());

        rewardRateDebaseExpansion = rewardShare.div(blockDuration);
        rewardRateDebaseContraction = rewardRateDebaseExpansion
            .mul(contractionRewardRatePercentage)
            .div(10**18);

        rewardRateMPH = mph88Reward.div(blockDuration);
        rewardRateCRV = crvReward.div(blockDuration);

        mph88Reward = 0;
        crvReward = 0;

        if (supplyDelta_ >= 0) {
            rewardRateDebase = rewardRateDebaseExpansion;
        } else {
            rewardRateDebase = rewardRateDebaseContraction;
        }

        periodFinish = block.number.add(blockDuration);
        lastUpdateBlock = block.number;

        emit LogStartNewDistribtionCycle(
            amount,
            rewardRateDebaseExpansion,
            rewardRateDebaseContraction,
            periodFinish
        );
    }
}
