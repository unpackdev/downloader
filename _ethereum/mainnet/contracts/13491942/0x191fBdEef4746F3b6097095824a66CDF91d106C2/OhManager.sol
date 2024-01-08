// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Address.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IBank.sol";
import "./ILiquidator.sol";
import "./IManager.sol";
import "./IToken.sol";
import "./TransferHelper.sol";
import "./OhSubscriber.sol";

/// @title Oh! Finance Manager
/// @notice The Manager contains references to all active banks, strategies, and liquidation contracts.
/// @dev This contract is used as the main control point for executing strategies
contract OhManager is OhSubscriber, IManager {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    /// @notice Denominator for calculating protocol fees
    uint256 public constant FEE_DENOMINATOR = 1000;

    /// @notice Maximum buyback fee, 50%
    uint256 public constant MAX_BUYBACK_FEE = 500;

    /// @notice Minimum buyback fee, 10%
    uint256 public constant MIN_BUYBACK_FEE = 100;

    /// @notice Maximum management fee, 10%
    uint256 public constant MAX_MANAGEMENT_FEE = 100;

    /// @notice Minimum management fee, 0%
    uint256 public constant MIN_MANAGEMENT_FEE = 0;

    /// @notice The address of the Oh! Finance Token
    address public override token;

    /// @notice The amount of profits reserved for protocol buybacks, base 1000
    uint256 public override buybackFee;

    /// @notice The amount of profits reserved for fund management, base 1000
    uint256 public override managementFee;

    /// @notice The mapping of `from` token to `to` token to liquidator contract
    mapping(address => mapping(address => address)) public override liquidators;

    /// @notice The mapping of contracts that are whitelisted for Bank use/management
    mapping(address => bool) public override whitelisted;

    /// @dev The set of Banks approved for investing
    EnumerableSet.AddressSet internal _banks;

    /// @dev The mapping of Banks to active Strategies
    mapping(address => EnumerableSet.AddressSet) internal _strategies;

    /// @dev The mapping of Banks to next Strategy index it will deposit to
    mapping(address => uint8) internal _depositQueue;

    /// @dev The mapping of Banks to next Strategy index it will withdraw from
    mapping(address => uint8) internal _withdrawQueue;

    /// @notice Emitted when a Bank's capital is rebalanced
    event Rebalance(address indexed bank);

    /// @notice Emitted when a Bank's capital is invested in a single Strategy 
    event Finance(address indexed bank, address indexed strategy);

    /// @notice Emitted when a Bank's capital is invested in all Strategies
    event FinanceAll(address indexed bank);

    /// @notice Emitted when a buyback is performed with an amount of from tokens
    event Buyback(address indexed from, uint256 amount, uint256 buybackAmount);

    /// @notice Emitted when a Bank realizes profit via liquidation 
    event AccrueRevenue(
        address indexed bank,
        address indexed strategy,
        uint256 profitAmount,
        uint256 buybackAmount,
        uint256 managementAmount
    );

    /// @notice Only allow function calls if sender is an approved Bank
    /// @param sender The address of the caller to validate
    modifier onlyBank(address sender) {
        require(_banks.contains(sender), "Manager: Only Bank");
        _;
    }
    
    /// @notice Only allow function calls if sender is an approved Strategy
    /// @param bank The address of the Bank that uses the Strategy
    /// @param sender The address of the caller to validate
    modifier onlyStrategy(address bank, address sender) {
        require(_strategies[bank].contains(sender), "Manager: Only Strategy");
        _;
    }

    /// @notice Only allow EOAs or Whitelisted contracts to interact
    /// @dev Prevents sandwich / flash loan attacks & re-entrancy
    modifier defense {
        require(msg.sender == tx.origin || whitelisted[msg.sender], "Manager: Only EOA or Whitelist");
        _;
    }

    /// @notice Deploy the Manager with the Registry reference
    /// @dev Sets initial buyback and management fee parameters
    /// @param registry_ The address of the registry
    /// @param token_ The address of the Oh! Token
    constructor(address registry_, address token_) OhSubscriber(registry_) {
        token = token_;
        buybackFee = 200; // 20%
        managementFee = 20; // 2%
    }

    /// @notice Get the Bank
    function banks(uint256 i) external view override returns (address) {
        return _banks.at(i);
    }

    function totalBanks() external view override returns (uint256) {
        return _banks.length();
    }

    /// @notice Get the Strategy at a given index for a given Bank
    /// @param bank The address of the Bank that contains the Strategy
    /// @param i The Bank queue index to check
    function strategies(address bank, uint256 i) external view override returns (address) {
        return _strategies[bank].at(i);
    }

    /// @notice Get total number of strategies for a given bank
    /// @param bank The Bank we are checking
    /// @return Amount of active strategies
    function totalStrategies(address bank) external view override returns (uint256) {
        return _strategies[bank].length();
    }

    /// @notice Get the index of the Strategy to withdraw from for a given Bank
    /// @param bank The Bank to check the next Strategy for
    /// @return The index of the Strategy
    function withdrawIndex(address bank) external view override returns (uint256) {
        return _withdrawQueue[bank];
    }

    /// @notice Set the withdrawal index
    /// @param i The 
    function setWithdrawIndex(uint256 i) external override onlyBank(msg.sender) {
        _withdrawQueue[msg.sender] = uint8(i);
    }

    /// @notice Rebalance Bank exposure by withdrawing all, then evenly distributing underlying to all strategies
    /// @param bank The bank to rebalance
    function rebalance(address bank) external override defense onlyBank(bank) {
        // Exit all strategies
        uint256 length = _strategies[bank].length();
        for (uint256 i; i < length; i++) {
            IBank(bank).exitAll(_strategies[bank].at(i));
        }

        // Re-invest underlying evenly
        uint256 toInvest = IBank(bank).underlyingBalance();
        for (uint256 i; i < length; i++) {
            uint256 amount = toInvest / length;
            IBank(bank).invest(_strategies[bank].at(i), amount);
        }

        emit Rebalance(bank);
    }

    /// @notice Finance the next Strategy in the Bank queue with all available underlying
    /// @param bank The address of the Bank to finance
    /// @dev Only allow this function to be called on approved Banks
    function finance(address bank) external override defense onlyBank(bank) {
        uint256 length = _strategies[bank].length();
        require(length > 0, "Manager: No Strategies");

        // get the next Strategy, reset if current index out of bounds
        uint8 i;
        uint8 queued = _depositQueue[bank];
        if (queued < length) {
            i = queued;
        } else {
            i = 0;
        }
        address strategy = _strategies[bank].at(i);

        // finance the strategy, increment index and update delay (+24h)
        IBank(bank).investAll(strategy);
        _depositQueue[bank] = i + 1;

        emit Finance(bank, strategy);
    }

    /// @notice Evenly finance underlying to all strategies
    /// @param bank The address of the Bank to finance
    /// @dev Deposit queue not needed here as all Strategies are equally invested in
    /// @dev Only allow this function to be called on approved Banks
    function financeAll(address bank) external override defense onlyBank(bank) {
        uint256 length = _strategies[bank].length();
        require(length > 0, "Manager: No Strategies");

        uint256 toInvest = IBank(bank).underlyingBalance();
        for (uint256 i; i < length; i++) {
            uint256 amount = toInvest / length;
            IBank(bank).invest(_strategies[bank].at(i), amount);
        }

        emit FinanceAll(bank);
    }

    /// @notice Perform a token buyback with accrued revenue
    /// @dev Burns all proceeds
    /// @param from The address of the token to liquidate for Oh! Tokens
    function buyback(address from) external override defense {
        // get token, liquidator, and liquidation amount
        address _token = token;
        address liquidator = liquidators[from][_token];
        uint256 amount = IERC20(from).balanceOf(address(this));

        // send to liquidator, buyback and burn
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(address(this), from, _token, amount, 1);
        IToken(_token).burn(received);

        emit Buyback(from, amount, received);
    }

    /// @notice Accrue revenue from a Strategy
    /// @dev Only callable by approved Strategies
    /// @param bank The address of the Bank which uses the Strategy
    /// @param amount The total amount of profit received from liquidation
    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external override onlyStrategy(bank, msg.sender) {
        // calculate protocol and management fees, find remaining
        uint256 fee = amount.mul(buybackFee).div(FEE_DENOMINATOR);
        uint256 reward = amount.mul(managementFee).div(FEE_DENOMINATOR);
        uint256 remaining = amount.sub(fee).sub(reward);

        // send original function caller the management fee, transfer remaining to the Strategy
        TransferHelper.safeTokenTransfer(tx.origin, underlying, reward);
        TransferHelper.safeTokenTransfer(msg.sender, underlying, remaining);

        emit AccrueRevenue(bank, msg.sender, remaining, fee, reward);
    }

    /// @notice Exit a given strategy for a given bank
    /// @param bank The bank that will be used to exit the strategy
    /// @param strategy The strategy to be exited
    function exit(address bank, address strategy) public onlyGovernance {
        IBank(bank).exitAll(strategy);
    }

    /// @notice Exit from all strategies for a given bank
    /// @param bank The bank that will be used to exit the strategy
    function exitAll(address bank) public override onlyGovernance {
        uint256 length = _strategies[bank].length();
        for (uint256 i = 0; i < length; i++) {
            IBank(bank).exitAll(_strategies[bank].at(i));
        }
    }

    /// @notice Adds or removes a Bank for investment
    /// @dev Only Governance can call this function
    /// @param _bank the bank to be approved/unapproved
    /// @param _approved the approval status of the bank
    function setBank(address _bank, bool _approved) external onlyGovernance {
        require(_bank.isContract(), "Manager: Not Contract");
        bool approved = _banks.contains(_bank);
        require(approved != _approved, "Manager: No Change");

        // if Bank is already approved, withdraw all capital
        if (approved) {
            exitAll(_bank);
            _banks.remove(_bank);
        } else {
            _banks.add(_bank);
        }
    }

    /// @notice Adds or removes a Strategy for a given Bank
    /// @param _bank the bank which uses the strategy
    /// @param _strategy the strategy to be approved/unapproved
    /// @param _approved the approval status of the Strategy
    /// @dev Only Governance can call this function
    function setStrategy(address _bank, address _strategy, bool _approved) external onlyGovernance {
        require(_strategy.isContract() && _bank.isContract(), "Manager: Not Contract");
        bool approved = _strategies[_bank].contains(_strategy);
        require(approved != _approved, "Manager: No Change");

        // if Strategy is already approved, withdraw all capital
        if (approved) {
            exit(_bank, _strategy);
            _strategies[_bank].remove(_strategy);
        } else {
            _strategies[_bank].add(_strategy);
        }
    }

    /// @notice Sets the Liquidator contract for a given token
    /// @param _liquidator the liquidator contract
    /// @param _from the token we have to liquidate
    /// @param _to the token we want to receive
    /// @dev Only Governance can call this function
    function setLiquidator(
        address _liquidator,
        address _from,
        address _to
    ) external onlyGovernance {
        require(_liquidator.isContract(), "Manager: Not Contract");
        liquidators[_from][_to] = _liquidator;
    }

    /// @notice Whitelists strategy for Bank use/management
    /// @param _contract the strategy contract
    /// @param _whitelisted the whitelisted status of the strategy
    /// @dev Only Governance can call this function
    function setWhitelisted(address _contract, bool _whitelisted) external onlyGovernance {
        require(_contract.isContract(), "Registry: Not Contract");
        whitelisted[_contract] = _whitelisted;
    }

    /// @notice Sets the protocol buyback percentage (Profit Share)
    /// @param _buybackFee The new buyback fee
    /// @dev Only Governance; base 1000, 1% = 10
    function setBuybackFee(uint256 _buybackFee) external onlyGovernance {
        require(_buybackFee > MIN_BUYBACK_FEE, "Registry: Invalid Buyback");
        require(_buybackFee < MAX_BUYBACK_FEE, "Registry: Buyback Too High");
        buybackFee = _buybackFee;
    }

    /// @notice Sets the protocol management fee percentage
    /// @param _managementFee The new management fee
    /// @dev Only Governance; base 1000, 1% = 10
    function setManagementFee(uint256 _managementFee) external onlyGovernance {
        require(_managementFee > MIN_MANAGEMENT_FEE, "Registry: Invalid Mgmt");
        require(_managementFee < MAX_MANAGEMENT_FEE, "Registry: Mgmt Too High");
        managementFee = _managementFee;
    }
}
