pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./Context.sol";

import "./IStrategy.sol";
import "./IController.sol";

abstract contract BaseStrategy is IStrategy, Ownable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Withdrawn(
        address indexed _token,
        uint256 indexed _amount,
        address indexed _to
    );

    /// @notice reward token address
    address internal _want;

    /// @notice Controller instance getter, used to simplify controller-related actions
    address public controller;

    /// @dev Prevents other msg.sender than controller address
    modifier onlyController() {
        require(_msgSender() == controller, "!controller");
        _;
    }

    /// @dev Prevents other msg.sender than controller or vault addresses
    modifier onlyControllerOrVault() {
        require(
            _msgSender() == controller ||
                _msgSender() == IController(controller).vaults(_want),
            "!controller|vault"
        );
        _;
    }

    /// @notice Default initialize method for solving migration linearization problem
    /// @dev Called once only by deployer
    /// @param _wantAddress address of eurxb instance or address of TokenWrapper(EURxb) instance
    /// @param _controllerAddress address of controller instance
    function _configure(
        address _wantAddress,
        address _controllerAddress,
        address _governance
    ) internal {
        _want = _wantAddress;
        controller = _controllerAddress;
        transferOwnership(_governance);
    }

    /// @notice Usual setter with check if param is new
    /// @param _newController New value
    function setController(address _newController) external override onlyOwner {
        require(controller != _newController, "!old");
        controller = _newController;
    }

    /// @notice Usual setter with check if param is new
    /// @param _newWant New value
    function setWant(address _newWant) external override onlyOwner {
        require(_want != _newWant, "!old");
        _want = _newWant;
    }

    /// @notice Usual getter (inherited from IStrategy)
    /// @return 'want' token (In this case EURxb)
    function want() external view override returns (address) {
        return _want;
    }

    /// @notice must exclude any tokens used in the yield
    /// @dev Controller role - withdraw should return to Controller
    function withdraw(address _token) external virtual override onlyController {
        require(address(_token) != address(_want), "!want");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(controller, balance);
        emit Withdrawn(_token, balance, controller);
    }

    /// @notice Withdraw partial funds, normally used with a vault withdrawal
    /// @dev Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256 _amount)
        public
        virtual
        override
        onlyControllerOrVault
    {
        uint256 _balance = IERC20(_want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        address _vault = IController(controller).vaults(_want);
        IERC20(_want).safeTransfer(_vault, _amount);
        emit Withdrawn(_want, _amount, _vault);
    }

    /// @notice balance of this address in "want" tokens
    function balanceOf() public view virtual override returns (uint256) {
        return IERC20(_want).balanceOf(address(this));
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);
}
