//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./InvestorsVesting.sol";
import "./LiquidityProvider.sol";
import "./CliffVesting.sol";
import "./IPublicSale.sol";
import "./IOneUp.sol";


contract PublicSale is IPublicSale, Ownable {
    using SafeMath for uint256;

    bool public privateSaleFinished;
    bool public liquidityPoolCreated;

    IOneUp public oneUpToken;
    IVesting public immutable vesting;
    ILiquidityProvider public immutable lpProvider;

    address public reserveLockContract;
    address public marketingLockContract;
    address public developerLockContract;
    address payable public immutable publicSaleFund;

    uint256 public totalDeposits;
    uint256 public publicSaleStartTimestamp;
    uint256 public publicSaleFinishedAt;

    uint256 public constant PUBLIC_SALE_DELAY = 7 days;
    uint256 public constant LP_CREATION_DELAY = 10 minutes;
    uint256 public constant TRADING_BLOCK_DELAY = 5 minutes;
    uint256 public constant WHITELISTED_USERS_ACCESS = 10 minutes;

    uint256 public constant PUBLIC_SALE_LOCK_PERCENT = 5000;  // 50% of tokens
    uint256 public constant PRIVATE_SALE_LOCK_PERCENT = 1500; // 15% of tokens
    uint256 public constant PUBLIC_SALE_PRICE = 151000;       // 1 ETH = 151,000 token

    uint256 public constant HARD_CAP_ETH_AMOUNT = 0.03 ether;
    uint256 public constant MIN_DEPOSIT_ETH_AMOUNT = 0.0003 ether;
    uint256 public constant MAX_DEPOSIT_ETH_AMOUNT = 0.03 ether;

    mapping(address => uint256) internal _deposits;
    mapping(address => uint256) internal _whitelistedAmount;

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event EmergencyWithdrawn(address user, uint256 amount);
    event UsersWhitelisted(address[] users, uint256 maxAmount);

    // ------------------------
    // CONSTRUCTOR
    // ------------------------

    constructor(address oneUpToken_, address payable publicSaleFund_, address uniswapRouter_) {
        require(oneUpToken_ != address(0), 'PublicSale: Empty token address!');
        require(publicSaleFund_ != address(0), 'PublicSale: Empty fund address!');
        require(uniswapRouter_ != address(0), 'PublicSale: Empty uniswap router address!');

        oneUpToken = IOneUp(oneUpToken_);
        publicSaleFund = publicSaleFund_;

        address vestingAddr = address(new InvestorsVesting(oneUpToken_));
        vesting = IVesting(vestingAddr);

        address lpProviderAddr = address(new LiquidityProvider(oneUpToken_, uniswapRouter_));
        lpProvider = ILiquidityProvider(lpProviderAddr);
    }

    // ------------------------
    // PAYABLE RECEIVE
    // ------------------------

    /// @notice Public receive method which accepts ETH
    /// @dev It can be called ONLY when private sale finished, and public sale is active
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(privateSaleFinished, 'PublicSale: Private sale not finished yet!');
        require(publicSaleFinishedAt == 0, 'PublicSale: Public sale already ended!');
        require(block.timestamp >= publicSaleStartTimestamp && block.timestamp <= publicSaleStartTimestamp.add(PUBLIC_SALE_DELAY), 'PublicSale: Time was reached!');
        require(totalDeposits.add(msg.value) <= HARD_CAP_ETH_AMOUNT, 'PublicSale: Deposit limits reached!');
        require(_deposits[msg.sender].add(msg.value) >= MIN_DEPOSIT_ETH_AMOUNT && _deposits[msg.sender].add(msg.value) <= MAX_DEPOSIT_ETH_AMOUNT, 'PublicSale: Limit is reached or not enough amount!');

        // Check the whitelisted status during the the first 2 hours
        if (block.timestamp < publicSaleStartTimestamp.add(WHITELISTED_USERS_ACCESS)) {
            require(_whitelistedAmount[msg.sender] > 0, 'PublicSale: Its time for whitelisted investors only!');
            require(_whitelistedAmount[msg.sender] >= msg.value, 'PublicSale: Sent amount should not be bigger from allowed limit!');
            _whitelistedAmount[msg.sender] = _whitelistedAmount[msg.sender].sub(msg.value);
        }

        _deposits[msg.sender] = _deposits[msg.sender].add(msg.value);
        totalDeposits = totalDeposits.add(msg.value);

        uint256 tokenAmount = msg.value.mul(PUBLIC_SALE_PRICE);
        vesting.submit(msg.sender, tokenAmount, PUBLIC_SALE_LOCK_PERCENT);

        emit Deposited(msg.sender, msg.value);
    }

    // ------------------------
    // SETTERS (PUBLIC)
    // ------------------------

    /// @notice Finish public sale
    /// @dev It can be called by anyone, if deadline or hard cap was reached
    function endPublicSale() external override {
        require(publicSaleFinishedAt == 0, 'endPublicSale: Public sale already finished!');
        require(privateSaleFinished, 'endPublicSale: Private sale not finished yet!');
        require(block.timestamp > publicSaleStartTimestamp.add(PUBLIC_SALE_DELAY) || totalDeposits.add(0.01 ether) >= HARD_CAP_ETH_AMOUNT, 'endPublicSale: Can not be finished!');
        publicSaleFinishedAt = block.timestamp;
    }

    /// @notice Distribute collected ETH between company/liquidity provider and create liquidity pool
    /// @dev It can be called by anyone, after LP_CREATION_DELAY from public sale finish
    function addLiquidity() external override  {
        require(!liquidityPoolCreated, 'addLiquidity: Pool already created!');
        require(publicSaleFinishedAt != 0, 'addLiquidity: Public sale not finished!');
        require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY), 'addLiquidity: Time was not reached!');

        liquidityPoolCreated = true;

        // Calculate distribution and liquidity amounts
        uint256 balance = address(this).balance;
        // Prepare 60% of all ETH for LP creation
        uint256 liquidityEth = balance.mul(6000).div(10000);

        // Transfer ETH to pre-sale address and liquidity provider
        publicSaleFund.transfer(balance.sub(liquidityEth));
        payable(address(lpProvider)).transfer(liquidityEth);

        // Create liquidity pool
        lpProvider.addLiquidity();

        // Start vesting for investors
        vesting.setStart();

        // Tokens will be tradable in TRADING_BLOCK_DELAY
        oneUpToken.setTradingStart(block.timestamp.add(TRADING_BLOCK_DELAY));
    }

    /// @notice Investor withdraw invested funds
    /// @dev Method will be available after 1 day if liquidity was not added
    function emergencyWithdrawFunds() external override {
      require(!liquidityPoolCreated, 'emergencyWithdrawFunds: Liquidity pool already created!');
      require(publicSaleFinishedAt != 0, 'emergencyWithdrawFunds: Public sale not finished!');
      require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY).add(1 days), 'emergencyWithdrawFunds: Not allowed to call now!');

      uint256 investedAmount = _deposits[msg.sender];
      require(investedAmount > 0, 'emergencyWithdrawFunds: No funds to receive!');

      // Reset user vesting information
      vesting.reset(msg.sender);

      // Transfer funds back to the user
      _deposits[msg.sender] = 0;
      payable(msg.sender).transfer(investedAmount);

      emit EmergencyWithdrawn(msg.sender, investedAmount);
    }

    // ------------------------
    // SETTERS (OWNABLE)
    // ------------------------

    /// @notice Admin can manually add private sale investors with this method
    /// @dev It can be called ONLY during private sale, also lengths of addresses and investments should be equal
    /// @param investors Array of investors addresses
    /// @param amounts Tokens Amount which investors needs to receive (INVESTED ETH * 200.000)
    function addPrivateAllocations(address[] memory investors, uint256[] memory amounts) external override onlyOwner {
        require(!privateSaleFinished, 'addPrivateAllocations: Private sale is ended!');
        require(investors.length > 0, 'addPrivateAllocations: Array can not be empty!');
        require(investors.length == amounts.length, 'addPrivateAllocations: Arrays should have the same length!');

        vesting.submitMulti(investors, amounts, PRIVATE_SALE_LOCK_PERCENT);
    }

    /// @notice Finish private sale and start public sale
    /// @dev It can be called once and ONLY during private sale, by admin
    function endPrivateSale() external override onlyOwner {
        require(!privateSaleFinished, 'endPrivateSale: Private sale is ended!');

        privateSaleFinished = true;
        publicSaleStartTimestamp = block.timestamp;
    }

    /// @notice Recover contract based tokens
    /// @dev Should be called by admin only to recover lost tokens
    function recoverERC20(address tokenAddress) external override onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
        emit Recovered(tokenAddress, balance);
    }

    /// @notice Recover locked LP tokens when time reached
    /// @dev Should be called by admin only, and tokens will be transferred to the owner address
    function recoverLpToken(address lPTokenAddress) external override onlyOwner {
        lpProvider.recoverERC20(lPTokenAddress, msg.sender);
    }

    /// @notice Mint and lock tokens for team, marketing, reserve
    /// @dev Only admin can call it once, after liquidity pool creation
    function lockCompanyTokens(address developerReceiver, address marketingReceiver, address reserveReceiver) external override {
        require(marketingReceiver != address(0) && reserveReceiver != address(0) && developerReceiver != address(0), 'lockCompanyTokens: Can not be zero address!');
        require(marketingLockContract == address(0) && reserveLockContract == address(0) && developerLockContract == address(0), 'lockCompanyTokens: Already locked!');
        require(block.timestamp > publicSaleFinishedAt.add(LP_CREATION_DELAY), 'lockCompanyTokens: Should be called after LP creation!');
        require(liquidityPoolCreated, 'lockCompanyTokens: Pool was not created!');

        developerLockContract = address(new CliffVesting(developerReceiver, 30 days, 180 days, address(oneUpToken)));    //  1 month cliff  6 months vesting
        marketingLockContract = address(new CliffVesting(marketingReceiver, 7 days, 90 days, address(oneUpToken)));      //  7 days cliff   3 months vesting
        reserveLockContract = address(new CliffVesting(reserveReceiver, 270 days, 360 days, address(oneUpToken)));        //  9 months cliff 3 months vesting

        oneUpToken.mint(developerLockContract, 2000000 ether);  // 2 mln tokens
        oneUpToken.mint(marketingLockContract, 2000000 ether);  // 2 mln tokens
        oneUpToken.mint(reserveLockContract, 500000 ether);    // 500k tokens
    }

    /// @notice Whitelist public sale privileged users
    /// @dev This users allowed to invest during the first 2 hours
    /// @param users list of addresses
    /// @param maxEthDeposit max amount of ETH which users allowed to invest during this period
    function whitelistUsers(address[] calldata users, uint256 maxEthDeposit) external override onlyOwner {
        require(users.length > 0, 'setWhitelistUsers: Empty array!');

        uint256 usersLength = users.length;
        for (uint256 i = 0; i < usersLength; i++) {
            address user = users[i];
            _whitelistedAmount[user] = _whitelistedAmount[user].add(maxEthDeposit);
        }

        emit UsersWhitelisted(users, maxEthDeposit);
    }


    // ------------------------
    // GETTERS
    // ------------------------

    /// @notice Returns how much provided user can invest during the first 2 hours (if whitelisted)
    /// @param user address
    function getWhitelistedAmount(address user) external override view returns (uint256) {
        return _whitelistedAmount[user];
    }

    /// @notice Returns how much user invested during the whole public sale
    /// @param user address
    function getUserDeposits(address user) external override view returns (uint256) {
        return _deposits[user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }
 }