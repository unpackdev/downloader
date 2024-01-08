pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";

import "./IController.sol";
import "./IStrategy.sol";
import "./IConverter.sol";

/// @title Controller
/// @notice The contract is the middleman between vault and strategy, it balances and trigger earn processes
contract Controller is IController, Ownable, Initializable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Emits when funds are withdrawn fully from related to vault strategy
    /// @param _token Token address to be withdrawn
    event WithdrawToVaultAll(address _token);
    event Earn(address _token, uint256 _amount);

    /// @dev token => vault
    mapping(address => address) public override vaults;

    /// @dev token => strategy
    mapping(address => address) public override strategies;

    /// @dev from => to => converter address
    mapping(address => mapping(address => address)) public override converters;

    /// @dev token => strategy => is strategy approved
    mapping(address => mapping(address => bool))
        public
        override approvedStrategies;

    /// @notice Strategist is an actor who created the strategies and he is receiving fees from strategies execution
    address public strategist;

    /// @notice Treasury contract address (used to channel fees to governance and rewards for voting process and investors)
    address private _treasury;

    /// @dev Prevents other msg.sender than either governance or strategist addresses
    modifier onlyOwnerOrStrategist() {
        require(
            _msgSender() == strategist || _msgSender() == owner(),
            "!governance|strategist"
        );
        _;
    }

    /// @notice Default initialize method for solving migration linearization problem
    /// @dev Called once only by deployer
    /// @param _initialTreasury treasury contract address
    /// @param _initialStrategist strategist address
    function configure(
        address _initialTreasury,
        address _initialStrategist,
        address _governance
    ) external onlyOwner initializer {
        _treasury = _initialTreasury;
        strategist = _initialStrategist;
        transferOwnership(_governance);
    }

    /// @notice Used only to rescue stuck funds from controller to msg.sender
    /// @param _token Token to rescue
    /// @param _amount Amount tokens to rescue
    function inCaseTokensGetStuck(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(_msgSender(), _amount);
    }

    /// @notice Used only to rescue stuck or unrelated funds from strategy to vault
    /// @param _strategy Strategy address
    /// @param _token Unrelated token address
    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
        external
        onlyOwnerOrStrategist
    {
        IStrategy(_strategy).withdraw(_token);
    }

    /// @notice Withdraws funds from strategy to related vault
    /// @param _token Token address to withdraw
    /// @param _amount Amount tokens
    function withdraw(address _token, uint256 _amount) external override {
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    function claim(address _wantToken, address _tokenToClaim)
        external
        override
    {
        IStrategy(strategies[_wantToken]).claim(_tokenToClaim);
    }

    /// @notice forces the strategy to take away the rewards due to it
    // this method must call via backend
    /// @param _token want token address
    function getRewardStrategy(address _token) external override {
        IStrategy(strategies[_token]).getRewards();
    }

    /// @notice Usual setter with additional checks
    /// @param _newTreasury New value
    function setTreasury(address _newTreasury) external onlyOwner {
        require(_treasury != _newTreasury, "!old");
        require(_newTreasury != address(0), "!treasury");
        require(_newTreasury.isContract(), "!contract");
        _treasury = _newTreasury;
    }

    /// @notice Usual setter with check if param is new
    /// @param _newStrategist New value
    function setStrategist(address _newStrategist) external onlyOwner {
        require(strategist != _newStrategist, "!old");
        strategist = _newStrategist;
    }

    /// @notice Used to obtain fees receivers address
    /// @return Treasury contract address
    function rewards() external view override returns (address) {
        return _treasury;
    }

    /// @notice Usual setter of vault in mapping with check if new vault is not address(0)
    /// @param _token Business logic token of the vault
    /// @param _vault Vault address
    function setVault(address _token, address _vault)
        external
        override
        onlyOwnerOrStrategist
    {
        require(vaults[_token] == address(0), "!vault 0");
        vaults[_token] = _vault;
    }

    /// @notice Usual setter of converter contract, it implements the optimal logic to token conversion
    /// @param _input Input token address
    /// @param _output Output token address
    /// @param _converter Converter contract
    function setConverter(
        address _input,
        address _output,
        address _converter
    ) external onlyOwnerOrStrategist {
        converters[_input][_output] = _converter;
    }

    /// @notice Sets new link between business logic token and strategy, and if strategy is already used, withdraws all funds from it to the vault
    /// @param _token Business logic token address
    /// @param _strategy Corresponded strategy contract address
    function setStrategy(address _token, address _strategy)
        external
        override
        onlyOwnerOrStrategist
    {
        require(approvedStrategies[_token][_strategy], "!approved");
        address _current = strategies[_token];
        if (_current != address(0)) {
            uint256 amount = IERC20(IStrategy(_current).want()).balanceOf(
                address(this)
            );
            IStrategy(_current).withdraw(amount);
            emit WithdrawToVaultAll(_token);
        }
        strategies[_token] = _strategy;
    }

    /// @notice Approves strategy to be added to mapping, needs to be done before setting strategy
    /// @param _token Business logic token address
    /// @param _strategy Strategy contract address
    /// @param _status Approved or not (bool)?
    function setApprovedStrategy(
        address _token,
        address _strategy,
        bool _status
    ) external onlyOwner {
        approvedStrategies[_token][_strategy] = _status;
    }

    /// @notice The method converts if needed given token to business logic strategy token,
    /// transfers converted tokens to strategy, and executes the business logic
    /// @param _token Given token address (wERC20)
    /// @param _amount Amount of given token address
    function earn(address _token, uint256 _amount) public override {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            require(converter != address(0), "!converter");
            require(
                IERC20(_token).transfer(converter, _amount),
                "!transferConverterToken"
            );
            _amount = IConverter(converter).convert(_strategy);
        }
        require(
            IERC20(_want).transfer(_strategy, _amount),
            "!transferStrategyWant"
        );
        IStrategy(_strategy).deposit();
        emit Earn(_token, _amount);
    }
}
