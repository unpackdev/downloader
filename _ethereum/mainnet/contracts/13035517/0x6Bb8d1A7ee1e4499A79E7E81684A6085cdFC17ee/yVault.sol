// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IController.sol";
import "./IVault.sol";

/// @title yVault yAgnostic.
/// @dev yVault inherits ERC20.
contract yVault is IVault, ERC20, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /// @notice Underlying token the vault operates with.
    /// @dev Set in constructor.
    /// @return Underlying token the vault operates with.
    address public override token;

    /// @notice Displays percentage to calculate available.
    /// @dev By default: 9500(95%).
    /// @return Percentage to calculate available.
    uint256 public min = 9500;

    /// @notice Displays percentage to calculate available.
    /// @dev By default: 10000(100%).
    /// @return Percentage to calculate available.
    uint256 public constant MAX = 10000;

    /// @notice Variable storing the governance address. By default it is equal to the deployer of the controller.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setGovernance method.
    /// @return Returns the governance address of this contract.
    address public override governance;

    /// @notice Variable storing the controller address.
    /// @notice By default, it is equal to the address specified during deployment.
    /// @dev Specified when creating the controller (in the constructor).
    /// @dev Can also be changed using the setController method.
    /// @return Returns the controller address of this contract.
    address public override controller;

    /// @notice Modifier to restrict the method for governance only.
    modifier governanceOnly() {
        require(_msgSender() == governance, "Not the governance");
        _;
    }

    /// @notice Modifier to restrict the method for controller only.
    modifier controllerOnly() {
        require(_msgSender() == controller, "Not the controller");
        _;
    }

    /// @notice Sets token name: yfiag + name, token symbol: y + symbol.
    /// @notice Sets the governance address equal to the deployer.
    /// @param _token Address of the token the vault work with.
    /// @param _controller Address of the controller.
    constructor(address _token, address _controller)
        public
        ERC20(
            string(abi.encodePacked("yfiag ", ERC20(_token).name())),
            string(abi.encodePacked("y", ERC20(_token).symbol()))
        )
    {
        _setupDecimals(ERC20(_token).decimals());
        token = _token;
        governance = _msgSender();
        controller = _controller;
    }

    /******
    * Governance regulated parameters
    ******/

    /// @notice called by the owner to pause, triggers stopped state
    function pause() whenNotPaused governanceOnly external {
        _pause();
    }

    /// @notice called by the owner to unpause, returns to normal state
    function unpause() whenPaused governanceOnly external {
        _unpause();
    }

    /// @notice Set percentage of tokens allowed for the strategy.
    /// @dev Can only be called by governance. The maximum value is 10000(100%).
    /// @param _min Percentage to calculate available.
    function setMin(uint256 _min) external governanceOnly {
        require(_min <= MAX, "min<=max");
        min = _min;
    }

    /// @notice Specifies a new governance address.
    /// @dev Can only be called by governance.
    /// @param _governance Address of the new governance.
    function setGovernance(address _governance) external governanceOnly {
        governance = _governance;
    }

    /// @notice Specifies a new controller address.
    /// @dev Can only be called by governance.
    /// @param _controller Address of the new controller.
    function setController(address _controller) external governanceOnly {
        controller = _controller;
    }

    /******
    * Vault functionality
    ******/

    /// @notice Method transferring tokens to a strategy through controller.
    function earn() whenNotPaused external {
        uint256 _bal = available();
        IERC20(token).safeTransfer(controller, _bal);
        IController(controller).earn(address(this), address(token), _bal);
    }

    /// @notice Used to swap any borrowed reserve over the debt limit to liquidate to underlying 'token'
    /// @param reserve Address of the reserve token.
    /// @param amount Amount of the tokens.
    function harvest(address reserve, uint256 amount) external controllerOnly {
         require(reserve != address(token), "token");
         IERC20(reserve).safeTransfer(controller, amount);
    }

    /// @notice Causes the deposit of all available sender tokens.
    function depositAll() whenNotPaused external override {
        deposit(IERC20(token).balanceOf(_msgSender()));
    }

    /// @notice Causes the deposit of amount sender tokens.
    /// @param _amount Amount of the tokens.
    function deposit(uint256 _amount) whenNotPaused nonReentrant public override {
        uint256 _pool = balance();

        uint256 _before = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 _after = IERC20(token).balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(_msgSender(), shares);
    }

    /// @notice Causes the withdraw of all available sender shares.
    function withdrawAll() whenNotPaused external override {
        withdraw(balanceOf(_msgSender()));
    }

    // No rebalance implementation for lower fees and faster swaps
    /// @notice Causes the withdraw of amount sender shares.
    /// @param _shares Amount of the shares.
    function withdraw(uint256 _shares) whenNotPaused public override {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(_msgSender(), _shares);

        // Check balance
        uint256 b = IERC20(token).balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(_withdraw);
            uint256 _after = IERC20(token).balanceOf(address(this));
            require(_after >= r, "Not enough balance");
        }

        IERC20(token).safeTransfer(_msgSender(), r);
    }

    /*****
    * View interface
    *****/

    /// @notice Сalculates the price per full share.
    /// @return Returns the price per full share.
    function getPricePerFullShare() external view override returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    /// @notice Shows how many tokens are available (in total in the volt and deposited to the strategy).
    function balance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this)).add(IController(controller).balanceOf(address(this)));
    }

    /// @notice Сalculates the available amount that can be transferred to the strategy.
    /// @dev Custom logic in here for how much the vault allows to be borrowed
    /// @dev Sets minimum required on-hand to keep small withdrawals cheap
    /// @return Returns the available vault.
    function available() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this)).mul(min).div(MAX);
    }
}
