// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IStableSwap3Pool.sol";
import "./ISwap.sol";
import "./IManager.sol";
import "./IStrategy.sol";
import "./IController.sol";

/**
 * @title BaseStrategy
 * @notice The BaseStrategy is an abstract contract which all
 * yAxis strategies should inherit functionality from. It gives
 * specific security properties which make it hard to write an
 * insecure strategy.
 * @notice All state-changing functions implemented in the strategy
 * should be internal, since any public or externally-facing functions
 * are already handled in the BaseStrategy.
 * @notice The following functions must be implemented by a strategy:
 * - function _deposit() internal virtual;
 * - function _harvest() internal virtual;
 * - function _withdraw(uint256 _amount) internal virtual;
 * - function _withdrawAll() internal virtual;
 * - function balanceOfPool() public view override virtual returns (uint256);
 */
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    address public immutable override want;
    address public immutable override weth;
    address public immutable controller;
    IManager public immutable override manager;
    string public override name;
    address[] public routerArray;
    ISwap public override router;

    /**
     * @param _controller The address of the controller
     * @param _manager The address of the manager
     * @param _want The desired token of the strategy
     * @param _weth The address of WETH
     * @param _routerArray The addresses of routers for swapping tokens
     */
    constructor(
        string memory _name,
        address _controller,
        address _manager,
        address _want,
        address _weth,
        address[] memory _routerArray
    ) public {
        name = _name;
        want = _want;
        controller = _controller;
        manager = IManager(_manager);
        weth = _weth;
        require(_routerArray.length > 0, "Must input at least one router");
        routerArray = _routerArray;
        router = ISwap(_routerArray[0]);
        for(uint i = 0; i < _routerArray.length; i++) {
            IERC20(_weth).safeApprove(address(_routerArray[i]), 0);
            IERC20(_weth).safeApprove(address(_routerArray[i]), type(uint256).max);
        }
        
    }

    /**
     * GOVERNANCE-ONLY FUNCTIONS
     */

    /**
     * @notice Approves a token address to be spent by an address
     * @param _token The address of the token
     * @param _spender The address of the spender
     * @param _amount The amount to spend
     */
    function approveForSpender(
        IERC20 _token,
        address _spender,
        uint256 _amount
    )
        external
    {
        require(msg.sender == manager.governance(), "!governance");
        _token.safeApprove(_spender, 0);
        _token.safeApprove(_spender, _amount);
    }

    /**
     * @notice Sets the address of the ISwap-compatible router
     * @param _routerArray The addresses of routers
     * @param _tokenArray The addresses of tokens that need to be approved by the strategy
     */
     function setRouter(
        address[] calldata _routerArray,
        address[] calldata _tokenArray
    )
        external
    {
        require(msg.sender == manager.governance(), "!governance");
        routerArray = _routerArray;
        router = ISwap(_routerArray[0]);
        address _router;
        uint256 _routerLength = _routerArray.length;
        uint256 _tokenArrayLength = _tokenArray.length;
        for(uint i = 0; i < _routerLength; i++) {
            _router = _routerArray[i];
            IERC20(weth).safeApprove(_router, 0);
            IERC20(weth).safeApprove(_router, type(uint256).max);
            for(uint j = 0; j < _tokenArrayLength; j++) {
                IERC20(_tokenArray[j]).safeApprove(_router, 0);
                IERC20(_tokenArray[j]).safeApprove(_router, type(uint256).max);
            }
        }

    }
    
    /**
     * @notice Sets the default ISwap-compatible router
     * @param _routerIndex Gets the address of the router from routerArray
     */
     function setDefaultRouter(
        uint256 _routerIndex
    )
        external
    {
    	require(msg.sender == manager.governance(), "!governance");
    	router = ISwap(routerArray[_routerIndex]);
    }

    /**
     * CONTROLLER-ONLY FUNCTIONS
     */

    /**
     * @notice Deposits funds to the strategy's pool
     */
    function deposit()
        external
        override
        onlyController
    {
        _deposit();
    }

    /**
     * @notice Harvest funds in the strategy's pool
     */
    function harvest(
        uint256[] calldata _estimates
    )
        external
        override
        onlyController
    {
        _harvest(_estimates);
    }

    /**
     * @notice Sends stuck want tokens in the strategy to the controller
     */
    function skim()
        external
        override
        onlyController
    {
        IERC20(want).safeTransfer(controller, balanceOfWant());
    }

    /**
     * @notice Sends stuck tokens in the strategy to the controller
     * @param _asset The address of the token to withdraw
     */
    function withdraw(
        address _asset
    )
        external
        override
        onlyController
    {
        require(want != _asset, "want");

        IERC20 _assetToken = IERC20(_asset);
        uint256 _balance = _assetToken.balanceOf(address(this));
        _assetToken.safeTransfer(controller, _balance);
    }

    /**
     * @notice Initiated from a vault, withdraws funds from the pool
     * @param _amount The amount of the want token to withdraw
     */
    function withdraw(
        uint256 _amount
    )
        external
        override
        onlyController
    {
        uint256 _balance = balanceOfWant();
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(controller, _amount);
    }

    /**
     * @notice Withdraws all funds from the strategy
     */
    function withdrawAll()
        external
        override
        onlyController
    {
        _withdrawAll();

        uint256 _balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(controller, _balance);
    }

    /**
     * EXTERNAL VIEW FUNCTIONS
     */

    /**
     * @notice Returns the strategy's balance of the want token plus the balance of pool
     */
    function balanceOf()
        external
        view
        override
        returns (uint256)
    {
        return balanceOfWant().add(balanceOfPool());
    }

    /**
     * PUBLIC VIEW FUNCTIONS
     */

    /**
     * @notice Returns the balance of the pool
     * @dev Must be implemented by the strategy
     */
    function balanceOfPool()
        public
        view
        virtual
        override
        returns (uint256);

    /**
     * @notice Returns the balance of the want token on the strategy
     */
    function balanceOfWant()
        public
        view
        override
        returns (uint256)
    {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * INTERNAL FUNCTIONS
     */

    function _deposit()
        internal
        virtual;

    function _harvest(
        uint256[] calldata _estimates
    )
        internal
        virtual;

    function _payHarvestFees(
        address _poolToken,
        uint256 _estimatedWETH,
        uint256 _estimatedYAXIS,
        uint256 _routerIndex
    )
        internal
        returns (uint256 _wethBal)
    {
        uint256 _amount = IERC20(_poolToken).balanceOf(address(this));
        _swapTokens(_poolToken, weth, _amount, _estimatedWETH);
        _wethBal = IERC20(weth).balanceOf(address(this));

        if (_wethBal > 0) {
            // get all the necessary variables in a single call
            (
                address yaxis,
                address treasury,
                uint256 treasuryFee
            ) = manager.getHarvestFeeInfo();

            uint256 _fee;

            // pay the treasury with YAX
            if (treasuryFee > 0 && treasury != address(0)) {
                _fee = _wethBal.mul(treasuryFee).div(ONE_HUNDRED_PERCENT);

                _swapTokensWithRouterIndex(weth, yaxis, _fee, _estimatedYAXIS, _routerIndex);
                IERC20(yaxis).safeTransfer(treasury, IERC20(yaxis).balanceOf(address(this)));
            }

            // return the remaining WETH balance
            _wethBal = IERC20(weth).balanceOf(address(this));
        }
    }

    function _swapTokensWithRouterIndex(
        address _input,
        address _output,
        uint256 _amount,
        uint256 _expected,
        uint256 _routerIndex
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = _input;
        path[1] = _output;
        ISwap(routerArray[_routerIndex]).swapExactTokensForTokens(
            _amount,
            _expected,
            path,
            address(this),
            // The deadline is a hardcoded value that is far in the future.
            1e10
        );
    }
    
    function _swapTokens(
        address _input,
        address _output,
        uint256 _amount,
        uint256 _expected
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = _input;
        path[1] = _output;
        router.swapExactTokensForTokens(
            _amount,
            _expected,
            path,
            address(this),
            // The deadline is a hardcoded value that is far in the future.
            1e10
        );
    }

    function _withdraw(
        uint256 _amount
    )
        internal
        virtual;

    function _withdrawAll()
        internal
        virtual;

    function _withdrawSome(
        uint256 _amount
    )
        internal
        returns (uint256)
    {
        uint256 _before = IERC20(want).balanceOf(address(this));
        _withdraw(_amount);
        uint256 _after = IERC20(want).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    /**
     * MODIFIERS
     */

    modifier onlyStrategist() {
        require(msg.sender == manager.strategist(), "!strategist");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "!controller");
        _;
    }
}
