// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./draft-IERC20Permit.sol";
import "./AggregatorV3Interface.sol";
import "./BUSDC.sol";
import "./IVault.sol";
import "./BUMPToken.sol";
import "./BumperAccessControl.sol";
import "./BUSDCV2.sol";

///@title Bumper Protocol Liquidity Provision Program (LPP) - Main Contract
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021
contract BumpMarketV2 is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    BumperAccessControl
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///@dev Interest rate not used
    struct Deposit {
        uint256 interest;
        uint256 balance;
        uint256 timestamp;
    }

    struct StableCoinDetail {
        address contractAddress;
        AggregatorV3Interface priceFeed;
    }

    struct TimePeriod {
        uint256 start;
        uint256 end;
    }

    enum StableCoins {USDC}

    ///@dev This maps an address to cumulative details of deposit made by an LP
    mapping(address => Deposit) public depositDetails;

    ///@dev This maps an address to number of USDC used to purchase BUMP tokens
    mapping(address => uint256) public usdcForBumpPurchase;

    ///@dev This map contains StableCoins enum in bytes form to the respective address
    mapping(bytes32 => StableCoinDetail) internal stableCoinsDetail;

    uint256 public currentTVL;

    ///@dev Represents the maximum percentage of their total deposit that an LP can use to buy BUMP
    ///@dev Decimal precision will be up to 2 decimals
    uint256 public maxBumpPercent;

    ///@dev Stores number of BUMP tokens available to be distributed as rewards during the LPP
    uint256 public bumpRewardAllocation;

    ///@dev Stores maximum number of BUMP tokens that can be purchased during the LPP
    uint256 public bumpPurchaseAllocation;

    ///@dev Address of USDC yearn vault where deposits will be sent to
    address public usdcVault;

    ///@dev 1a BUMP token address
    ///@notice To be replaced in future
    address public bumpTokenAddress;

    ///@dev 1a bUSDC token address
    ///@notice To be replaced in future
    address public busdcTokenAddress;

    ///@dev These will be constants used in TVL and BUMP price formulas
    ///@notice These constants have been carefully selected to calibrate BUMP price and reward rates
    uint256 public constant BUMP_INITAL_PRICE = 6000;
    uint256 public constant SWAP_RATE_CONSTANT = 8;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG = 68;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG_DIVIDER = 11000;
    uint256 public constant BUMP_REWARDS_FORMULA_CONSTANT = 6 * (10**7);

    ///@dev ---------------------- Below are the state variables added in version 2 ------------------------------

    ///@dev This is the percentage of withdrawal amount that is deducted as fees during withdrawal.
    uint256 public fee;

    ///@dev This is the percentage of withdrawal amount that is deducted as levy during withdrawal.
    uint256 public levy;

    ///@dev This is used for bump token price calculations.
    ///@dev swapRateParameter1 has decimal precision of 18.
    uint256 public swapRateParameter1;

    ///@dev This is used for bump token price calculations.
    ///@dev swapRateParameter2 has decimal precision of 4.
    uint256 public swapRateParameter2;

    ///@dev This stores total number of deposits made into the protocol.
    uint256 public totalDeposits;

    ///@dev This stores allowed period for swap BUSDC to BUMP
    TimePeriod public swapAllowedPeriod;

    ///@dev This is the percentage of reward has decimal precision of 2.
    uint256 public rewardPercent;

    ///@dev ------------------------ Here version 2 state variables ends -----------------------------------------

    ///@dev Emitted after an LP deposit is made
    event DepositMade(
        address indexed depositor,
        uint256 amount,
        uint256 interestRate
    );

    ///@dev Emitted when rewards are issued to the LP at the time of deposit
    event RewardIssued(address indexed rewardee, uint256 amount, uint256 price);

    ///@dev Emitted when BUMP is swapped for USDC during LPP
    event BumpPurchased(
        address indexed depositor,
        uint256 amount,
        uint256 price
    );

    ///@dev These events will be emitted when yearn related methods will be called by governance.
    event ApprovedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event DepositedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event AmountWithdrawnFromYearn(
        string description,
        address sender,
        uint256 burnedYearnTokens,
        uint256 amountWithdrawn
    );

    ///@dev These events will be emitted when respective governance parameters will change.
    event UpdatedMaxBumpPercent(
        string description,
        address sender,
        uint256 newMaxBumpPercent
    );
    event UpdatedBumpRewardAllocation(
        string description,
        address sender,
        uint256 newBumpRewardAllocation
    );
    event UpdatedBumpPurchaseAllocation(
        string description,
        address sender,
        uint256 newBumpPurchaseAllocation
    );

    ///@dev --------------------------- Below are the events added in version 2 --------------------------------
    event WithdrawUsdc(
        uint256 tokensBurnt,
        uint256 usdcWithdrawn,
        address indexed receiver
    );

    event UpdatedFee(
        string description,
        address indexed sender,
        uint256 newFee
    );

    event UpdatedLevy(
        string description,
        address indexed sender,
        uint256 newLevy
    );

    event UpdateSwapRateParameter1(
        string description,
        address indexed sender,
        uint256 newSwapRateParameter1
    );

    event UpdateSwapRateParameter2(
        string description,
        address indexed sender,
        uint256 newSwapRateParameter2
    );

    event UpdateTotalDeposits(
        string description,
        address indexed sender,
        uint256 newTotalDeposits
    );

    event UpdatedSwapAllowedPeriod(
        address indexed sender,
        uint256 start,
        uint256 end
    );

    event SwappedBUSDCToBUMP(address sender, uint256 amount);

    event PermittedForTransfer(
        address indexed owner,
        address indexed spender,
        uint256 value,
        uint256 deadline
    );

    event TransferUsdc(address indexed receiver, uint256 amount);

    event DepositType(
        address indexed sender,
        uint256 amount,
        uint256 depositType
    );

    event UpdatedRewardPercent(address indexed sender, uint256 percent);

    modifier lockWithdrawal {
        require(
            block.timestamp >= BUSDCV2(busdcTokenAddress).unlockTimestamp(),
            "Withdrawal functionality can't be accessed before it's unlocked"
        );
        _;
    }

    modifier onlyTimestampPeriod(TimePeriod storage period) {
        uint256 curentTime = block.timestamp;
        require(
            curentTime >= period.start && curentTime <= period.end,
            "Forbidden time"
        );
        _;
    }

    ///@dev ------------------------------- Here version 2 events and modifier ends ------------------------------------
    ///@dev initialize function is removed from V2 , as there is no need to define it here again. It is called only once when deployng contracts for first time.

    ///@notice Swap BUSDC to BUMP.
    ///@param _amount Amount of BUSDC you want to swap to BUMP.
    function swap(uint256 _amount)
        external
        virtual
        whenNotPaused
        onlyTimestampPeriod(swapAllowedPeriod)
        returns (bool)
    {
        uint256 currBalance = depositDetails[msg.sender].balance;
        uint256 bumpTokensAsRewards;
        uint256 bumpTokensPurchased;
        require(_amount <= currBalance, "Not enough balance to swap");
        depositDetails[msg.sender].balance -= _amount;
        usdcForBumpPurchase[msg.sender] += _amount;

        BUSDCV2(busdcTokenAddress).burn(msg.sender, _amount);

        (bumpTokensAsRewards, bumpTokensPurchased) = getBumpAllocation(
            0,
            _amount
        );

        BUMPToken(bumpTokenAddress).distributeToAddress(
            msg.sender,
            bumpTokensAsRewards + bumpTokensPurchased
        );
        emit RewardIssued(
            msg.sender,
            bumpTokensAsRewards,
            getSwapRateBumpUsdc()
        );
        emit BumpPurchased(
            msg.sender,
            bumpTokensPurchased,
            getSwapRateBumpUsdc()
        );

        emit SwappedBUSDCToBUMP(msg.sender, bumpTokensPurchased);
        return true;
    }

    ///@notice This method pauses bUSDC token and can only be called by governance.
    function pauseProtocol() external virtual onlyGovernance {
        BUSDC(busdcTokenAddress).pause();
        _pause();
    }

    ///@notice This method un-pauses bUSDC token and can only be called by governance.
    function unpauseProtocol() external virtual onlyGovernance {
        BUSDC(busdcTokenAddress).unpause();
        _unpause();
    }

    ///@notice This returns a number of yUSDC tokens issued on the name of BumpMarket contract.
    ///@return amount returns the amount of yUSDC issued to BumpMarket by yearn vault.
    function getyUSDCIssuedToReserve()
        external
        view
        virtual
        returns (uint256 amount)
    {
        amount = IERC20Upgradeable(usdcVault).balanceOf(address(this));
    }

    ///@notice Transfers approved amount of asset ERC20 Tokens from user wallet to Reserve contract and further to yearn for yield farming. Mints bUSDC for netDeposit made to reserve and mints rewarded and purchased BUMP tokens
    ///@param _amount Amount of ERC20 tokens that need to be transfered.
    ///@param _amountForBumpPurchase Amount of deposit that user allocates for bump purchase.
    ///@param _coin Type of token.
    ///@param _depositType Type of deposit
    ///@dev This function was modified in version 2.
    function depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType
    ) external virtual nonReentrant whenNotPaused {
        _depositAmount(_amount, _amountForBumpPurchase, _coin, _depositType);
    }

    ///@notice Transfers approved amount of asset ERC20 Tokens from user wallet to Reserve contract and further to yearn for yield farming. Mints bUSDC for netDeposit made to reserve and mints rewarded and purchased BUMP tokens
    ///@param _amount Amount of ERC20 tokens that need to be transfered.
    ///@param _amountForBumpPurchase Amount of deposit that user allocates for bump purchase.
    ///@param _coin Type of token.
    ///@param deadline Permit deadline.
    ///@param _depositType Type of deposit
    ///@param v Permit v.
    ///@param r Permit r.
    ///@param s Permit s.
    function depositAmountWithPermit(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual nonReentrant whenNotPaused {
        IERC20Permit(
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))]
                .contractAddress
        )
            .permit(msg.sender, address(this), _amount, deadline, v, r, s);

        _depositAmount(_amount, _amountForBumpPurchase, _coin, _depositType);

        emit PermittedForTransfer(msg.sender, address(this), _amount, deadline);
    }

    function _depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin,
        uint256 _depositType
    ) private {
        uint256 bumpPurchasePercent =
            (_amountForBumpPurchase * 10000) / _amount;
        uint256 amountToDeposit = _amount - _amountForBumpPurchase;
        uint256 bumpTokensAsRewards;
        uint256 bumpTokensPurchased;
        require(
            bumpPurchasePercent <= maxBumpPercent,
            "Exceeded maximum deposit percentage that can be allocated for BUMP pruchase"
        );

        if (depositDetails[msg.sender].timestamp == 0) {
            depositDetails[msg.sender] = Deposit(
                0,
                amountToDeposit,
                block.timestamp
            );
        } else {
            depositDetails[msg.sender].balance =
                depositDetails[msg.sender].balance +
                amountToDeposit;
        }
        usdcForBumpPurchase[msg.sender] =
            usdcForBumpPurchase[msg.sender] +
            _amountForBumpPurchase;
        currentTVL = currentTVL + _amount;
        totalDeposits = totalDeposits + _amount;
        (bumpTokensAsRewards, bumpTokensPurchased) = getBumpAllocation(
            amountToDeposit,
            _amountForBumpPurchase
        );
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))]
                .contractAddress
        )
            .safeTransferFrom(msg.sender, address(this), _amount);
        ///Mint busdc tokens in user's name
        BUSDC(busdcTokenAddress).mint(msg.sender, amountToDeposit);
        ///Mint BUMP tokens in user's name
        BUMPToken(bumpTokenAddress).distributeToAddress(
            msg.sender,
            bumpTokensAsRewards + bumpTokensPurchased
        );
        _approveUSDCToYearnVault(_amount);
        _depositUSDCInYearnVault(_amount);
        emit DepositMade(msg.sender, amountToDeposit, 0);
        emit RewardIssued(
            msg.sender,
            bumpTokensAsRewards,
            getSwapRateBumpUsdc()
        );
        emit BumpPurchased(
            msg.sender,
            bumpTokensPurchased,
            getSwapRateBumpUsdc()
        );
        emit DepositType(msg.sender, _amount, _depositType);
    }

    ///@notice This acts like an external onlyGovernance interface for internal method _approveUSDCToYearnVault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function approveUSDCToYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        whenNotPaused
    {
        _approveUSDCToYearnVault(_amount);
        emit ApprovedAmountToYearnVault(
            "BUMPER ApprovedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    //////@notice This acts like an external onlyGovernance interface for internal method _depositUSDCInYearnVault.
    ///@param _amount Amount of USDC you want to deposit to the yearn vault.
    function depositUSDCInYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        nonReentrant
        whenNotPaused
    {
        _depositUSDCInYearnVault(_amount);
        emit DepositedAmountToYearnVault(
            "BUMPER DepositedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    ///@notice Withdraws USDC from yearn vault and burns yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to burn
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        returns (uint256)
    {
        uint256 tokensRedeemed = IVault(usdcVault).withdraw(_amount);
        emit AmountWithdrawnFromYearn(
            "BUMPER AmountWithdrawnFromYearnVault",
            msg.sender,
            _amount,
            tokensRedeemed
        );
        return tokensRedeemed;
    }

    ///@notice This function in introduced in V2
    ///@notice Withdraws USDC from yearn vault, sends to address and burns yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to withdraw
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVaultToAddress(uint256 _amount)
        external
        virtual
        onlyGovernance
        nonReentrant
        returns (uint256)
    {
        uint256 tokensWithdrawn = IVault(usdcVault).withdraw(_amount);

        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeTransfer(msg.sender, tokensWithdrawn);

        emit AmountWithdrawnFromYearn(
            "BUMPER withdrawUSDCFromYearnVaultToAddress",
            msg.sender,
            _amount,
            tokensWithdrawn
        );
        emit TransferUsdc(msg.sender, tokensWithdrawn);
        return tokensWithdrawn;
    }

    ///@notice This function is used to update maxBumpPercent state variable by governance.
    ///@param _maxBumpPercent New value of maxBumpPercent state variable.
    ///@dev Decimal precision is 2
    function updateMaxBumpPercent(uint256 _maxBumpPercent)
        external
        virtual
        onlyGovernance
    {
        maxBumpPercent = _maxBumpPercent;
        emit UpdatedMaxBumpPercent(
            "BUMPER UpdatedMaxBUMPPercent",
            msg.sender,
            _maxBumpPercent
        );
    }

    ///@notice This function is used to update bumpRewardAllocation state variable by governance.
    ///@param _bumpRewardAllocation New value of bumpRewardAllocation state variable.
    ///@dev Decimal precision should be 18
    function updateBumpRewardAllocation(uint256 _bumpRewardAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpRewardAllocation = _bumpRewardAllocation;
        emit UpdatedBumpRewardAllocation(
            "BUMPER UpdatedBUMPRewardAllocation",
            msg.sender,
            _bumpRewardAllocation
        );
    }

    ///@notice This function is used to update bumpPurchaseAllocation state variable by governance.
    ///@param _bumpPurchaseAllocation New value of bumpPurchaseAllocation state variable
    ///@dev Decimal precision should be 18
    function updateBumpPurchaseAllocation(uint256 _bumpPurchaseAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpPurchaseAllocation = _bumpPurchaseAllocation;
        emit UpdatedBumpPurchaseAllocation(
            "BUMPER UpdatedBumpPurchaseAllocation",
            msg.sender,
            _bumpPurchaseAllocation
        );
    }

    ///@notice This function is used to update swap period.
    ///@param _start Beginning of the period
    ///@param _end End of period
    function updateSwapAllowedPeriod(uint256 _start, uint256 _end)
        external
        virtual
        onlyGovernance
    {
        require(
            _end >= _start,
            "The end of the period must be larger than the start"
        );
        swapAllowedPeriod = TimePeriod(_start, _end);
        emit UpdatedSwapAllowedPeriod(msg.sender, _start, _end);
    }

    ///@notice This function is used to update rewardPercent.
    ///@param percent Percent
    function updateRrewardPercent(uint256 percent)
        external
        virtual
        onlyGovernance
    {
        rewardPercent = percent;
        emit UpdatedRewardPercent(msg.sender, percent);
    }

    ///@notice This function returns a predicted swap rate for BUMP/USDC after a given deposit is made.
    ///@param _deposit It is the deposit amount for which it calculates swap rate.
    ///@return Returns swap rate for BUMP/USDC.
    ///@dev This function was modified in version 2.
    function estimateSwapRateBumpUsdc(uint256 _deposit)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 totalDepositsAfterDeposit = totalDeposits + _deposit;
        return
            ((totalDepositsAfterDeposit * swapRateParameter1) /
                (10**18 * 10**2)) + swapRateParameter2;
    }

    ///@notice This returns current price of stablecoin passed as an param.
    ///@param _coin Coin of which current price user wants to know.
    ///@return Returns price that it got from aggregator address provided.
    ///@dev Decimal precision of 8 decimals
    function getCurrentPrice(StableCoins _coin)
        public
        view
        virtual
        returns (int256)
    {
        AggregatorV3Interface priceFeed =
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))].priceFeed;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    ///@notice This calculates what is the latest swap rate of BUMP/USDC
    ///@return Returns what is the swap rate of BUMP/USDC
    ///@dev This function was modified in version 2.
    /// 8215759267 * 8000000000000000000 / 10 ** 20 + 60000000 =  717260741,36
    /// 8215759267 * 8 / 10**11 + 6000 = 6000,65726074136
    /// 717260741,36 / 6000,65726074136 = 119530,3631241529981991136
    function getSwapRateBumpUsdc() public view virtual returns (uint256) {
        return
            ((totalDeposits * swapRateParameter1) / (10**18 * 10**2)) +
            swapRateParameter2;
    }

    ///@notice Calculates BUMP rewards that is issued to user
    ///@param _totalDeposit total deposit made by user
    ///@param _amountForPurchase Amount of usdc spent to buy BUMP tokens
    ///@return BUMP rewards that need to be transferred
    ///@dev This function was modified in version 2.
    function getBumpRewards(uint256 _totalDeposit, uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 currentTimestamp = block.timestamp;
        if (
            currentTimestamp < swapAllowedPeriod.start ||
            currentTimestamp > swapAllowedPeriod.end
        ) {
            return 0;
        }
        if (
            depositDetails[msg.sender].timestamp == 0 ||
            depositDetails[msg.sender].timestamp >= swapAllowedPeriod.start
        ) {
            return 0;
        }
        uint256 bumpRewards =
            (getBumpPurchaseAmount(_amountForPurchase) * rewardPercent) /
                (100 * 10**2);
        return bumpRewards;
    }

    ///@notice This function returns amount of BUMP tokens you will get for amount of usdc you want to use for purchase.
    ///@param _amountForPurchase Amount of USDC for BUMP purchase.
    ///@return Amount of BUMP tokens user will get.
    function getBumpPurchaseAmount(uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        //The reason we have multiplied numerator by 10**12 because decimal precision of BUMP token is 18
        //Given precision of _amountForPurchase is 6 , we need 12 more
        //And we have again multiplied it by 10**4 because , below swap rate is of precision 4
        uint256 bumpPurchaseAmount =
            (_amountForPurchase * 10**12 * 10**4) / (getSwapRateBumpUsdc());
        return bumpPurchaseAmount;
    }

    ///@notice Calculates amount of BUMP tokens that need to be transferred as rewards and as purchased amount
    ///@param _amountForDeposit Amount of USDC tokens deposited for which BUMP rewards need to be issued
    ///@param _amountForPurchase Amount of USDC tokens sent for the purchase of BUMP tokens
    ///@return Returns amount of BUMP tokens as rewards and amount of BUMP tokens purchased
    function getBumpAllocation(
        uint256 _amountForDeposit,
        uint256 _amountForPurchase
    ) internal virtual returns (uint256, uint256) {
        uint256 bumpRewards =
            getBumpRewards(
                (_amountForDeposit + _amountForPurchase),
                _amountForPurchase
            );
        require(
            bumpRewards <= bumpRewardAllocation,
            "Not enough BUMP Rewards left!"
        );
        bumpRewardAllocation = bumpRewardAllocation - bumpRewards;
        uint256 bumpPurchased = getBumpPurchaseAmount(_amountForPurchase);
        require(
            bumpPurchased <= bumpPurchaseAllocation,
            "Not enough BUMP left to purchase!"
        );
        bumpPurchaseAllocation = bumpPurchaseAllocation - bumpPurchased;
        return (bumpRewards, bumpPurchased);
    }

    ///@notice Approves USDC to yearn vault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function _approveUSDCToYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeApprove(usdcVault, _amount);
    }

    ///@notice Deposits provided amount of USDC to yearn vault.
    ///@param _amount Amount of USDC you want to deposit to yearn vault.
    function _depositUSDCInYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IVault(usdcVault).deposit(_amount);
    }

    ///@dev ----------------------- Below mentioned functions are the newly added functions in version 2. ------------------------

    ///@notice This function is used  by governance to update fee state variable.
    ///@param _fee New value for fee state variable.
    ///@dev It has a decimal precision of 2 decimals.
    function updateFee(uint256 _fee) external virtual onlyGovernance {
        fee = _fee;
        emit UpdatedFee("BUMPER UpdateFee", msg.sender, fee);
    }

    ///@notice This function is used by governance to update levy state variable.
    ///@param _levy New value for levy state variable.
    ///@dev It has a decimal precision of 2 decimals.
    function updateLevy(uint256 _levy) external virtual onlyGovernance {
        levy = _levy;
        emit UpdatedLevy("BUMPER UpdateLevy", msg.sender, levy);
    }

    ///@notice This function is used by governance to update swapRateParameter1 state variable.
    ///@param _swapRateParameter1 New value for swapRateParameter1 state variable.
    ///@dev swapRateParameter1 has a decimal precision of 18.
    function updateSwapRateParameter1(uint256 _swapRateParameter1)
        external
        virtual
        onlyGovernance
    {
        swapRateParameter1 = _swapRateParameter1;
        emit UpdateSwapRateParameter1(
            "BUMPER UpdateSwapRateParameter1",
            msg.sender,
            swapRateParameter1
        );
    }

    ///@notice This function is used by governance to update swapRateParameter2 state variable.
    ///@param _swapRateParameter2 New value for swapRateParameter2 state variable.
    ///@dev swapRateParameter2 have a decimal precision of 4.
    function updateSwapRateParameter2(uint256 _swapRateParameter2)
        external
        virtual
        onlyGovernance
    {
        swapRateParameter2 = _swapRateParameter2;
        emit UpdateSwapRateParameter2(
            "BUMPER UpdateSwapRateParameter2",
            msg.sender,
            swapRateParameter2
        );
    }

    ///@notice This function is used by governance to initalize totalDeposits state variable.
    function totalDepositsInit() external virtual onlyGovernance {
        require(
            totalDeposits == 0,
            "TotalDeposits can only be initialized once"
        );
        totalDeposits = currentTVL;
        emit UpdateTotalDeposits(
            "BUMPER UpdateTotalDeposits",
            msg.sender,
            totalDeposits
        );
    }

    ///@notice Burn bUSDC tokens and calculate number of USDC tokens to transfer to user's account.
    ///@param amount Number of bUSDC tokens user wants to burn.
    ///@return true if everything is successful.
    function withdrawLiquidity(uint256 amount)
        external
        virtual
        lockWithdrawal
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            BUSDCV2(busdcTokenAddress).balanceOf(msg.sender) >= amount,
            "User doesn't have enough bUSDC to burn"
        );
        return _withdrawLiquidity(msg.sender, amount);
    }

    ///@notice Burn bUSDC tokens and calculate number of USDC tokens to transfer to user's account.
    ///@param receiver This is the person whose tokens need to be burned.
    ///@param amount Number of bUSDC tokens user wants to burn.
    ///@return true if everything is successful.
    function withdrawLiquidity(address receiver, uint256 amount)
        public
        virtual
        lockWithdrawal
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(
            msg.sender == busdcTokenAddress,
            "This method is only callable by bUSDC token contract"
        );
        require(
            BUSDCV2(busdcTokenAddress).balanceOf(receiver) >= amount,
            "User doesn't have enough bUSDC to burn"
        );
        return _withdrawLiquidity(receiver, amount);
    }

    function _withdrawLiquidity(address receiver, uint256 amount)
        internal
        returns (bool)
    {
        uint256 feeCalculated;
        uint256 levyCalculated;
        uint256 pricePerShare;
        uint256 yUSDCTokensBurn;
        uint256 tokensWithdrawn;
        uint256 amountAfterDeduduction;
        //calculate fees and levy and deduct it from USDC amount that will be transfered to user.
        feeCalculated = (fee * amount) / 10000;
        levyCalculated = (levy * amount) / 10000;
        amountAfterDeduduction = amount - (feeCalculated + levyCalculated);
        //calculate amount of yUSDC that need to be burn to get USDC.
        pricePerShare = IVault(usdcVault).pricePerShare();
        // Number of bUSDC tokens is equal to the number of USDC tokens deposited.
        // That's the reason for dividing by pricePerShare.
        yUSDCTokensBurn = ((amountAfterDeduduction * 1000000) / pricePerShare);
        // Deduct amount from depositDetails variable.
        depositDetails[receiver].balance =
            depositDetails[receiver].balance -
            amount;
        currentTVL = currentTVL - amountAfterDeduduction;
        //Burn user's bUSDC tokens
        BUSDCV2(busdcTokenAddress).burn(receiver, amount);
        // Burn calculated amount of yUSDC tokens and withdraw USDC.
        tokensWithdrawn = IVault(usdcVault).withdraw(yUSDCTokensBurn);
        // Transfer withdrawn amount to user's account.
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeTransfer(receiver, tokensWithdrawn);
        emit WithdrawUsdc(amount, tokensWithdrawn, receiver);
        return true;
    }
}
