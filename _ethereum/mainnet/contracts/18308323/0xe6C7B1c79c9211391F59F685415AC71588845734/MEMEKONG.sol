// SPDX-License-Identifier: NONE

import "IERC20Upgradeable.sol";
import "ERC20Upgradeable.sol";
import "SafeMathUpgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "OwnableUpgradeable.sol";
import "AddressUpgradeable.sol";

import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Router02.sol";

import "TokenEvents.sol";
import "MkongStaker.sol";

pragma solidity ^0.8.18;

contract MEMEKONG is
    IERC20Upgradeable,
    TokenEvents,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using AddressUpgradeable for address payable;

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;
    using SafeMathUpgradeable for uint16;
    using SafeMathUpgradeable for uint8;
    using SafeERC20Upgradeable for MEMEKONG;

    MkongStaker public stakerStorage;

    mapping(address => bool) public bots;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniPool;
    address public admin;

    uint256 public totalStaked;
    uint256 public burnAdjust;
    uint256 public poolBurnAdjust;
    uint internal MINUTESECONDS;
    uint internal DAYSECONDS;
    uint256 public maximumStakingAmount;
    uint256 public maxTaxAmount;
    uint private apyCount;
    uint private buyAdminPercentage;
    uint private sellAdminPercentage;
    uint private sellAdminPercentageMax;
    uint private dynamicPercentage;
    uint private minMkong;
    uint private burnPercentage;
    uint8 private _decimals;
    uint256 public UNSTAKE_TIMEOFF;
    //Eth tax additions
    uint256 public _swapTokensAmount;
    uint256 public stakingRewardsPool;

    bool private sync;
    bool internal lockContract;

    uint256 public basisPointsForLPBurn;
    bool public lpBurnEnabled;
    uint256 public lpBurnFrequency;
    uint256 public lastLpBurnTime;

    event UniSwapBuySell(
        address indexed from,
        address indexed to,
        uint value,
        uint adminCommission,
        uint burnAmount
    );

    //protects against potential reentrancy
    modifier synchronized() {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    function init(
        uint256 initialTokens,
        address _adminAccount,
        address _router,
        address _stakerStorageAddress
    ) external initializer {
        //staker storage contract definition
        MkongStaker _stakerStorage = MkongStaker(_stakerStorageAddress);
        stakerStorage = _stakerStorage;
        //burn setup
        burnAdjust = 10;
        _decimals = 9;
        poolBurnAdjust = 100;

        //stake setup
        MINUTESECONDS = 60;
        DAYSECONDS = 86400;
        maximumStakingAmount = 2e6 * 10 ** decimals();
        maxTaxAmount = 2e6 * 10 ** decimals();
        apyCount = 1251;
        buyAdminPercentage = 0;
        sellAdminPercentage = 18;
        sellAdminPercentageMax = 18;
        dynamicPercentage = 2;
        minMkong = 4000 * 10 ** decimals();
        burnPercentage = 2;
        //Eth tax additions
        _swapTokensAmount = 10000 * 10 ** 9;

        UNSTAKE_TIMEOFF = 9 * DAYSECONDS;

        //lock
        lockContract = false;
        __ERC20_init("MEME KONG", "MKONG");

        __Ownable_init(msg.sender);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;

        mintInitialTokens(initialTokens, msg.sender);
        admin = _adminAccount;

        _createUniswapPair(address(this), _router);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override(IERC20Upgradeable, ERC20Upgradeable) returns (bool) {
        _transferMkong(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(IERC20Upgradeable, ERC20Upgradeable) returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        _transferMkong(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            currentAllowance.sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        _approve(msg.sender, spender, currentAllowance.add(addedValue));
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        _approve(
            msg.sender,
            spender,
            currentAllowance.sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    //This function is only ever called on initialization to create initial supply
    function _mintMkong(address account, uint256 amount) internal {
        uint256 amt = amount;
        require(!lockContract, "TOKEN: Contract is Locked");
        require(!bots[account], "TOKEN: Your account is blacklisted!");
        super._mint(account, amt);

        emit Transfer(address(0), account, amt);
    }

    function _burnMkong(address account, uint256 amount) internal {
        require(!lockContract, "TOKEN: Contract is Locked");
        require(!bots[account], "TOKEN: Your account is blacklisted!");
        super._burn(account, amount);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal override {
        require(!lockContract, "TOKEN: Contract is Locked");

        require(
            !bots[_owner] && !bots[spender],
            "TOKEN: Your account is blacklisted!"
        );
        super._approve(_owner, spender, amount);

        emit Approval(_owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        uint256 currentAllowance = allowance(account, msg.sender);
        _burnMkong(account, amount);
        _approve(
            account,
            msg.sender,
            currentAllowance.sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }

    function _transferMkong(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(!lockContract, "TOKEN: Contract is Locked");
        require(
            !bots[sender] && !bots[recipient],
            "TOKEN: Your account is blacklisted!"
        );
        if (
            sender != owner() &&
            sender != address(this) &&
            sender != address(uniswapV2Router) &&
            sender != uniPool
        ) {
            require(amount <= maxTaxAmount, "More than Max Transaction limit");
        }
        if (sender == owner() || sender == address(this)) {
            super._transfer(sender, recipient, amount);
        } else {
            if (sender == uniPool) {
                // 1. Execute buy logic
                uint256 buyAdminCommission = amount.mul(buyAdminPercentage).div(
                    100
                );
                uint256 _taxFee = 0;
                uint256 userBuyAmount = amount.sub(buyAdminCommission);
                super._transfer(sender, address(this), buyAdminCommission);
                super._transfer(sender, recipient, userBuyAmount);
                // 2. Adjust dynamic sell tax
                if (amount >= minMkong) {
                    uint256 newSellAdminPercentage = sellAdminPercentage >
                        dynamicPercentage
                        ? sellAdminPercentage.sub(dynamicPercentage)
                        : 2;
                    sellAdminPercentage = newSellAdminPercentage;
                }
                emit UniSwapBuySell(
                    msg.sender,
                    recipient,
                    userBuyAmount,
                    buyAdminCommission,
                    _taxFee
                );
            } else if (recipient == uniPool) {
                // 1. Auto burn LP tokens
                if (
                    !sync &&
                    lpBurnEnabled &&
                    block.timestamp >= lastLpBurnTime + lpBurnFrequency
                ) {
                    autoBurnLPTokens();
                }
                // 2. Swap tokens for ETH
                uint256 contractTokenBalance = balanceOf(address(this))
                    .sub(totalStaked)
                    .sub(stakingRewardsPool);
                bool canSwap = contractTokenBalance >= _swapTokensAmount;
                if (canSwap && !sync) {
                    swapTokensForEth(_swapTokensAmount);
                }
                // 3. Execute sell logic
                uint256 sellAdminCommission = amount
                    .mul(sellAdminPercentage)
                    .div(100);
                uint256 _taxFee = amount.mul(burnPercentage).div(100);
                uint256 userSellAmount = amount.sub(_taxFee).sub(
                    sellAdminCommission
                );
                _burnMkong(sender, _taxFee);
                super._transfer(sender, address(this), sellAdminCommission);
                super._transfer(sender, recipient, userSellAmount);
                // 4. Adjust dynamic sell tax
                if (sellAdminPercentage < sellAdminPercentageMax) {
                    uint256 newSellAdminPercentage = sellAdminPercentage.add(
                        dynamicPercentage
                    );
                    sellAdminPercentage = newSellAdminPercentage <=
                        sellAdminPercentageMax
                        ? newSellAdminPercentage
                        : sellAdminPercentageMax;
                } else {
                    sellAdminPercentage = sellAdminPercentageMax;
                }

                emit UniSwapBuySell(
                    msg.sender,
                    recipient,
                    userSellAmount,
                    sellAdminCommission,
                    _taxFee
                );
            } else {
                super._transfer(sender, recipient, amount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) internal synchronized {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Perform the token swap
        try
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            // Handle error here
            emit SwapFailed(tokenAmount);
        }
    }

    //mint memekong initial tokens (only ever called in constructor)
    function mintInitialTokens(
        uint amount,
        address _owner
    ) internal synchronized {
        _mintMkong(_owner, amount);
    }

    /////////////////PUBLIC FACING - MEMEKONG CONTROL//////////
    ////////STAKING FUNCTIONS/////////
    //stake MKONG tokens to contract and claims any accrued interest

    function StakeTokens(uint amt) external synchronized {
        require(amt > 0, "zero input");
        require(
            stakerStorage.getStaker(msg.sender).stakedBalance.add(amt) <=
                maximumStakingAmount,
            "Maximum staking limit reached"
        );
        require(mkongBalance() >= amt, "Error: insufficient balance"); //ensure user has enough funds
        require(
            stakingRewardsPool > 0,
            "Error: the rewards pool is empty, further staking is not allowed"
        ); //ensure there are rewards to be claimed

        //claim any accrued interest
        _claimInterest();

        //get the current staker details
        MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
            msg.sender
        );

        //update staker details
        currentStaker.activeUser = true;
        currentStaker.stakedBalance = currentStaker.stakedBalance.add(amt);

        //save updated staker details
        stakerStorage.setStaker(msg.sender, currentStaker);

        totalStaked = totalStaked.add(amt);

        _transferMkong(msg.sender, address(this), amt); //make transfer

        emit TokenStake(msg.sender, amt);
    }

    /**
  9 days Timer will start
  **/
    function UnstakeTokens(
        uint256 _amount,
        bool isEmergency
    ) external synchronized {
        require(_amount > 0, "invalid deposit amount");
        require(
            stakerStorage.getStaker(msg.sender).stakedBalance >= _amount,
            "unstake amount is bigger than you staked"
        );

        // Calculate staking rewards
        uint256 stakingRewards = calcStakingRewards(msg.sender);

        // Only claim interest if staking rewards are less than or equal to the staking rewards pool
        if (stakingRewards <= stakingRewardsPool) {
            _claimInterest();
        }

        uint256 outAmount = _amount;
        uint fee = 0;
        uint emerAmt = 0;

        if (isEmergency == true) {
            fee = _amount.mul(9).div(100);

            emerAmt = _amount.sub(fee);
        }
        //get the current staker details
        MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
            msg.sender
        );
        currentStaker.stakedBalance = currentStaker.stakedBalance.sub(_amount);
        currentStaker.lastDepositTime = block.timestamp;

        if (isEmergency == true) {
            // send token to msg.sender.
            _transferMkong(address(this), msg.sender, emerAmt);
            _burnMkong(msg.sender, fee);
            //save updated staker details
            stakerStorage.setStaker(msg.sender, currentStaker);
            totalStaked = totalStaked.sub(_amount);
            return;
        }

        currentStaker.unstakeStartTime = block.timestamp;
        currentStaker.pendingAmount = currentStaker.pendingAmount + outAmount;

        //save updated staker details
        stakerStorage.setStaker(msg.sender, currentStaker);
    }

    // claim interest
    function ClaimStakeInterest() external synchronized {
        require(
            stakerStorage.getStaker(msg.sender).stakedBalance > 0,
            "you have no staked balance"
        );
        _claimInterest();
    }

    // claim cooled down staking amount
    function ClaimUnStakeAmount() external synchronized {
        require(
            stakerStorage.getStaker(msg.sender).pendingAmount > 0,
            "you have no pending tokens to claim"
        );
        _claimInterestUnstake();
    }

    //roll any accrued interest
    function RollStakeInterest() external synchronized {
        require(
            stakerStorage.getStaker(msg.sender).stakedBalance > 0,
            "you have no staked balance"
        );
        _rollInterest();
    }

    // Calculate Staking interest
    function _rollInterest() internal {
        uint256 interest = calcStakingRewards(msg.sender);
        if (interest > 0) {
            //get the current staker details
            MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
                msg.sender
            );
            currentStaker.stakedBalance = currentStaker.stakedBalance.add(
                interest
            );
            totalStaked = totalStaked.add(interest);
            stakingRewardsPool = stakingRewardsPool.sub(interest);
            currentStaker.totalStakingInterest += interest;
            currentStaker.stakeStartTimestamp = block.timestamp;
            //save updated staker details
            stakerStorage.setStaker(msg.sender, currentStaker);
        }
    }

    function isClaimable(address user) external view returns (bool) {
        if (stakerStorage.getStaker(user).unstakeStartTime == 0) return false;

        return
            (block.timestamp - stakerStorage.getStaker(user).unstakeStartTime >
                UNSTAKE_TIMEOFF)
                ? true
                : false;
    }

    function timeDiffForClaim(address user) external view returns (uint256) {
        return
            (stakerStorage.getStaker(user).unstakeStartTime + UNSTAKE_TIMEOFF >
                block.timestamp)
                ? stakerStorage.getStaker(user).unstakeStartTime +
                    UNSTAKE_TIMEOFF -
                    block.timestamp
                : 0;
    }

    function setUnstakeTimeoffInNumDays(uint256 timeInDays) external onlyOwner {
        UNSTAKE_TIMEOFF = timeInDays * DAYSECONDS;
    }

    function _claimInterest() internal {
        //calculate staking interest
        uint256 interest = calcStakingRewards(msg.sender);
        //get the current staker details
        MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
            msg.sender
        );
        currentStaker.stakeStartTimestamp = block.timestamp;
        if (interest > 0) {
            currentStaker.totalStakingInterest += interest;

            // uint256 tax = interest.mul(adminPercentage).div(100);
            _transferMkong(address(this), msg.sender, interest);
            stakingRewardsPool = stakingRewardsPool.sub(interest);
        }
        //save updated staker details
        stakerStorage.setStaker(msg.sender, currentStaker);
    }

    function _claimInterestUnstake() internal {
        require(
            (block.timestamp -
                stakerStorage.getStaker(msg.sender).unstakeStartTime) >=
                UNSTAKE_TIMEOFF,
            "invalid time: must be greater than 9 days"
        );

        uint256 receiveAmount = stakerStorage
            .getStaker(msg.sender)
            .pendingAmount;
        require(receiveAmount > 0, "no available amount");
        require(
            balanceOf(address(this)) >= receiveAmount,
            "Insufficient MKONG balance in staking contract"
        );

        _transferMkong(address(this), msg.sender, receiveAmount);
        totalStaked = totalStaked.sub(receiveAmount);
        //get the current staker details
        MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
            msg.sender
        );
        currentStaker.pendingAmount = 0;
        currentStaker.unstakeStartTime = block.timestamp;
        //save updated staker details
        stakerStorage.setStaker(msg.sender, currentStaker);
    }

    function _createUniswapPair(address _token, address _router) internal {
        address _factory = IUniswapV2Router02(_router).factory();
        uniPool = IUniswapV2Factory(_factory).createPair(
            _token,
            IUniswapV2Router02(_router).WETH()
        );
        require(uniPool != address(0), "Pair Address Zero");
    }

    ////////VIEW ONLY//////////////
    // totalstaked * minutesPast / 10000 / 1314 @ 4.20% APY
    function calcStakingRewards(address _user) public view returns (uint) {
        uint mkongBurnt = stakerStorage.getStaker(_user).totalBurnt;
        uint staked = stakerStorage.getStaker(_user).stakedBalance;
        uint apyAdjust = 10000;
        if (mkongBurnt > 0) {
            // if MKONG burnt is more than 90% of staked amount, 10x Apy adjustment applied
            if (mkongBurnt >= staked.sub(staked.div(10))) {
                apyAdjust = 1000;
                // If MKONG burnt is less than 90% of staked amount...
            } else {
                // calculate burnt percentage
                uint burntPercentage = ((mkongBurnt.mul(100) / staked));
                // calculate variable apy adjustment
                uint v = (apyAdjust * burntPercentage) / 100;
                apyAdjust = apyAdjust.sub(v);
                // If calculated Apy adjustment is more than 10x, cap at 10x
                if (apyAdjust < 1000) {
                    apyAdjust = 1000;
                }
            }
        }

        return (
            // Reward= (staked*minutespast/apyAdjust)/apyCount
            // Sample Reward after 30 days with no MkongBurnt=(1000000*43200 mins/10000)/1314 = 3287.67
            staked.mul(minsPastStakeTime(_user)).div(apyAdjust).div(apyCount)
        );
    }

    //returns amount of minutes past since stake start
    function minsPastStakeTime(address _user) public view returns (uint) {
        if (stakerStorage.getStaker(_user).stakeStartTimestamp == 0) {
            return 0;
        }
        uint minsPast = (block.timestamp)
            .sub(stakerStorage.getStaker(_user).stakeStartTimestamp)
            .div(MINUTESECONDS);
        if (minsPast >= 1) {
            return minsPast; // returns 0 if under 1 min passed
        } else {
            return 0;
        }
    }

    //MKONG balance of caller
    function mkongBalance() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    //MKONG rewards pooled in staking contract
    function viewStakingRewardsPool() external view returns (uint256) {
        return stakingRewardsPool;
    }

    //Current sell tax, dynamic updates
    function viewCurrentSellTax() external view returns (uint) {
        return sellAdminPercentage;
    }

    // can only burn equivalent of x10 total staking interest
    // minimize vamp bots by keeping max burn pamp slippage low
    function BurnMkong(uint amt) external synchronized {
        require(
            stakerStorage.getStaker(msg.sender).totalBurnt.add(amt) <=
                stakerStorage.getStaker(msg.sender).totalStakingInterest.mul(
                    burnAdjust
                ),
            "can only burn equivalent of x10 total staking interest"
        );
        require(amt > 0, "value must be greater than 0");
        require(balanceOf(msg.sender) >= amt, "balance too low");
        _burnMkong(msg.sender, amt);
        //get the current staker details
        MkongStaker.Staker memory currentStaker = stakerStorage.getStaker(
            msg.sender
        );
        currentStaker.totalBurnt += amt;
        //save updated staker details
        stakerStorage.setStaker(msg.sender, currentStaker);
        uint256 poolDiv = balanceOf(uniPool).div(poolBurnAdjust);

        if (poolDiv > amt) {
            _burnMkong(uniPool, amt);
        } else {
            _burnMkong(uniPool, poolDiv);
        }
        IUniswapV2Pair(uniPool).sync();
    }

    ////////OWNER ONLY//////////////
    function setUnipool(address _lpAddress) external onlyOwner {
        require(!lockContract, "cannot change native pool");
        uniPool = _lpAddress;
    }

    //adjusts amount users are eligible to burn over time
    function setBurnAdjust(uint _v) external onlyOwner {
        require(!lockContract, "cannot change burn rate");
        burnAdjust = _v;
    }

    //adjusts max % of liquidity tokens that can be burnt from pool
    function uniPoolBurnAdjust(uint _v) external onlyOwner {
        require(!lockContract, "cannot change pool burn rate");
        require(_v >= 20, "cannot set pool burn rate above 5%");
        poolBurnAdjust = _v;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function blockBots(address bot) external onlyOwner {
        require(bot != uniPool, "cannot block pool address");
        bots[bot] = true;
    }

    function unblockBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    function lockTrading() external onlyOwner {
        lockContract = true;
    }

    function unlockTrading() external onlyOwner {
        lockContract = false;
    }

    function apyUnique(uint _unique) external onlyOwner {
        apyCount = _unique;
    }

    function setBuyAdminCommission(uint _per) external onlyOwner {
        require(_per <= 25, "cannot set buy tax above 25%");
        buyAdminPercentage = _per;
    }

    function setSellAdminCommission(uint _per) external onlyOwner {
        require(_per <= 25, "cannot set sell tax above 25%");
        sellAdminPercentage = _per;
    }

    function setSellAdminPercentageMax(uint _per) external onlyOwner {
        require(_per <= 25, "cannot set dynamic sell tax above 25%");
        sellAdminPercentageMax = _per;
    }

    function setDynamicPercentage(uint _per) external onlyOwner {
        dynamicPercentage = _per;
    }

    function setMinMkong(uint _amt) external onlyOwner {
        minMkong = _amt * 10 ** decimals();
    }

    function setBurnPercentage(uint _per) external onlyOwner {
        require(_per <= 25, "cannot set burn percentage above 25%");
        burnPercentage = _per;
    }

    function setMaxTransactionAmount(uint _amt) external onlyOwner {
        require(
            _amt >= 10000000000000,
            "cannot set max transaction below 10k MKONG"
        );
        maxTaxAmount = _amt;
    }

    function addToStakingRewardsPool(uint _amt) external onlyOwner {
        _transferMkong(msg.sender, address(this), _amt);
        stakingRewardsPool += _amt;
    }

    // Function to allow admin to claim ERC20 tokens sent to this contract (by mistake)
    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint128 _amount
    ) external onlyOwner {
        // If the token to be rescued is the native token of this contract
        if (_tokenAddr == address(this)) {
            uint256 balanceBeforeTransfer = IERC20Upgradeable(_tokenAddr)
                .balanceOf(address(this));
            uint256 totalReserved = totalStaked + stakingRewardsPool;

            require(
                balanceBeforeTransfer - _amount >= totalReserved,
                "Cannot withdraw more than available balance after accounting for staked and reward pool tokens"
            );
        }

        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(_tokenAddr),
            _to,
            _amount
        );
    }

    function setUniswapRouterAddress(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Invalid Address");
        uniswapV2Router = IUniswapV2Router02(_newRouter);
    }

    //Eth tax additions
    function setSwapTokensAmount(uint256 amount) external onlyOwner {
        _swapTokensAmount = amount;
    }

    receive() external payable {
        // Optional: Add any custom logic to handle the received ETH
    }

    function sendEthToAdmin(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");

        address payable adminWallet = payable(admin);

        adminWallet.transfer(amount);
    }

    function autoBurnLPTokens() internal synchronized returns (bool) {
        lastLpBurnTime = block.timestamp;
        uint256 lpBalance = balanceOf(uniPool);
        uint256 amountToBurn = lpBalance.mul(basisPointsForLPBurn).div(10000);

        if (amountToBurn > 0) {
            _burnMkong(uniPool, amountToBurn);
        }

        // Use try-catch specifically for the external call
        try IUniswapV2Pair(uniPool).sync() {
            // Successful sync
        } catch {
            emit AutoBurnFailed(amountToBurn);
            return false; // Indicate that the auto burn failed
        }

        return true;
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _basisPoints,
        bool _enabled
    ) external onlyOwner {
        require(
            _basisPoints <= 500 && _basisPoints >= 0,
            "Must set auto LP burn percent between 0% and 5%"
        );
        require(
            _frequencyInSeconds >= 600,
            "Frequency cannot be less than 10 minutes"
        );
        lpBurnFrequency = _frequencyInSeconds;
        basisPointsForLPBurn = _basisPoints;
        lpBurnEnabled = _enabled;
    }
}
