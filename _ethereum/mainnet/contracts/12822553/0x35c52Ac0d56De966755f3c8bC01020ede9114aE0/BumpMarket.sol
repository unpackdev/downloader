// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AggregatorV3Interface.sol";
import "./BUSDC.sol";
import "./IVault.sol";
import "./BUMPToken.sol";
import "./BumperAccessControl.sol";

///@title Bumper Protocol Liquidity Provision Program (LPP) - Main Contract
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021
contract BumpMarket is
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

    ///@notice This initializes state variables of this contract
    ///@dev This method is called during deployment by open zeppelin and works like a constructor.
    ///@param _usdcAddresses This array stores following addresses at following indexes 0: usdc address 1: usdc aggregator address 2: yUSDC address.
    ///@param _whitelistAddresses Array of white list addresses.
    ///@param _bumpTokenAddress This is the address of the BUMP token.
    ///@param _busdcTokenAddress This is the address of the BUSDC token.
    ///@param _maxBumpPercent This is the maximum percentage of deposit amount that can be used to buy BUMP tokens.
    ///@param _bumpRewardAllocation This stores a maximum number of BUMP tokens that can be distributed as rewards.
    ///@param _bumpPurchaseAllocation This stores a maximum number of BUMP tokens that can be purchased by the LPs.
    function initialize(
        address[] memory _usdcAddresses,
        address[] memory _whitelistAddresses,
        address _bumpTokenAddress,
        address _busdcTokenAddress,
        uint256 _maxBumpPercent,
        uint256 _bumpRewardAllocation,
        uint256 _bumpPurchaseAllocation
    ) public initializer {
        require(
            _bumpTokenAddress != address(0),
            "Bump Token Address cannot be 0"
        );
        require(
            _busdcTokenAddress != address(0),
            "BUSDC Token Address cannot be 0"
        );
        __Pausable_init();
        __ReentrancyGuard_init();
        _BumperAccessControl_init(_whitelistAddresses);
        stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
            .contractAddress = _usdcAddresses[0];
        stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
            .priceFeed = AggregatorV3Interface(_usdcAddresses[1]);
        usdcVault = _usdcAddresses[2];
        bumpTokenAddress = _bumpTokenAddress;
        busdcTokenAddress = _busdcTokenAddress;
        maxBumpPercent = _maxBumpPercent;
        bumpRewardAllocation = _bumpRewardAllocation;
        bumpPurchaseAllocation = _bumpPurchaseAllocation;
        _pause();
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
    function depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin
    ) external virtual nonReentrant whenNotPaused {
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

    ///@notice Withdraws USDC from yearn vault and burn yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to burn
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        whenNotPaused
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

    ///@notice This method estimates how much BUMP you will get as rewards if a certain amount of deposit is made.
    ///@param _totalDeposit Total amount of USDC you are depositing
    ///@param _amountForPurchase Amount of USDC for BUMP token purchase
    ///@return Amount of BUMP rewards you will get if a certain deposit amount is made.
    function estimateBumpRewards(
        uint256 _totalDeposit,
        uint256 _amountForPurchase
    ) external view returns (uint256) {
        uint256 bumpPrice = estimateSwapRateBumpUsdc(_totalDeposit);
        uint256 netDepositAfterPurchase = _totalDeposit - _amountForPurchase;
        uint256 bumpRewards =
            ((netDepositAfterPurchase * bumpRewardAllocation) /
                (bumpPrice * BUMP_REWARDS_FORMULA_CONSTANT * (10**2))) +
                ((_totalDeposit * BUMP_REWARDS_BONUS_DRAG * (10**12)) /
                    BUMP_REWARDS_BONUS_DRAG_DIVIDER);
        return bumpRewards;
    }

    ///@notice This function returns a predicted swap rate for BUMP/USDC after a given deposit is made.
    ///@param _deposit It is the deposit amount for which it calculates swap rate.
    ///@return Returns swap rate for BUMP/USDC.
    function estimateSwapRateBumpUsdc(uint256 _deposit)
        public
        view
        returns (uint256)
    {
        uint256 currentTVLAfterDeposit = currentTVL + _deposit;
        return
            ((currentTVLAfterDeposit * SWAP_RATE_CONSTANT) / (10**9 * 10**2)) +
            BUMP_INITAL_PRICE;
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
    function getSwapRateBumpUsdc() public view returns (uint256) {
        return
            ((currentTVL * SWAP_RATE_CONSTANT) / (10**9 * 10**2)) +
            BUMP_INITAL_PRICE;
    }

    ///@notice Calculates BUMP rewards that is issued to user
    ///@param _totalDeposit total deposit made by user
    ///@param _amountForPurchase Amount of usdc spent to buy BUMP tokens
    ///@return BUMP rewards that need to be transferred
    function getBumpRewards(uint256 _totalDeposit, uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 bumpPrice = getSwapRateBumpUsdc();
        uint256 netDepositAfterPurchase = _totalDeposit - _amountForPurchase;
        uint256 bumpRewards =
            ((netDepositAfterPurchase * bumpRewardAllocation) /
                (bumpPrice * BUMP_REWARDS_FORMULA_CONSTANT * (10**2))) +
                ((_totalDeposit * BUMP_REWARDS_BONUS_DRAG * (10**12)) /
                    BUMP_REWARDS_BONUS_DRAG_DIVIDER);
        return bumpRewards;
    }

    ///@notice This function returns amount of BUMP tokens you will get for amount of usdc you want to use for purchase.
    ///@param _amountForPurchase Amount of USDC for BUMP purchase.
    ///@return Amount of BUMP tokens user will get.
    function getBumpPurchaseAmount(uint256 _amountForPurchase)
        internal
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
}
