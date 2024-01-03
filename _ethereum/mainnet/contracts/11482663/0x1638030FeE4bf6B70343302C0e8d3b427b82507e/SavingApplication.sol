// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IController.sol";
import "./IAccount.sol";
import "./IVault.sol";

/**
 * @notice Application to save assets from account to vaults to
 * earn yield and rewards.
 */
contract SavingApplication is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event StrategistUpdated(address indexed oldStrategist, address indexed newStrategist);
    event ControllerUpdated(address indexed oldController, address indexed newController);
    event AutoSavingUpdated(address indexed account, address indexed token, bool indexed allowed);
    event AutoSavingThresholdUpdated(address indexed token, uint256 oldValue, uint256 newValue);
    event Deposited(address indexed account, uint256 indexed vaultId, address token, uint256 amount);
    event Withdrawn(address indexed account, uint256 indexed vaultId, address token, uint256 amount);
    event Claimed(address indexed account, uint256 indexed vaultId, address token, uint256 amount);
    event Exited(address indexed account, uint256 indexed vaultId);

    // Account ==> Token ==> Auto saving 
    mapping(address => mapping(address => bool)) public autoSaving;
    // Token ==> Auto saving threshold
    mapping(address => uint256) public autoSavingThreshold;
    address public controller;
    address public governance;
    address public strategist;

    uint256[50] private __gap;

    /**
     * @dev Initializes the saving application. Can be called only once.
     */
    function initialize(address _controller) public initializer {
        require(_controller != address(0x0), "controller not set");
        controller = _controller;
        governance = msg.sender;
        strategist = msg.sender;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "not governance");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == governance || msg.sender == strategist, "not strategist");
        _;
    }

    /**
     * @dev Updates the govenance address.
     * Only governance can set a new governance. The governance can be renounced
     * by setting a zero address.
     */
    function setGovernance(address _governance) public onlyGovernance {
        address oldGovernance = governance;
        governance = _governance;
        emit GovernanceUpdated(oldGovernance, _governance);
    }

    /**
     * @dev Updates the strategist address. Only governance can update strategist.
     * Each vault has its own strategist to perform daily permissioned opertions.
     * Vault and its strategies managed share the same strategist.
     */
    function setStrategist(address _strategist) public onlyGovernance {
        address oldStrategist = strategist;
        strategist = _strategist;
        emit StrategistUpdated(oldStrategist, _strategist);
    }

    /**
     * @dev Updates the controller address.
     * Only governance can set a new controller.
     */
    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0x0), "controller not set");
        address oldController = address(controller);
        controller = _controller;
        emit ControllerUpdated(oldController, _controller);
    }

    function _validateAccount(IAccount _account) internal view {
        require(_account.owner() == msg.sender, "not owner");
        require(_account.isOperator(address(this)), "not operator");
    }

    /**
     * @dev Updates auto saving policy on account. When auto saving is enabled on
     * an account on a token, strategist can help to deposit account's token to its vault.
     * @param _account Account to enable auto saving.
     * @param _token The token to enable auto saving.
     * @param _allowed Whether auto saving is allowed.
     */
    function setAutoSaving(address _account, address _token, bool _allowed) public {
        _validateAccount(IAccount(_account));
        autoSaving[_account][_token] = _allowed;
        emit AutoSavingUpdated(_account, _token, _allowed);
    }

    /**
     * @dev Updates auto saving threshold for a token. If the token balance of an account is
     * below the threshold, strategist won't help to deposit the account's token even if auto saving
     * is enabled on the account for that token.
     * @param _token The token to set auto saving threshold.
     * @param _value The new auto saving threshold to that token.
     */
    function setAutoSavingThreshold(address _token, uint256 _value) public onlyStrategist {
        uint256 oldValue = autoSavingThreshold[_token];
        autoSavingThreshold[_token] = _value;
        emit AutoSavingThresholdUpdated(_token, oldValue, _value);
    }

    /**
     * @dev Deposit token into rewarded vault.
     * @param _account The account address used to deposit.
     * @param _vaultId ID of the vault to deposit.
     * @param _amount Amount of token to deposit.
     * @param _claimRewards Whether to claim rewards at the same time.
     */
    function deposit(address _account, uint256 _vaultId, uint256 _amount, bool _claimRewards) external {
        IVault vault = IVault(IController(controller).vaults(_vaultId));
        require(address(vault) != address(0x0), "no vault");
        require(_amount > 0, "zero amount");

        IAccount account = IAccount(_account);
        _validateAccount(account);
        address token = vault.want();
        account.approveToken(token, address(vault), _amount);

        bytes memory methodData = abi.encodeWithSignature("deposit(uint256)", _amount);
        account.invoke(address(vault), 0, methodData);

        emit Deposited(_account, _vaultId, token, _amount);

        if (_claimRewards) {
            _claimAllRewards(_account, _vaultId, address(vault));
        }
    }

    /**
     * @dev Withdraws token out of RewardedVault.
     * @param _account The account address used to withdraw.
     * @param _vaultId ID of the vault to withdraw.
     * @param _amount Amount of token to withdraw.
     * @param _claimRewards Whether to claim rewards at the same time.
     */
    function withdraw(address _account, uint256 _vaultId, uint256 _amount, bool _claimRewards) external {
        IVault vault = IVault(IController(controller).vaults(_vaultId));
        require(address(vault) != address(0x0), "no vault");
        require(_amount > 0, "zero amount");
        IAccount account = IAccount(_account);
        _validateAccount(account);
        address token = IVault(vault).want();

        // Important: Need to convert token amount to vault share!
        uint256 totalBalance = vault.balance();
        uint256 totalSupply = IERC20Upgradeable(address(vault)).totalSupply();
        uint256 shares = _amount.mul(totalSupply).div(totalBalance);
        bytes memory methodData = abi.encodeWithSignature("withdraw(uint256)", shares);
        account.invoke(address(vault), 0, methodData);

        emit Withdrawn(_account, _vaultId, token, _amount);

        if (_claimRewards) {
            _claimAllRewards(_account, _vaultId, address(vault));
        }
    }

    /**
     * @dev Exit the vault and claims all rewards.
     * @param _account The account address used to exit.
     * @param _vaultId ID of the vault to exit.
     */
    function exit(address _account, uint256 _vaultId) external {
        IVault vault = IVault(IController(controller).vaults(_vaultId));
        require(address(vault) != address(0x0), "no vault");
        IAccount account = IAccount(_account);
        _validateAccount(account);

        bytes memory methodData = abi.encodeWithSignature("exit()");
        account.invoke(address(vault), 0, methodData);

        emit Exited(_account, _vaultId);
    }

    /**
     * @dev Claims rewards from RewardedVault.
     * @param _account The account address used to claim rewards.
     * @param _vaultId ID of the vault to claim rewards.
     */
    function claimRewards(address _account, uint256 _vaultId) public {
        IVault vault = IVault(IController(controller).vaults(_vaultId));
        require(address(vault) != address(0x0), "no vault");
        IAccount account = IAccount(_account);
        _validateAccount(account);

        _claimAllRewards(_account, _vaultId, address(vault));
    }

    /**
     * @dev Internal method to claims rewards. Account and vault parameters should be already validated.
     */
    function _claimAllRewards(address _account, uint256 _vaultId, address _vault) internal {
        address rewardToken = IController(controller).rewardToken();
        bytes memory methodData = abi.encodeWithSignature("claimReward()");
        bytes memory methodResult = IAccount(_account).invoke(_vault, 0, methodData);
        uint256 claimAmount = abi.decode(methodResult, (uint256));

        emit Claimed(_account, _vaultId, rewardToken, claimAmount);
    }

    /**
     * @dev Deposits into vault on behalf of the accounts provided. This can be only called by strategist.
     * @param _accounts Accounts to deposit token from.
     * @param _vaultId ID of the target vault.
     */
    function depositForAccounts(address[] memory _accounts, uint256 _vaultId) public onlyStrategist {
        IVault vault = IVault(IController(controller).vaults(_vaultId));
        require(address(vault) != address(0x0), "no vault");
        address token = vault.want();
        // If the account's balance is below the threshold, no op.
        uint256 threshold = autoSavingThreshold[token];

        for (uint256 i = 0; i < _accounts.length; i++) {
            IAccount account = IAccount(_accounts[i]);
            require(account.isOperator(address(this)), "not operator");
            require(autoSaving[_accounts[i]][token], "not allowed");

            uint256 amount = IERC20Upgradeable(token).balanceOf(_accounts[i]);
            // No op if the account's balance is under threshold.
            if (amount < threshold) continue;
            account.approveToken(token, address(vault), amount);

            bytes memory methodData = abi.encodeWithSignature("deposit(uint256)", amount);
            account.invoke(address(vault), 0, methodData);

            emit Deposited(_accounts[i], _vaultId, token, amount);

        }
    }
}