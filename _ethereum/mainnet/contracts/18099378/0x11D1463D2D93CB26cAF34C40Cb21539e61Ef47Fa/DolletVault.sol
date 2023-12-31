// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IStrategyConvex.sol";
import "./IAdminStructure.sol";
import "./IWETH.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * @notice This is the contract that receives funds and that users interface with.
 * @notice The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 */
contract DolletVault is ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev The strategy currently in use by the vault.
     */
    IStrategyConvex public strategy;
    /**
     * @dev Contract that stores the information of the admins.
     */
    IAdminStructure public adminStructure;

    /**
     * @dev Stores the deposit limit amounts for a token
     */
    mapping(address => DepositLimit) public tokenDepositLimit;

    /**
     * @notice Structure of the values stored in the token deposit limits
     */
    struct DepositLimit {
        address token; // Address of the token
        uint256 minAmount; // Minimum amount allowed for deposits
        uint256 maxAmount; // Maximum amount allowed for deposits
    }
    /**
     * @notice Logs when the deposit limit of a token has been changed
     * @param limitBefore Structure of the deposit limit before
     * @param limitAfter Structure of the deposit limit after
     */
    event EditedDepositLimits(DepositLimit limitBefore, DepositLimit limitAfter);

    /**
     * @notice Logs when stucked tokens have been withdrawn
     * @param caller Address of the caller of the transaction
     * @param token Address of the token withdrawn
     * @param amount Withdrawn amount
     */
    event WithdrawStuckTokens(address caller, address token, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the vault values like the admin stucture contract, strategy, name
     * @dev Symbol, and the deposit limits.
     * @param _adminStructure The address of the admin stucture contract.
     * @param _strategy The address of the strategy contract.
     * @param _name The name of the vault token.
     * @param _symbol The symbol of the vault token.
     * @param _depositLimits Array indicating the deposit limits
     */
    function initialize(
        IAdminStructure _adminStructure,
        IStrategyConvex _strategy,
        string calldata _name,
        string calldata _symbol,
        DepositLimit[] calldata _depositLimits
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();
        strategy = _strategy;
        require(address(_adminStructure) != address(0), "ZeroAdminStructure");
        adminStructure = _adminStructure;
        for (uint256 i = 0; i < _depositLimits.length; i++) {
            tokenDepositLimit[_depositLimits[i].token] = _depositLimits[i];
        }
    }

    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     * @param _amount Amount to be deposited
     * @param _token Address of token to be deposited
     * @param _minWant Minimum amount obtained fromt he deposit on curve
     */
    function deposit(
        uint256 _amount,
        IERC20Upgradeable _token,
        uint256 _minWant
    ) external payable nonReentrant {
        _validateDepositLimit(_token, _amount);
        strategy.harvestOnDeposit();
        uint256 _before = balance();
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        earn(_token, _minWant);
        uint256 _after = balance();
        _amount = _after - _before;
        uint256 _shares = 0;
        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * totalSupply()) / _before;
        }
        _mint(msg.sender, _shares);
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of dollet vault
     * tokens are burned in the process.
     * @param _token The token to be received in the withdrawal
     * @param _minCurveOutput Minimum amount tokens obtained from curve
     */
    function withdrawAll(address _token, uint256 _minCurveOutput) external nonReentrant {
        uint256 _shares = balanceOf(msg.sender);
        require(_shares > 0, "UserHasZeroLP");
        strategy.harvest();
        uint256 _amount = (balance() * _shares) / totalSupply();
        _burn(msg.sender, _shares);
        strategy.withdraw(msg.sender, _amount, _token, _minCurveOutput);
        uint256 _tokenBal = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _tokenBal);
    }

    /**
     * @dev Claims rewards from the Vault for a specific token.
     * @param _token The address of the token to claim rewards for.
     * @param _minCurveOutput The minimum amount of tokens to receive from Curve.
     */
    function claimRewards(address _token, uint256 _minCurveOutput) external nonReentrant {
        uint256 _shares = balanceOf(msg.sender);
        require(_shares > 0, "UserHasZeroLP");
        strategy.harvest();
        uint256 _before = balance();
        uint256 _amount = (_before * _shares) / totalSupply();
        strategy.claimRewards(msg.sender, _token, _amount, _minCurveOutput);
        uint256 _after = balance();
        uint256 _wantSpent = _before - _after;
        uint256 _amountLP = (_wantSpent * totalSupply()) / _before;
        _burn(msg.sender, _amountLP);
        uint256 _tokenBal = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _tokenBal);
    }

    /**
     * @dev Estimates the deposit details for a specific token and amount.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _slippage The allowed slippage percentage.
     * @return amountLP The amount of LP tokens to receive from the vault
     * @return amountWant The minimum amount of LP tokens to get from curve deposit
     */
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 amountLP, uint256 amountWant) {
        uint256 _before = estimateWantAfterHarvest(_slippage);
        amountWant = strategy.calculations().estimateDeposit(_token, _amount, _slippage);
        if (totalSupply() == 0) {
            amountLP = amountWant;
        } else {
            amountLP = (amountWant * totalSupply()) / _before;
        }
    }

    /**
     * @dev Estimates the withdrawal details for a specific user and token.
     * @param _user The address of the user.
     * @param _token The address of the token to withdraw.
     * @param _slippage The allowed slippage percentage.
     * @return minCurveOutput The minimum amount of tokens to receive from Curve.
     * @return withdrawable The amount of tokens available that will be accepted from the withdrawal.
     */
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 withdrawable) {
        uint256 _balanceUser = balanceOf(_user);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0 || _balanceUser == 0) return (0, 0);
        uint256 _amount = (estimateWantAfterHarvest(_slippage) * _balanceUser) / _totalSupply;
        return strategy.calculations().estimateWithdrawal(_user, _token, _amount, _slippage);
    }

    /**
     * @dev Estimates the rewards details for a specific user and token.
     * @param _user The address of the user.
     * @param _token The address of the token to check rewards for.
     * @param _slippage The allowed slippage percentage.
     * @return minCurveOutput The minimum amount of tokens to receive from Curve.
     * @return claimable The amount of tokens claimable as rewards.
     */
    function estimateRewards(
        address _user,
        address _token,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 claimable) {
        uint256 _balanceUser = balanceOf(_user);
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0 || _balanceUser == 0) return (0, 0);
        uint256 amount = (estimateWantAfterHarvest(_slippage) * _balanceUser) / _totalSupply;
        (minCurveOutput, claimable) = strategy.calculations().estimateRewards(
            _user,
            _token,
            amount,
            _slippage
        );
    }

    /**
     * @dev Estimates the want amount after calling harvest useful for other estimation
     * @param _slippage The allowed slippage percentage.
     * @return want amount after harvest
     */
    function estimateWantAfterHarvest(uint256 _slippage) public returns (uint256) {
        return strategy.calculations().estimateWantAfterHarvest(_slippage);
    }

    /**
     * @dev Estimates the total rewards claimable for all users for a specific token.
     * @param _token The address of the token to check rewards for.
     * @param _slippage The allowed slippage percentage.
     * @return claimable The total amount of tokens claimable as rewards.
     */
    function estimateAllUsersRewards(
        address _token,
        uint256 _slippage
    ) external returns (uint256 claimable) {
        claimable = strategy.calculations().estimateAllUsersRewards(
            _token,
            estimateWantAfterHarvest(_slippage),
            _slippage
        );
    }

    /**
     * @dev Allows the super admin to set the strategy
     * @param _strategy The address of the strategy
     */
    function setStrategy(IStrategyConvex _strategy) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_strategy) != address(0), "ZeroStrategy");
        strategy = _strategy;
    }

    /**
     * @dev Handles the case where tokens get stuck in the Vault. Allows the admin to send the tokens to the super admin
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external {
        adminStructure.isValidAdmin(msg.sender);
        require(_token != address(want()), "ZeroToken");

        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(adminStructure.superAdmin(), _amount);
        emit WithdrawStuckTokens(msg.sender, _token, _amount);
    }

    /**
     * @dev Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit structs representing the new deposit limits.
     */
    function editDepositLimits(DepositLimit[] calldata _depositLimits) external {
        adminStructure.isValidAdmin(msg.sender);
        for (uint256 i = 0; i < _depositLimits.length; i++) {
            emit EditedDepositLimits(tokenDepositLimit[_depositLimits[i].token], _depositLimits[i]);
            tokenDepositLimit[_depositLimits[i].token] = _depositLimits[i];
        }
    }

    /**
     * @notice Estimates the amount of tokens to swap from one token to another
     * @param _from The address of the token to swap from
     * @param _to The address of the token to swap to
     * @param _amount The amount of tokens to swap
     * @param _slippage The allowed slippage percentage
     * @return estimate The estimated amount of tokens to receive after the swap
     */
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate) {
        return strategy.calculations().estimateSwap(_from, _to, _amount, _slippage);
    }

    /**
     * @dev Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of LP tokens to withdraw from curve.
     * @param _slippage The allowed slippage percentage.
     * @return The minimum amount of tokens to receive from Curve.
     */
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256) {
        return strategy.calculations().calculateCurveMinWithdrawal(_token, _amount, _slippage);
    }

    /**
     * @notice Calculates the amount of LP tokens to get on curve deposit
     * @param _amount The amount of tokens to deposit
     * @param _slippage The allowed slippage percentage
     * @return The amount of LP tokens to get
     */
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256) {
        return strategy.calculations().calculateCurveDeposit(_token, _amount, _slippage);
    }

    /**
     * @dev Returns the amount of tokens deposited by a specific user in the indicated token
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The amount of tokens deposited by the user.
     */
    function userDeposit(address _user, address _token) external view returns (uint256) {
        return strategy.calculations().userDeposit(_user, _token);
    }

    /**
     * @dev Returns the total amount of tokens deposited in the strategy in the indicated token
     * @param _token The address of the token.
     * @return The total amount of tokens deposited.
     */
    function totalDeposits(address _token) external view returns (uint256) {
        return strategy.calculations().totalDeposits(_token);
    }

    /**
     * @dev Returns the address of the token that the Vault holds.
     * @return The address of the want token
     */
    function want() public view returns (IERC20Upgradeable) {
        return IERC20Upgradeable(strategy.want());
    }

    /**
     * @dev Calculated the total balance of the want token
     * It takes into account the vault contract balance, the strategy contract balance
     * and the balance deployed in other contracts as part of the strategy.
     * @return The total balance of the want token
     */
    function balance() public view returns (uint256) {
        return want().balanceOf(address(this)) + IStrategyConvex(strategy).balanceOf();
    }

    /**
     * @dev Function to send funds into the strategy and put them to work.
     * @dev It's primarily called by the vault's deposit() function.
     * @param _token The token used in the deposit
     */
    function earn(IERC20Upgradeable _token, uint256 _minWant) internal {
        uint256 _tokenBal = _token.balanceOf(address(this));
        _token.safeTransfer(address(strategy), _tokenBal);
        strategy.deposit(address(_token), msg.sender, _minWant);
    }

    /**
     * @dev Override of the internal function of ERC20 token transfer.
     * @dev Implemented to disable transfers on the Dollet LP token.
     */
    function _transfer(address, address, uint256) internal pure override {
        revert("DisabledTransfers");
    }

    /**
     * @dev Validated the deposit limits for specific tokens.
     * @param _token Address of the token to validate.
     * @param _amount Amount to validate.
     */
    function _validateDepositLimit(IERC20Upgradeable _token, uint256 _amount) private view {
        DepositLimit memory _depositLimits = tokenDepositLimit[address(_token)];

        require(_depositLimits.token == address(_token), "InvalidDepositToken");
        require(
            _amount >= _depositLimits.minAmount && _amount <= _depositLimits.maxAmount,
            "InvalidDepositAmount"
        );
    }
}
