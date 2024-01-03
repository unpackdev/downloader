// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./IDRF.sol";

contract DRFLord is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed account, uint256 ethAmount, uint256 lpAmount);
    event Withdrawn(address indexed account, uint256 drfAmount, uint256 ethAmount, uint256 lpAmount);
    event Claimed(address indexed account, uint256 ethAmount, uint256 lpAmount);
    event Halved(uint256 rewardAllocation);
    event Rebalanced();
    event SwappedSDRF(uint256 amount);

    bool private _initialized;

    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router02 uniswapRouter;
    address weth;
    address drf;
    address sdrf;
    address sdrfFarm;
    address payable devTreasury;
    address pairAddress;

    bool public isFarmOpen = false;
    uint256 public farmOpenTime;

    uint256 private constant MAX = uint256(- 1);
    uint256 public constant INITIAL_PRICE = 4000;
    uint256 public maxStake = 25 ether;

    uint256 public rewardAllocation;
    uint256 public rewardRate;
    uint256 public constant rewardDuration = 15 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public finishTime;

    struct AccountInfo {
        uint256 balance;
        uint256 peakBalance;
        uint256 withdrawTime;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }

    /// @notice Account info
    mapping(address => AccountInfo) public accountInfos;

    /// @notice Peak LP token balance
    uint256 public peakPairTokenBalance;

    /// @dev Total staked token
    uint256 private _totalSupply;

    /// @notice Principal supply is used to generate perpetual yield
    /// @dev Used to give liquidity provider in liquidity pair rewards
    /// If this value is not zero, it means the principal is not used, and still exist in lord contract
    uint256 public principalSupply;

    /// @notice Marketing funds
    uint256 public marketingSupply;

    /// @notice Sale supply
    uint256 public saleSupply;

    /// @notice Lend supply
    uint256 public lendSupply;

    /// @notice Swappable DRF for sDRF
    uint256 public swappableSupply;

    /// @notice Deposited DRF from SDRF Farm
    uint256 public sdrfFarmDepositSupply;

    /// @notice Burned supply that locked forever
    uint256 public burnSupply;

    /// @notice Drift liquidity threshold
    uint256 public driftThreshold = 75;

    /// @notice Brake liquidity threshold
    uint256 public brakeThreshold = 50;

    /// @notice Last rebalance time
    uint256 public rebalanceTime;

    /// @notice rebalance waiting time
    uint256 public rebalanceWaitingTime = 1 hours;

    /// @notice Min balance to receive reward as rebalance caller
    uint256 public rebalanceRewardMinBalance = 1000e18;

    enum State {Normal, Drift, Brake}
    struct StateInfo {
        uint256 reflectFeeDenominator;
        uint256 buyTxFeeDenominator;
        uint256 sellTxFeeDenominator;
        uint256 buyBonusDenominator;
        uint256 sellFeeDenominator;
        uint256 rebalanceRewardDenominator;
        uint256 buyBackDenominator;
    }

    /// @notice Current state
    State public state;
    /// @notice State info
    mapping(State => StateInfo) public stateInfo;
    /// @notice Last state time
    uint256 public stateActivatedTime;

    /// @notice Token to pair with DRF when generating liquidity
    address public liquidityToken;
    /// @notice If set, LP provider for this liquidity will receive rewards.
    /// Usually DRF-PartnerToken
    address public liquidityPairToken;

    /// @dev Added to receive ETH when remove liquidity on Uniswap
    receive() external payable {
    }

    constructor(address _uniswapRouter, address _drf, address _sdrf, uint256 _farmOpenTime) public {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
        drf = _drf;
        sdrf = _sdrf;
        pairAddress = uniswapFactory.createPair(drf, weth);
        farmOpenTime = _farmOpenTime;
        devTreasury = msg.sender;
        liquidityToken = weth;

        // 5% from total supply
        principalSupply = 500000e18;
        // 5% from total supply
        marketingSupply = 500000e18;
        // Sale supply
        saleSupply = 4000000e18;
        // Lend supply for lp provider
        lendSupply = 2000000e18;
        // Farming allocation / 2
        rewardAllocation = 1500000e18;

        // Approve uniswap router to spend weth
        approveUniswap(weth);
        // Approve uniswap router to spend drf
        approveUniswap(drf);
        // Approve uniswap router to spend lp token
        approveUniswap(pairAddress);

        // Initialize
        lastUpdateTime = farmOpenTime;
        finishTime = farmOpenTime.add(rewardDuration);
        rewardRate = rewardAllocation.div(rewardDuration);
        rebalanceTime = farmOpenTime;
    }

    /* ========== Modifiers ========== */

    modifier onlySDRFFarm {
        require(msg.sender == sdrfFarm, 'Only farm');
        _;
    }

    modifier farmOpen {
        require(isFarmOpen, 'Farm not open');
        _;
    }

    modifier checkOpenFarm()  {
        require(farmOpenTime <= block.timestamp, 'Farm not open');
        if (!isFarmOpen) {
            // Set flag
            isFarmOpen = true;
        }
        _;
    }

    modifier checkHalving() {
        if (block.timestamp >= finishTime) {
            // Halved reward
            rewardAllocation = rewardAllocation.div(2);
            // Calculate reward rate
            rewardRate = rewardAllocation.div(rewardDuration);
            // Set finish time
            finishTime = block.timestamp.add(rewardDuration);
            // Set last update time
            lastUpdateTime = block.timestamp;
            // Emit event
            emit Halved(rewardAllocation);
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].reward = earned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /* ========== Only Owner ========== */

    function init(address _sdrfFarm) external onlyOwner {
        // Make sure we can only init one time
        if (!_initialized) {
            // Set flag
            _initialized = true;
            // Set farm
            sdrfFarm = _sdrfFarm;
            // 1.5% reflect, 0.5% buy reserve, 0.5% sell reserve, 4% buy bonus, 2% sell fee, (5% lock liquidity reward from reserve), 12.5% buy back
            setStateInfo(State.Normal, 67, 200, 200, 25, 50, 20, 8, false);
            // 1% reflect, 1% buy reserve, 1% sell reserve, 6.25% buy bonus, 2% sell fee, (4% lock liquidity reward from reserve), 20% buy back
            setStateInfo(State.Drift, 100, 100, 100, 16, 50, 25, 5, false);
            // 1% reflect, 1% buy reserve, 5% sell reserve, 8% buy bonus, 2% sell fee, (3% lock liquidity reward from reserve), 50% buy back
            setStateInfo(State.Brake, 100, 100, 20, 12, 50, 33, 2, false);
            // Apply fee
            _applyStateFee();
        }
    }

    function setStateInfo(
        State _state,
        uint256 _reflectFeeDenominator,
        uint256 _buyTxFeeDenominator,
        uint256 _sellTxFeeDenominator,
        uint256 _buyBonusDenominator,
        uint256 _sellFeeDenominator,
        uint256 _rebalanceRewardDenominator,
        uint256 _buyBackDenominator,
        bool applyImmediately
    ) public onlyOwner {
        // Make sure fee is valid
        require(_reflectFeeDenominator >= 10, 'Invalid denominator');
        require(_buyTxFeeDenominator >= 10, 'Invalid denominator');
        require(_sellTxFeeDenominator >= 10, 'Invalid denominator');
        require(_buyBonusDenominator >= 10, 'Invalid denominator');
        require(_sellFeeDenominator >= 10, 'Invalid denominator');
        require(_rebalanceRewardDenominator >= 10, 'Invalid denominator');
        require(_buyBackDenominator > 0, 'Invalid denominator');

        stateInfo[_state].reflectFeeDenominator = _reflectFeeDenominator;
        stateInfo[_state].buyTxFeeDenominator = _buyTxFeeDenominator;
        stateInfo[_state].sellTxFeeDenominator = _sellTxFeeDenominator;
        stateInfo[_state].buyBonusDenominator = _buyBonusDenominator;
        stateInfo[_state].sellFeeDenominator = _sellFeeDenominator;
        stateInfo[_state].rebalanceRewardDenominator = _rebalanceRewardDenominator;
        stateInfo[_state].buyBackDenominator = _buyBackDenominator;

        if (applyImmediately) {
            _applyStateFee();
        }
    }

    function setMaxStake(uint256 _maxStake) external onlyOwner {
        maxStake = _maxStake;
    }

    function setStateThreshold(uint256 _driftThreshold, uint256 _brakeThreshold) external onlyOwner {
        driftThreshold = _driftThreshold;
        brakeThreshold = _brakeThreshold;
    }

    function setRebalanceWaitingTime(uint256 _waitingTime) external onlyOwner {
        rebalanceWaitingTime = _waitingTime;
    }

    function setRebalanceRewardMinBalance(uint256 _minBalance) external onlyOwner {
        rebalanceRewardMinBalance = _minBalance;
    }

    function setLiquidityToken(address _liquidityToken) external onlyOwner {
        liquidityToken = _liquidityToken;
    }

    function setLiquidityPairAddress(address _liquidityPairToken) external onlyOwner {
        liquidityPairToken = _liquidityPairToken;
    }

    function depositPrincipalSupply() public onlyOwner {
        if (principalSupply > 0) {
            IDRF(drf).depositPrincipalSupply(principalSupply);
            principalSupply = 0;
        }
    }

    function withdrawPrincipalSupply() public onlyOwner {
        if (principalSupply == 0) {
            principalSupply = IDRF(drf).withdrawPrincipalSupply();
        }
    }

    function withdrawMarketingSupply(address recipient, uint256 amount) external onlyOwner {
        require(marketingSupply > 0, 'No supply');
        marketingSupply = marketingSupply.sub(amount);
        IERC20(drf).transfer(recipient, amount);
    }

    function approveUniswap(address token) public onlyOwner {
        IERC20(token).approve(address(uniswapRouter), MAX);
    }

    function connectLiquidityToken(address _liquidityToken, address _liquidityPairToken) external onlyOwner {
        liquidityToken = _liquidityToken;
        liquidityPairToken = _liquidityPairToken;
        depositPrincipalSupply();

        // Approve uniswap to spend liquidity token
        approveUniswap(liquidityToken);
        approveUniswap(liquidityPairToken);
    }

    function disconnectLiquidityToken() external onlyOwner {
        liquidityToken = weth;
        liquidityPairToken = address(0);
        withdrawPrincipalSupply();
    }

    /* ========== Only SDRF Farm ========== */

    function depositFromSDRFFarm(address sender, uint256 amount) external onlySDRFFarm {
        // Transfer from sender
        IERC20(drf).transferFrom(sender, address(this), amount);
        // Increase deposit
        sdrfFarmDepositSupply = sdrfFarmDepositSupply.add(amount);
    }

    function redeemFromSDRFFarm(address recipient, uint256 amount) external onlySDRFFarm {
        require(sdrfFarmDepositSupply >= amount, 'Insufficient supply');
        // Reduce first
        sdrfFarmDepositSupply = sdrfFarmDepositSupply.sub(amount);
        // Transfer to recipient
        IERC20(drf).transfer(recipient, amount);
    }

    /* ========== Mutative ========== */

    /// @notice Stake ETH.
    function stake() external payable nonReentrant checkOpenFarm checkHalving updateReward(msg.sender) {
        _stake(msg.sender, msg.value);
    }

    /// @notice Stake ETH.
    function stakeTo(address recipient) external payable nonReentrant checkOpenFarm checkHalving updateReward(msg.sender) {
        _stake(recipient, msg.value);
    }

    /// @notice Withdraw LP.
    function withdraw(uint256 amount) external nonReentrant farmOpen checkHalving updateReward(msg.sender) {
        _withdraw(msg.sender, msg.sender, amount);
    }

    /// @notice Withdraw LP.
    function withdrawTo(address payable recipient, uint256 amount) external nonReentrant farmOpen checkHalving updateReward(msg.sender) {
        _withdraw(msg.sender, recipient, amount);
    }

    /// @notice Claim reward
    function claimReward() external nonReentrant farmOpen checkHalving updateReward(msg.sender) returns (uint256 net, uint256 tax) {
        (net, tax) = _claimReward(msg.sender, msg.sender);
    }

    /// @notice Claim reward
    function claimRewardTo(address recipient) external nonReentrant farmOpen checkHalving updateReward(msg.sender) returns (uint256 net, uint256 tax) {
        (net, tax) = _claimReward(msg.sender, recipient);
    }

    /// @notice Rebalance
    function rebalance() external {
        // Let's wait before releasing liquidity
        require(rebalanceTime.add(rebalanceWaitingTime) <= block.timestamp, 'Too soon');
        // Update time
        rebalanceTime = block.timestamp;

        // If there is no principal in this contract, it means the principal is actually being used
        if (principalSupply == 0) {
            // Distribute principal rewards for liquidity provider or reserve supply
            IDRF(drf).distributePrincipalRewards(liquidityPairToken);
        }

        // Get reserve supply to be locked as liquidity
        uint256 liquiditySupply = IDRF(drf).reserveSupply();
        // If there is supply
        if (liquiditySupply > 0) {
            // If sender has required DRF, give reward
            if (IERC20(drf).balanceOf(msg.sender) >= rebalanceRewardMinBalance) {
                // Calc reward for msg sender
                uint256 senderReward = liquiditySupply.div(stateInfo[state].rebalanceRewardDenominator);
                // Reduce first
                liquiditySupply = liquiditySupply.sub(senderReward);
                // Send reward
                IERC20(drf).transfer(msg.sender, senderReward);
            }

            // If we are not in brake state, we can provide other token liquidity
            // otherwise enforce DRF-ETH
            address token = state != State.Brake ? liquidityToken : weth;

            uint256 drfDust;
            // Add liquidity DRF-Token. Default is DRF-WETH
            if (token == weth) {
                (drfDust,) = _addLiquidityDRFETH(liquiditySupply);
                // Adjust reserve supply
                IDRF(drf).setReserveSupply(drfDust);
                // Check if should change state
                _checkState();
            } else {
                uint256 tokenDust;
                (drfDust, tokenDust,) = _addLiquidityToken(drf, token, liquiditySupply);
                // Adjust reserve supply
                IDRF(drf).setReserveSupply(drfDust);
                // Send dust out
                IERC20(liquidityToken).transfer(devTreasury, tokenDust);
            }
        }

        // If we have good amount of ETH
        if (address(this).balance > 0.01 ether) {
            // Buy back and burn
            _buyBack();
        }

        emit Rebalanced();
    }

    /// @notice Swap SDRF to DRF
    function swap(uint256 amount) external {
        require(state != State.Brake, 'Swap disabled');
        require(swappableSupply >= amount, 'Insufficient supply');

        // Reduce swappable supply
        swappableSupply = swappableSupply.sub(amount);
        // Receive sDRF
        IERC20(sdrf).transferFrom(msg.sender, address(this), amount);
        // Transfer DRF
        IERC20(drf).transfer(msg.sender, amount);
        // Emit event
        emit SwappedSDRF(amount);
    }

    /* ========== Private ========== */

    function _stake(address recipient, uint256 ethAmount) private {
        require(ethAmount > 0, 'Cannot stake 0');
        require(ethAmount <= maxStake, 'Max stake reached');

        // 10% compensation fee
        uint256 fee = ethAmount.div(10);
        ethAmount = ethAmount.sub(fee);
        devTreasury.transfer(fee);

        uint256 pairETHBalance = IERC20(weth).balanceOf(pairAddress);
        uint256 pairDRFBalance = IERC20(drf).balanceOf(pairAddress);
        // If eth amount = 0 then set initial price
        uint256 drfAmount = pairETHBalance == 0 ? ethAmount.mul(INITIAL_PRICE) : ethAmount.mul(pairDRFBalance).div(pairETHBalance);

        // If there is still sale supply
        if (saleSupply > 0) {
            // Get sale amount
            uint256 saleAmount = drfAmount > saleSupply ? saleSupply : drfAmount;
            // Reduce sale supply
            saleSupply = saleSupply.sub(saleAmount);
            // Send DRF to recipient
            IERC20(drf).transfer(recipient, saleAmount);
        }

        drfAmount = drfAmount.div(2);
        uint256 pairTokenAmount;

        if (lendSupply >= drfAmount) {
            // Use half of eth
            ethAmount = ethAmount.div(2);
            // Reduce DRF can be lend
            lendSupply = lendSupply.sub(drfAmount);
            // Add liquidity in uniswap
            (,, pairTokenAmount) = uniswapRouter.addLiquidityETH{value : ethAmount}(drf, drfAmount, 0, 0, address(this), MAX);
        } else {
            uint256 wethDust;
            IWETH(weth).deposit{value : ethAmount}();
            (wethDust,, pairTokenAmount) = _addLiquidityToken(weth, drf, ethAmount);
            IWETH(weth).withdraw(wethDust);
        }

        // Add to balance
        accountInfos[recipient].balance = accountInfos[recipient].balance.add(pairTokenAmount);
        // Set peak balance
        if (accountInfos[recipient].balance > accountInfos[recipient].peakBalance) {
            accountInfos[recipient].peakBalance = accountInfos[recipient].balance;
        }
        // Set stake timestamp as withdraw time to prevent withdraw immediately after first staking
        if (accountInfos[recipient].withdrawTime == 0) {
            accountInfos[recipient].withdrawTime = block.timestamp;
        }

        // Increase total supply
        _totalSupply = _totalSupply.add(pairTokenAmount);
        // Set peak pair token balance
        uint256 pairTokenBalance = IERC20(pairAddress).balanceOf(address(this));
        if (pairTokenBalance > peakPairTokenBalance) {
            peakPairTokenBalance = pairTokenBalance;
        }

        // Check if should change state
        _checkState();

        emit Staked(recipient, ethAmount, pairTokenAmount);
    }

    function _withdraw(address sender, address payable recipient, uint256 amount) private {
        require(state != State.Brake, 'Withdraw disabled');
        require(amount > 0 && amount <= maxWithdrawOf(sender), 'Invalid withdraw');
        require(amount <= accountInfos[sender].balance, 'Insufficient balance');

        // Reduce balance
        accountInfos[sender].balance = accountInfos[sender].balance.sub(amount);
        // Set withdraw time
        accountInfos[sender].withdrawTime = block.timestamp;
        // Reduce total supply
        _totalSupply = _totalSupply.sub(amount);

        // Remove liquidity in uniswap
        (uint256 drfAmount, uint256 ethAmount) = uniswapRouter.removeLiquidity(drf, weth, amount, 0, 0, address(this), MAX);
        // Send DRF to recipient
        IERC20(drf).transfer(recipient, drfAmount);
        // Withdraw ETH and send to recipient
        IWETH(weth).withdraw(ethAmount);
        recipient.transfer(ethAmount);

        // Check if should change state
        _checkState();

        emit Withdrawn(recipient, drfAmount, ethAmount, amount);
    }

    function _claimReward(address sender, address recipient) private returns (uint256 net, uint256 tax) {
        uint256 reward = accountInfos[sender].reward;
        require(reward > 0, 'No reward');

        // Reduce reward first
        accountInfos[sender].reward = 0;

        // Calculate tax and net
        tax = taxForReward(reward);
        net = reward.sub(tax);

        // Add tax to swappable reserve
        swappableSupply = swappableSupply.add(tax);

        // Send drf as reward
        IDRF(drf).transfer(recipient, net);

        emit Claimed(recipient, net, tax);
    }

    /// @notice Check if should change state based on liquidity
    function _checkState() private {
        uint256 pairTokenBalance = IERC20(pairAddress).balanceOf(address(this));
        uint256 baseThreshold = peakPairTokenBalance.div(100);
        uint256 driftStateThreshold = baseThreshold.mul(driftThreshold);
        uint256 brakeStateThreshold = baseThreshold.mul(brakeThreshold);

        // If drift state already run for 1 day, and liquidity high enough
        if (state == State.Drift && stateActivatedTime.add(1 days) <= block.timestamp && pairTokenBalance > driftStateThreshold) {
            state = State.Normal;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If brake state already run for 1 day, and liquidity high enough
        else if (state == State.Brake && stateActivatedTime.add(1 days) <= block.timestamp && pairTokenBalance > brakeStateThreshold) {
            state = State.Drift;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If liquidity reached drift state from normal state
        else if (state == State.Normal && pairTokenBalance <= driftStateThreshold) {
            state = State.Drift;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If liquidity reached brake state from drift state
        else if (state == State.Drift && pairTokenBalance <= brakeStateThreshold) {
            state = State.Brake;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
    }

    /// @notice Apply fee to DRF token
    function _applyStateFee() private {
        IDRF(drf).setFee(
            stateInfo[state].reflectFeeDenominator,
            stateInfo[state].buyTxFeeDenominator,
            stateInfo[state].sellTxFeeDenominator,
            stateInfo[state].buyBonusDenominator,
            stateInfo[state].sellFeeDenominator
        );
    }

    /// @notice Add liquidity to DRF-ETH pair using DRF amount
    function _addLiquidityDRFETH(uint256 drfAmount) private returns (uint256 drfDust, uint256 ethDust) {
        uint256 drfToSwapForETH = drfAmount.div(2);
        uint256 drfToAddLiquidity = drfAmount.sub(drfToSwapForETH);
        uint256 ethBalanceBeforeSwap = address(this).balance;

        // Swap path
        address[] memory path = new address[](2);
        path[0] = drf;
        path[1] = weth;

        // Swap DRF for ETH
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            drfToSwapForETH,
            0,
            path,
            address(this),
            MAX
        );

        uint256 ethToAddLiquidity = address(this).balance.sub(ethBalanceBeforeSwap);

        // Add liquidity
        (uint256 drfUsed, uint256 ethUsed,) = uniswapRouter.addLiquidityETH{value : ethToAddLiquidity}(
            drf,
            drfToAddLiquidity,
            0,
            0,
            address(this),
            MAX
        );

        drfDust = drfAmount.sub(drfToSwapForETH);
        drfDust = drfDust > drfUsed ? drfDust.sub(drfUsed) : 0;
        ethDust = ethToAddLiquidity > ethUsed ? ethToAddLiquidity.sub(ethUsed) : 0;
    }

    /// @notice Add liquidity using token A amount
    function _addLiquidityToken(address tokenA, address tokenB, uint256 tokenAAmount) private returns (uint256 tokenADust, uint256 tokenBDust, uint256 pairTokenAmount) {
        uint256 tokenAToSwap = tokenAAmount.div(2);
        uint256 tokenAToAddLiquidity = tokenAAmount.sub(tokenAToSwap);
        uint256 tokenBBalanceBeforeSwap = IERC20(tokenB).balanceOf(address(this));

        // Swap path
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        // Swap DRF for token
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAToSwap,
            0,
            path,
            address(this),
            MAX
        );

        uint256 tokenBToAddLiquidity = IERC20(tokenB).balanceOf(address(this)).sub(tokenBBalanceBeforeSwap);

        // Add liquidity
        (uint256 tokenAUsed, uint256 tokenBUsed, uint256 liquidity) = uniswapRouter.addLiquidity(
            tokenA,
            tokenB,
            tokenAToAddLiquidity,
            tokenBToAddLiquidity,
            0,
            0,
            address(this),
            MAX
        );

        tokenADust = tokenAAmount.sub(tokenAToSwap);
        tokenADust = tokenADust > tokenAUsed ? tokenADust.sub(tokenAUsed) : 0;
        tokenBDust = tokenBToAddLiquidity > tokenBUsed ? tokenBToAddLiquidity.sub(tokenBUsed) : 0;
        pairTokenAmount = liquidity;
    }

    /// @notice Buy back and burn DRF
    function _buyBack() private {
        // Swap path
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = drf;

        // Use ETH to market buy
        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value : address(this).balance.div(stateInfo[state].buyBackDenominator)}
        (0, path, address(this), MAX);

        // Add as burned supply
        burnSupply = burnSupply.add(amounts[1]);
    }

    /* ========== View ========== */

    /// @notice Get staked token total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get staked token balance
    function balanceOf(address account) public view returns (uint256) {
        return accountInfos[account].balance;
    }

    /// @notice Get account max withdraw
    function maxWithdrawOf(address account) public view returns (uint256) {
        // Get how many day already passes
        uint256 dayCount = block.timestamp.sub(accountInfos[account].withdrawTime).add(1).div(1 days);
        // If already 10 days passes
        if (dayCount >= 10) {
            return Math.min(accountInfos[account].peakBalance, balanceOf(account));
        } else {
            return Math.min(accountInfos[account].peakBalance.div(10).mul(dayCount), balanceOf(account));
        }
    }

    /// @notice Get reward tax percentage
    function rewardTaxPercentage() public view returns (uint256) {
        return state == State.Brake ? 80 : 10;
    }

    /// @notice Get claim reward tax
    function taxForReward(uint256 reward) public view returns (uint256 tax) {
        tax = reward.div(100).mul(rewardTaxPercentage());
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

}
