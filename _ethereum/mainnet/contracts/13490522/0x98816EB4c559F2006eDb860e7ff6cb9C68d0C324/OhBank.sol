// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IBank.sol";
import "./IStrategy.sol";
import "./IManager.sol";
import "./IRegistry.sol";
import "./TransferHelper.sol";
import "./OhSubscriberUpgradeable.sol";
import "./OhBankStorage.sol";

/// @title Oh! Finance Bank
/// @notice ERC-20 Token that represents user share ownership
/// @dev Base Upgradeable Bank Contract
contract OhBank is ERC20Upgradeable, ERC20PermitUpgradeable, OhSubscriberUpgradeable, OhBankStorage, IBank {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Emitted when the Bank invests in a Strategy
    event Invest(address strategy, uint256 amount);

    /// @notice Emitted when a user deposits an amount of underlying
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws an amount of underlying
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Event emitted when an amount is withdrawn and exits a strategy
    event Exit(address indexed strategy, uint256 amount);

    /// @notice Event emitted when all capital is withdrawn and exitted from a strategy
    event ExitAll(address indexed strategy);

    /// @notice Event emitted when an amount is withdrawn and exits a strategy
    event Pause(address indexed governance);

    /// @notice Event emitted when all capital is withdrawn and exitted from a strategy
    event Unpause(address indexed governance);

    /// @notice Protocol defense modifier
    /// @dev Only allow user-facing functions to be called by EOA or be whitelisted
    modifier defense {
        require(msg.sender == tx.origin || IManager(manager()).whitelisted(msg.sender), "Bank: Only EOA or whitelisted");
        _;
    }

    /// @notice Initialize the Bank Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(underlying() == address(0));
    }

    /// @notice Initialize the Bank Proxy
    /// @param name_ The name of the Bank Token
    /// @param symbol_ The symbol of the Bank Token
    /// @param registry_ Rhe address of the registry
    /// @param underlying_ Rhe address of the underlying token that is deposited
    /// @dev Should be called when deploying the proxy contract
    function initializeBank(
        string memory name_,
        string memory symbol_,
        address registry_,
        address underlying_
    ) public initializer {
        // setup token first, use same token decimals
        uint8 decimals_ = ERC20Upgradeable(underlying_).decimals();
        __ERC20_init(name_, symbol_);
        _setupDecimals(decimals_);

        // setup permit
        __ERC20Permit_init(name_);

        // initialize subscriber and storage
        initializeSubscriber(registry_);
        initializeStorage(underlying_);
    }

    /// @notice The Bank Strategy at index i
    /// @param i The Strategy index
    /// @return The address of the Strategy
    function strategies(uint256 i) public view override returns (address) {
        return IManager(manager()).strategies(address(this), i);
    }

    /// @notice Total Strategies for this Bank
    /// @return The number of Strategies this Bank uses
    function totalStrategies() public view override returns (uint256) {
        return IManager(manager()).totalStrategies(address(this));
    }

    /// @notice Get the underlying balance on the Bank
    /// @return Underlying token balance
    function underlyingBalance() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @notice Get the virtual balance invested in the Strategy at a given index
    /// @dev Virtual Balance represents the amount of underlying available if we withdrew all
    /// @param i The Strategy Index
    /// @return The virtual balance of underlying invested in the Strategy
    function strategyBalance(uint256 i) public view override returns (uint256) {
        address strategy = strategies(i);
        return IStrategy(strategy).investedBalance();
    }

    /// @notice Get the total virtual amount invested in all Strategies
    /// @return amount The virtual balance invested in all Strategies
    function investedBalance() public view override returns (uint256 amount) {
        uint256 length = totalStrategies();
        for (uint256 i = 0; i < length; i++) {
            amount = amount.add(strategyBalance(i));
        }
    }

    /// @notice Get the total virtual amount available to the bank
    /// @return The balance of underlying if we were to exit all Strategies
    function virtualBalance() public view override returns (uint256) {
        return underlyingBalance().add(investedBalance());
    }

    /// @notice The virtual price of each token
    /// @return The amount of underlying each token represents
    function virtualPrice() public view override returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 unit = 10**decimals();
        return totalSupply == 0 ? unit : virtualBalance().mul(unit).div(totalSupply);
    }

    /// @notice Invest a given amount underlying into a given strategy
    /// @dev Only callable by Governance or Manager
    /// @param strategy The address of the Strategy to invest in
    /// @param amount The amount of underlying to invest in the Strategy
    function invest(address strategy, uint256 amount) external override onlyAuthorized {
        _invest(strategy, amount);
    }

    /// @notice Invest all available underlying into a given strategy
    /// @dev Only callable by Governance or Manager
    /// @param strategy The address of the Strategy to invest all underlying in
    function investAll(address strategy) external override onlyAuthorized {
        _invest(strategy, underlyingBalance());
    }

    /// @notice Exit and withdraw a given amount from a strategy
    /// @param strategy The address of the Strategy to exit
    function exit(address strategy, uint256 amount) external override onlyAuthorized {
        IStrategy(strategy).withdraw(amount);
        emit Exit(strategy, amount);
    }

    /// @notice Exit and withdraw all underlying from a given strategy
    function exitAll(address strategy) external override onlyAuthorized {
        IStrategy(strategy).withdrawAll();
        emit ExitAll(strategy);
    }

    /// @notice Pause the Bank
    function pause() external override onlyGovernance {
        _setPaused(true);
        emit Pause(msg.sender);
    }

    /// @notice Unpause the Bank
    function unpause() external override onlyGovernance {
        _setPaused(false);
        emit Unpause(msg.sender);
    }

    /// @notice Deposit an amount of underlying to receive Bank shares
    /// @dev Deposits for the caller
    /// @param amount The amount of underlying to deposit
    function deposit(uint256 amount) external override defense {
        _deposit(amount, msg.sender, msg.sender);
    }

    /// @notice Deposit an amount of underlying for a given recipient
    /// @dev Deposits for any address except the burn address
    /// @param amount The amount of underlying to deposit
    /// @param recipient The address to receive Bank shares
    function depositFor(uint256 amount, address recipient) external override defense {
        require(recipient != address(0), "Bank: Invalid Recipient");
        _deposit(amount, msg.sender, recipient);
    }

    /// @notice Deposit with Permit for ERC712 Compliant Tokens
    /// @param amount The amount of undelrying to deposit
    /// @param recipient The address to receive Bank shares
    /// @param deadline The UNIX timestamp the permit expires at
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    function depositWithPermit(
        uint256 amount,
        address recipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external defense {
        require(recipient != address(0), "Bank: Invalid Recipient");
        IERC20Permit(underlying()).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(amount, msg.sender, recipient);
    }

    // withdraw an amount of shares for underlying
    function withdraw(uint256 shares) external override defense {
        _withdraw(msg.sender, shares);
    }

    /// @dev Invest an amount into a strategy
    function _invest(address strategy, uint256 amount) internal {
        // transfer to strategy if amount > 0
        if (amount > 0) {
            TransferHelper.safeTokenTransfer(strategy, underlying(), amount);
        }
        // perform strategy investment, handle no new underlying in strategy
        IStrategy(strategy).invest();
        emit Invest(strategy, amount);
    }

    // deposit underlying to receive shares
    function _deposit(
        uint256 amount,
        address sender,
        address recipient
    ) internal {
        require(totalStrategies() > 0, "Bank: No Strategies");
        require(amount > 0, "Bank: Invalid Deposit");

        uint256 totalSupply = totalSupply();
        uint256 mintAmount = totalSupply == 0 ? amount : amount.mul(totalSupply).div(virtualBalance());

        _mint(recipient, mintAmount);
        IERC20(underlying()).safeTransferFrom(sender, address(this), amount);

        emit Deposit(recipient, amount);
    }

    /// @dev Withdraw shares for underlying
    /// @dev 3 scenarios can occur
    /// @dev   1. If we have enough underlying on the Bank to cover the withdrawal, transfer from Bank
    /// @dev   2. Else if we are withdrawing all shares, withdraw all underlying tokens
    /// @dev   3. Else, transfer from each Strategy until the withdrawal is satisfied
    function _withdraw(address user, uint256 shares) internal {
        require(shares > 0, "Bank: Invalid withdrawal");
        uint256 totalSupply = totalSupply();
        _burn(user, shares);

        uint256 balance = underlyingBalance();
        uint256 withdrawAmount = virtualBalance().mul(shares).div(totalSupply);
        if (withdrawAmount > balance) {
            if (shares == totalSupply) {
                _withdrawAll();
            } else {
                _withdrawRemaining(withdrawAmount.sub(balance));
            }
        }

        TransferHelper.safeTokenTransfer(user, underlying(), withdrawAmount);
        emit Withdraw(user, withdrawAmount);
    }

    /// @dev Withdraw all underlying to the bank
    function _withdrawAll() internal {
        uint256 length = totalStrategies();
        for (uint256 i = 0; i < length; i++) {
            IStrategy(strategies(i)).withdrawAll();
        }
    }

    /// @dev Withdraw from each strategy until remaining amount is reached
    function _withdrawRemaining(uint256 amount) internal {
        address manager = manager();
        uint256 index = IManager(manager).withdrawIndex(address(this));
        uint256 length = totalStrategies();
        uint256 i = 0;

        // while we haven't withdrawn from each Strategy and we haven't withdrawn the total amount
        while (i < length && amount > 0) {
            // perform the Strategy withdrawal
            uint256 withdrawn = IStrategy(strategies(index)).withdraw(amount);

            // update variables
            amount = amount.sub(withdrawn);
            i = i + 1;

            // increment Strategy index or restart
            if (index - 1 == length) {
                index = 0;
            } else {
                index = index + 1;
            }
        }

        // update withdrawal index
        IManager(manager).setWithdrawIndex(index);
    }
}
