//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
    Mainnet instances:
    - Uniswap V2 Router:                         0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    - Sushiswap V1 Router:                       0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
    - Shibaswap V1 Router:                       0x03f7724180AA6b939894B5Ca4314783B0b36b329
    - UNI:                                       0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984  // exists on Sushi
    - USDT:                                      0xdAC17F958D2ee523a2206206994597C13D831ec7
    - DAI:                                       0x6B175474E89094C44Da98b954EedeAC495271d0F // Triangular 1000000000
    - WETH:                                      0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 // Simple 10000000000000
    - Aave LendingPoolAddressesProvider(Mainnet):0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
*/

/**
    Goerli instances:
    - Uniswap V2 Router:                         0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    - Sushiswap V1 Router:                       0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    - Shibaswap V1 Router:                       0x03f7724180AA6b939894B5Ca4314783B0b36b329
    - UNI:                                       0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984  // exists on Sushi
    - USDT:                                      0xaa34a2eE8Be136f0eeD223C9Ec8D4F2d0BC472dd
    - DAI:                                       0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60 // Triangular 1000000000
    - WETH:                                      0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 // Simple 10000000000000
    - Aave LendingPoolAddressesProvider(kovan):  0x5E52dEc931FFb32f609681B8438A51c675cc232d
    
*/

/**
    Kovan instances:
    - Uniswap V2 Router:                         0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    - Sushiswap V1 Router:                       0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    - UNI:                                       0x075A36BA8846C6B6F53644fDd3bf17E5151789DC  // exists on Sushi
    - USDT:                                      0x13512979ADE267AB5100878E2e0f485B568328a4
    - BUSD:                                      0x4c6E1EFC12FDfD568186b7BAEc0A43fFfb4bCcCf 
    - DAI:                                       0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD // Triangular 1000000000
    - WETH:                                      0xd0A1E359811322d97991E03f863a0C30C2cF029C // Simple 10000000000000
    - Aave LendingPoolAddressesProvider(kovan):  0x88757f2f99175387aB4C6a4b3067c77A695b0349
    
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/types/DataTypes.sol
library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol
/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.solpragma experimental ABIEncoderV2;

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function LENDING_POOL() external view returns (ILendingPool);
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/dependencies/openzeppelin/contracts/Address.sol
/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/dependencies/openzeppelin/contracts/SafeMath.sol
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// File: https://github.com/aave/protocol-v2/blob/master/contracts/flashloan/base/FlashLoanReceiverBase.sol

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Arbitrage_flat.sol

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor()public {
        owner = msg.sender;
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract WBNB is ERC20 {
    // string public name = "Wrapped BNB";
    // string public symbol = "WBNB";
    // uint8 public decimals = 18;

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    constructor() public ERC20("Wrapped BNB", "WBNB") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }
}

contract FlashLoanSimpleArbitrage is FlashLoanReceiverBase {
    //--------------------------------------------------------------------
    // VARIABLES

    address public owner;
    address public exchangeA;
    address public exchangeB;
    address public tokenA;
    address public tokenB;

    address public devAddr;

    enum Exchange {
        EXCA,
        EXCB,
        NONE
    }

    //--------------------------------------------------------------------
    // MODIFIERS

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(
        address _addressProvider,             // 0x5E52dEc931FFb32f609681B8438A51c675cc232d
        address _exchangeA,                   // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        address _exchangeB,                   // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        address _tokenA,
        address _tokenB,
        address _devAddr
    )
        public
        FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider))
    {
        owner = msg.sender;
        exchangeA = _exchangeA;
        exchangeB = _exchangeB;
        tokenA = _tokenA;
        tokenB = _tokenB;
        devAddr = _devAddr;
    }

    //--------------------------------------------------------------------
    // ARBITRAGE FUNCTIONS/LOGIC
    
    function withdrawERC(address _tokenAddress, uint256 amount) public onlyOwner {
        uint256 erc20Balance = getTokenBalance(_tokenAddress);
        require(amount <= erc20Balance, "Not enough balance");
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        uint256 ethBalance = getETHBalance();
        require(amount <= ethBalance, "Not enough balance");
        payable(owner).transfer(amount);
    }

    function simpleArbitrage(uint256 _amountIn) public payable {
      
        uint256 amountIn = 0;
        if(tokenA == address(0)) {
            amountIn = msg.value;
        } else {
            amountIn = _amountIn; 
        }  
                
        uint256 amountOut = 0;
        uint256 amountOut_ = 0;
        
        Exchange result = _comparePrice(tokenA, tokenB, amountIn);    // loan amountIn
        if (result == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut = _swap(
                amountIn,
                exchangeA,
                tokenA,
                tokenB
            );

        } else if (result == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut = _swap(
                amountIn,
                exchangeB,
                tokenA,
                tokenB
            );

        } else {
          revert("No Arbitrage Found");
        }

        Exchange result_ = _comparePrice(tokenB, tokenA, amountOut);    // loan amountIn
        if (result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut_ = _swap(
                amountOut, 
                exchangeA, 
                tokenB, 
                tokenA
            );
        } else if (result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeB,
                tokenB,
                tokenA
            ); 
        } else {
          revert("No Arbitrage Found");
        }

        require(amountOut_ > amountIn, "Trade Reverted, Arbitrage not profitable");
            
        if(tokenA == address(0)) {
            payable(devAddr).transfer(amountOut_);
        } else {
            IERC20(tokenA).transfer(devAddr, amountOut_);
        }
    }

    function simpleArbitrageFlashloan(uint256 _amountIn) internal returns(uint256){
    
      
        address _tokenA;
        if(tokenA == address(0)) {
            // amountIn = msg.value;
            address WETH = IUniswapV2Router02(exchangeB).WETH();
            _tokenA = WETH;
        } else {
            _tokenA = tokenA;
            // amountIn = _amountIn; 
        }  

        uint256 amountOut = 0;
        uint256 amountOut_ = 0;
                
        Exchange result = _comparePrice(_tokenA, tokenB, _amountIn);    // loan _amountIn
        if (result == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut = _swap(
                _amountIn,
                exchangeA,
                _tokenA,
                tokenB
            );
        } else if (result == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut = _swap(
                _amountIn,
                exchangeB,
                _tokenA,
                tokenB
            );
        } else {
          revert("No Arbitrage Found");
        }

        Exchange result_ = _comparePrice(tokenB, _tokenA, amountOut);    // loan amountIn
        if (result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeA,
                tokenB,
                _tokenA
            );
        } else if (result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeB,
                tokenB,
                _tokenA
            );
        } else {
          revert("No Arbitrage Found");
        }

        require(amountOut_ > _amountIn, "Trade Reverted, Arbitrage not profitable");
            
        return amountOut_;
    }

    function _swap(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {

        address WETH = IUniswapV2Router02(routerAddress).WETH();
        
        if(sell_token == address(0)) {

            sell_token = WETH;

            // IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactETHForTokens{value : amountIn}(
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];
            
            return amountOut;

        } else if(buy_token == address(0)) {

            buy_token = WETH;

            IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];

            return amountOut;

        } else {
            IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];

            return amountOut;
        }
    }

    function _comparePrice(address _tokenA, address _tokenB, uint256 amount) internal view returns (Exchange) {
        
        address WETH = IUniswapV2Router02(exchangeA).WETH();
        
        if(_tokenA == address(0)) _tokenA = WETH;
        else if(_tokenB == address(0)) _tokenB = WETH;

        uint256 exchangeAPrice = _getAmountOut(
            exchangeA,
            _tokenA,
            _tokenB,
            amount
        );
        uint256 exchangeBPrice = _getAmountOut(
            exchangeB,
            _tokenA,
            _tokenB,
            amount
        );

        // we try to sell ETH with higher price and buy it back with low price to make profit
        if (exchangeAPrice > exchangeBPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    exchangeAPrice,
                    exchangeBPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.EXCA;
        } else if (exchangeAPrice < exchangeBPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    exchangeBPrice,
                    exchangeAPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.EXCB;
        } else {
            return Exchange.NONE;
        }
    }

    function _checkIfArbitrageIsProfitable(
        uint256 amountIn,
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // uniswap & sushiswap have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount

        // difference in ETH
        uint256 difference = ((higherPrice - lowerPrice) * 10**18) /
            higherPrice;

        uint256 payed_fee = (amountIn * 3) / 1000;

        if (difference > payed_fee) {
            return true;
        } else {
            return false;
        }
    }

    function _getAmountOut(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {

        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }

    //--------------------------------------------------------------------
    // FLASHLOAN FUNCTIONS

    /**
     * @dev This function must be called only be the LENDING_POOL and takes care of repaying
     * active debt positions, migrating collateral and incurring new V2 debt token debt.
     *
     * @param assets The array of flash loaned assets used to repay debts.
     * @param amounts The array of flash loaned asset amounts used to repay debts.
     * @param premiums The array of premiums incurred as additional debts.
     * @param initiator The address that initiated the flash loan, unused.
     * @param params The byte array containing, in this case, the arrays of aTokens and aTokenAmounts.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // Try to do arbitrage with the flashloan amount.
        //
        uint256 amountOut = simpleArbitrageFlashloan(amounts[0]);
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.

        uint256 amountOwing = 0;

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        if(tokenA == address(0)) {
            address WETH = IUniswapV2Router02(exchangeA).WETH();
            WBNB(WETH).withdraw(amountOut.sub(amountOwing));
            
            payable(devAddr).transfer(amountOut.sub(amountOwing));
        } else {
            IERC20(tokenA).transfer(devAddr, amountOut.sub(amountOwing));
        }  

        return true;
    }

    function flashloanArbitrage(uint256 _amountIn) public payable {
        address receiverAddress = address(this);
        
        uint256 amountIn = 0;
        
        address _tokenA;
        if(tokenA == address(0)) {
            address WETH = IUniswapV2Router02(exchangeA).WETH();
            _tokenA = WETH;
            amountIn = msg.value; 
          WBNB(WETH).deposit{value: amountIn}();
        } else {
            _tokenA = tokenA;
            amountIn = _amountIn; 
        }

        address[] memory assets = new address[](1);
        assets[0] = address(_tokenA);
        // assets[1] = address(_tokenB);


        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountIn;
        // amounts[0] = getERC20Balance(wethAddress);

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        // modes[1] = INSERT_ASSET_TWO_MODE;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );

    }

    function getTokenBalance(address _erc20Address)
        public
        view
        returns (uint256)
    {
        return IERC20(_erc20Address).balanceOf(address(this));
    }

    function getETHBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function checkProbability(address _tokenA, address _tokenB, uint256 _amountIn) public view returns(string memory){
        Exchange result = _comparePrice(_tokenA, _tokenB, _amountIn);
        if (result == Exchange.EXCA) {
            return "Arbitrage Chances in ExchangeA";
        }else if(result == Exchange.EXCB){
            return "Arbitrage Chances in ExchangeB";
        }else{
            return "No Availabe Arbitrage";
        }
        
    }

    receive() external payable {}

    fallback() external payable { }
}

contract FlashLoanTriangularArbitrage is FlashLoanReceiverBase {
    //--------------------------------------------------------------------
    // VARIABLES

    address public owner;

    address public exchangeA;
    address public exchangeB;
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public devAddr;

    enum Exchange {
        EXCA,
        EXCB,
        NONE
    }

    //--------------------------------------------------------------------
    // MODIFIERS

    modifier onlyOwner() {
        require(devAddr == owner, "only owner can call this");
        _;
    }

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(
        address _addressProvider,            // 0x5E52dEc931FFb32f609681B8438A51c675cc232d
        address _exchangeA,                  // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        address _exchangeB,                  // 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        address _tokenA,
        address _tokenB,
        address _tokenC,
        address _devAddr
    )
        public
        FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider))
    {
        owner = devAddr;
        exchangeA = _exchangeA;
        exchangeB = _exchangeB;
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenC = _tokenC;
        devAddr = _devAddr;
    }

    //--------------------------------------------------------------------
    // ARBITRAGE FUNCTIONS/LOGIC

    function withdrawERC(address _tokenAddress, uint256 amount) public onlyOwner {
        uint256 erc20Balance = getTokenBalance(_tokenAddress);
        require(amount <= erc20Balance, "Not enough balance");
        IERC20(_tokenAddress).transfer(devAddr, amount);
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        uint256 ethBalance = getETHBalance();
        require(amount <= ethBalance, "Not enough balance");
        payable(owner).transfer(amount);
    }

    function triangularArbitrage(uint256 _amountIn) public payable {
        
        // address WETH = IUniswapV2Router02(exchangeB).WETH();

        uint256 amountIn = 0;
        if(tokenA == address(0)) { 
           amountIn = msg.value;
        } else { 
           amountIn = _amountIn; 
        }

        uint256 amountOut = 0;
        uint256 amountOut_ = 0;
        uint256 _amountOut_ = 0;

        Exchange result = _comparePrice(tokenA, tokenB, amountIn);    // loan amountIn
        if (result == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut = _swap(
                amountIn,
                exchangeA,
                tokenA,
                tokenB
            );
        } else if (result == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut = _swap(
                amountIn,
                exchangeB,
                tokenA,
                tokenB
            );
        } else {
          revert("No Arbitrage Found");
        }

        Exchange result_ = _comparePrice(tokenB, tokenC, amountOut);    // loan amountIn
        if (result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeA,
                tokenB,
                tokenC
            );
        } else if (result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeB,
                tokenB,
                tokenC
            );
        } else {
          revert("No Arbitrage Found");
        }

        Exchange _result_ = _comparePrice(tokenC, tokenA, amountOut_);    // loan amountIn
        if (_result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            _amountOut_ = _swap(
                amountOut_,
                exchangeA,
                tokenC,
                tokenA
            );
        } else if (_result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            _amountOut_ = _swap(
                amountOut_,
                exchangeB,
                tokenC,
                tokenA
            );
        } else {
          revert("No Arbitrage Found");
        }

        require(_amountOut_ > amountIn, "Trade Reverted, Arbitrage not profitable");

        if(tokenA == address(0)) {
            payable(devAddr).transfer(_amountOut_);
        } else {
            IERC20(tokenA).transfer(devAddr, _amountOut_);
        } 
    }

    function triangularArbitrageFlashloan(uint256 _amountIn) internal returns(uint256){
        
        address WETH = IUniswapV2Router02(exchangeB).WETH();

        // uint256 amountIn = 0;
        address _tokenA;
        if(tokenA == address(0)) { 
        //    amountIn = msg.value;
           _tokenA = WETH;
        } else { 
        //    amountIn = _amountIn;
            _tokenA = tokenA;
        }
        
        uint256 amountOut = 0;
        uint256 amountOut_ = 0;
        uint256 _amountOut_ = 0;

        Exchange result = _comparePrice(_tokenA, tokenB, _amountIn);    // loan _amountIn
        if (result == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut = _swap(
                _amountIn,
                exchangeA,
                _tokenA,
                tokenB
            );
        } else if (result == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut = _swap(
                _amountIn,
                exchangeB,
                _tokenA,
                tokenB
            );
        } else {
          revert("No Arbitrage Found");
        }

        Exchange result_ = _comparePrice(tokenB, tokenC, amountOut);    // loan amountIn
        if (result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeA,
                tokenB,
                tokenC
            );
        } else if (result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            amountOut_ = _swap(
                amountOut,
                exchangeB,
                tokenB,
                tokenC
            );
        } else {
          revert("No Arbitrage Found");
        }

        Exchange _result_ = _comparePrice(tokenC, _tokenA, amountOut_);    // loan amountIn
        if (_result_ == Exchange.EXCA) {
            // sell loanToken in uniswap for swapToken with high price and buy loanToken from sushiswap with lower price
            _amountOut_ = _swap(
                amountOut_,
                exchangeA,
                tokenC,
                _tokenA
            );
        } else if (_result_ == Exchange.EXCB) {
            // sell loanToken in sushiswap for swapToken with high price and buy loanToken from uniswap with lower price
            _amountOut_ = _swap(
                amountOut_,
                exchangeB,
                tokenC,
                _tokenA
            );
        } else {
          revert("No Arbitrage Found");
        }

        require(_amountOut_ > _amountIn, "Trade Reverted, Arbitrage not profitable");

        return _amountOut_;
    }

    function _swap(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal returns (uint256) {
      
       address WETH = IUniswapV2Router02(routerAddress).WETH();
        
        if(sell_token == address(0)) {

            sell_token = WETH;

            // IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactETHForTokens{value : amountIn}(
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];

            return amountOut;

        } else if(buy_token == address(0)) {

            buy_token = WETH;

            IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactTokensForETH(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];

            return amountOut;

        } else {
            IERC20(sell_token).approve(routerAddress, amountIn);

            uint256 amountOutMin = (_getAmountOut(
                routerAddress,
                sell_token,
                buy_token,
                amountIn
            ) * 95) / 100;

            address[] memory path = new address[](2);
            path[0] = sell_token;
            path[1] = buy_token;

            uint256 amountOut = IUniswapV2Router02(routerAddress)
                .swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp + 15 minutes
                )[1];

            return amountOut;
        }
          
    }

    function _comparePrice(address _tokenA, address _tokenB, uint256 amount) internal view returns (Exchange) {
        
        // else if(tokenC == address(0)) tokenC = WETH;
        address WETH = IUniswapV2Router02(exchangeA).WETH();
        
        if(_tokenA == address(0)) _tokenA = WETH;
        else if(_tokenB == address(0)) _tokenB = WETH;

        uint256 uniswapPrice = _getAmountOut(
            exchangeA,
            _tokenA,
            _tokenB,
            amount
        );
        uint256 sushiswapPrice = _getAmountOut(
            exchangeB,
            _tokenA,
            _tokenB,
            amount
        );

        // we try to sell ETH with higher price and buy it back with low price to make profit
        if (uniswapPrice > sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    uniswapPrice,
                    sushiswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.EXCA;
        } else if (uniswapPrice < sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    amount,
                    sushiswapPrice,
                    uniswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.EXCB;
        } else {
            return Exchange.NONE;
        }
    }

    function _checkIfArbitrageIsProfitable(
        uint256 amountIn,
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // uniswap & sushiswap have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount

        // difference in ETH
        uint256 difference = ((higherPrice - lowerPrice) * 10**18) /
            higherPrice;

        uint256 payed_fee = (amountIn * 3) / 1000;

        if (difference > payed_fee) {
            return true;
        } else {
            return false;
        }
    }

    function _getAmountOut(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {

        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }

    /**
     * @dev This function must be called only be the LENDING_POOL and takes care of repaying
     * active debt positions, migrating collateral and incurring new V2 debt token debt.
     *
     * @param assets The array of flash loaned assets used to repay debts.
     * @param amounts The array of flash loaned asset amounts used to repay debts.
     * @param premiums The array of premiums incurred as additional debts.
     * @param initiator The address that initiated the flash loan, unused.
     * @param params The byte array containing, in this case, the arrays of aTokens and aTokenAmounts.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        //
        // Try to do arbitrage with the flashloan amount.
        //
        uint256 amountOut = triangularArbitrageFlashloan(amounts[0]);
        // At the end of your logic above, this contract owes
        // the flashloaned amounts + premiums.
        // Therefore ensure your contract has enough to repay
        // these amounts.
        uint256 amountOwing = 0;
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        if(tokenA == address(0)) {
            address WETH = IUniswapV2Router02(exchangeA).WETH();
            WBNB(WETH).withdraw(amountOut.sub(amountOwing));

            payable(devAddr).transfer(amountOut.sub(amountOwing));
        } else {
            IERC20(tokenA).transfer(devAddr, amountOut.sub(amountOwing));
        }  
        
        return true;
    }

    function flashloanArbitrage(uint256 _amountIn) public payable {
        address receiverAddress = address(this);

        uint256 amountIn = 0;        
        address _tokenA;

        if(tokenA == address(0)) {
            address WETH = IUniswapV2Router02(exchangeA).WETH();
            _tokenA = WETH;
            amountIn = msg.value; 
            WBNB(WETH).deposit{value: amountIn}();
        } else {
            _tokenA = tokenA;
            amountIn = _amountIn; 
        }

        address[] memory assets = new address[](1);
        assets[0] = address(_tokenA);
        // assets[1] = address(_tokenB);
        // assets[2] = address(_tokenC);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountIn;
        // amounts[0] = getERC20Balance(wethAddress);

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        // modes[1] = INSERT_ASSET_TWO_MODE;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function getTokenBalance(address _erc20Address)
        public
        view
        returns (uint256)
    {
        return IERC20(_erc20Address).balanceOf(address(this));
    }

    function getETHBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function checkProbability(address _tokenA, address _tokenB, uint256 _amountIn) public view returns(string memory){
        Exchange result = _comparePrice(_tokenA, _tokenB, _amountIn);
        if (result == Exchange.EXCA) {
            return "Arbitrage Chances in ExchangeA";
        }else if(result == Exchange.EXCB){
            return "Arbitrage Chances in ExchangeB";
        }else{
            return "No Availabe Arbitrage";
        }
        
    }

    receive() external payable {}

    fallback() external payable { }
}

contract ArbitrageMain is Ownable {
    using SafeMath for uint256;

    address public providerAddress = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;  // Mainnet

    enum Exchange {
        EXCA,
        EXCB,
        NONE
    }

    event SimpleArbitrageDeployed(address user, address arbitrage);
    event SimpleFlashLoanArbitrageDeployed(address user, address arbitrage);
    event TriangularArbitrageDeployed(address user, address arbitrage);
    event TriangularFlashLoanArbitrageDeployed(address user, address arbitrage);

    constructor() public {
    }

    function modifyProviderAddress(address _providerAddress) external onlyOwner {
        providerAddress = _providerAddress;
    }

    function callSimpleArbitrage(address _user, address _exchangeA, address _exchangeB, address _tokenA, address _tokenB, uint256 _amountIn) public payable {
        address payable contractA = address(new FlashLoanSimpleArbitrage(providerAddress, _exchangeA, _exchangeB, _tokenA, _tokenB, _user));

        uint256 amountIn;
        if(_tokenA == address(0)) {
          amountIn = msg.value;
          FlashLoanSimpleArbitrage(contractA).simpleArbitrage{value:amountIn}(0);
        } else {
          amountIn = _amountIn; 
          IERC20(_tokenA).transferFrom(_user, address(this), amountIn);
          IERC20(_tokenA).transfer(contractA, amountIn);
          FlashLoanSimpleArbitrage(contractA).simpleArbitrage(amountIn);
        }

        // IERC20(_tokenA).approve(contractA, amountIn);
        // IERC20(_tokenB).approve(contractA, amountIn);

        emit SimpleArbitrageDeployed(_user, contractA);
    }  

    function callSimpleFlashLoan(address _user, address _exchangeA, address _exchangeB, address _tokenA, address _tokenB, uint256 _amountIn) public payable {
        address payable contractA = address(new FlashLoanSimpleArbitrage(providerAddress, _exchangeA, _exchangeB, _tokenA, _tokenB, _user));

        uint256 amountIn;
        if(_tokenA == address(0)) {
          amountIn = msg.value;
          FlashLoanSimpleArbitrage(contractA).flashloanArbitrage{value:amountIn}(0);
        } else {
          amountIn = _amountIn; 
          FlashLoanSimpleArbitrage(contractA).flashloanArbitrage(amountIn);
        }

        emit SimpleFlashLoanArbitrageDeployed(_user, contractA);
    }

    function callTriangularArbitrage(address _user, address _exchangeA, address _exchangeB, address _tokenA, address _tokenB, address _tokenC, uint256 _amountIn) public payable {
        address payable contractA = address(new FlashLoanTriangularArbitrage(providerAddress, _exchangeA, _exchangeB, _tokenA, _tokenB, _tokenC, _user));

        uint256 amountIn;
        if(_tokenA == address(0)) {
          amountIn = msg.value;
          FlashLoanTriangularArbitrage(contractA).triangularArbitrage{value:amountIn}(0);

        } else {
          amountIn = _amountIn; 
          IERC20(_tokenA).transferFrom(_user, address(this), amountIn);
          IERC20(_tokenA).transfer(contractA, amountIn);
          FlashLoanTriangularArbitrage(contractA).triangularArbitrage(amountIn);
        }

        emit TriangularArbitrageDeployed(_user, contractA);
    }

    function callTriangularFlashLoan(address _user, address _exchangeA, address _exchangeB, address _tokenA, address _tokenB, address _tokenC, uint256 _amountIn) public payable {
        address payable contractA = address(new FlashLoanTriangularArbitrage(providerAddress, _exchangeA, _exchangeB, _tokenA, _tokenB, _tokenC, _user));

        uint256 amountIn;
        if(_tokenA == address(0)) {
          amountIn = msg.value;
          FlashLoanTriangularArbitrage(contractA).flashloanArbitrage{value:amountIn}(0);   

        } else {
          amountIn = _amountIn; 
          FlashLoanTriangularArbitrage(contractA).flashloanArbitrage(amountIn);
        }

        emit TriangularFlashLoanArbitrageDeployed(_user, contractA);
    }

    function getTokenBalance(address _erc20Address)
        public
        view
        returns (uint256)
    {
        return IERC20(_erc20Address).balanceOf(address(this));
    }

    function getETHBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function withdrawERC(address _tokenAddress, uint256 amount) public onlyOwner {
        uint256 erc20Balance = getTokenBalance(_tokenAddress);
        require(amount <= erc20Balance, "Not enough balance");
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        uint256 ethBalance = getETHBalance();
        require(amount <= ethBalance, "Not enough balance");
        payable(owner).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable { }

}