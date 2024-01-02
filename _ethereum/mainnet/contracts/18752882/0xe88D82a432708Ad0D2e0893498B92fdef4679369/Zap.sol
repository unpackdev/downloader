// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IAsyncSwapper.sol";
import "./IRegistry.sol";
import "./IPool.sol";
import "./IStargateRouter.sol";
import "./ITokenKeeper.sol";
import "./IZap.sol";

import "./Error.sol";
import "./ERC20Utils.sol";

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";

contract Zap is IZap, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable swapper;
    address public immutable registry;
    address public immutable stargateRouter;
    address public immutable tokenKeeper;

    uint256 public constant DST_GAS = 200_000;

    // chainId -> stargateReceiver
    mapping(uint16 => address) public stargateDestinations;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(
        address _swapper,
        address _registry,
        address _stargateRouter,
        address _tokenKeeper,
        address _owner
    ) Ownable(_owner) {
        if (_swapper == address(0)) revert Error.ZeroAddress();
        if (_registry == address(0)) revert Error.ZeroAddress();
        if (_stargateRouter == address(0)) revert Error.ZeroAddress();
        if (_tokenKeeper == address(0)) revert Error.ZeroAddress();
        swapper = _swapper;
        registry = _registry;
        stargateRouter = _stargateRouter;
        tokenKeeper = _tokenKeeper;
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IZap
    function stake(address _pool, uint256 _amount) external poolExists(_pool) {
        if (_amount == 0) revert Error.ZeroAmount();

        IERC20 token = IPool(_pool).token();
        token.safeTransferFrom(msg.sender, address(this), _amount);

        _stake(_pool, address(token), _amount);
    }

    /// @inheritdoc IZap
    function stakeFromBridge(address _pool) external poolExists(_pool) {
        IERC20 token = IPool(_pool).token();
        uint256 amount = ITokenKeeper(tokenKeeper).pullToken(address(token), msg.sender);

        _stake(_pool, address(token), amount);
    }

    /// @inheritdoc IZap
    function swapAndStake(SwapParams memory _swapParams, address _pool) external poolExists(_pool) nonReentrant {
        if (_swapParams.buyTokenAddress != address(IPool(_pool).token())) revert WrongPoolToken();

        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        sellToken.safeTransferFrom(msg.sender, address(this), _swapParams.sellAmount);

        uint256 amountSwapped = _swap(_swapParams);
        _stake(_pool, _swapParams.buyTokenAddress, amountSwapped);
    }

    /// @inheritdoc IZap
    function swapAndStakeFromBridge(
        SwapParams memory _swapParams,
        address _pool
    ) external poolExists(_pool) nonReentrant {
        if (_swapParams.buyTokenAddress != address(IPool(_pool).token())) revert WrongPoolToken();

        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        uint256 amountToSwap = ITokenKeeper(tokenKeeper).pullToken(address(sellToken), msg.sender);
        if (_swapParams.sellAmount != amountToSwap) revert WrongAmount();

        uint256 amountSwapped = _swap(_swapParams);
        _stake(_pool, _swapParams.buyTokenAddress, amountSwapped);
    }

    /// @inheritdoc IZap
    function swapAndBridge(
        SwapParams memory _swapParams,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable nonReentrant {
        IERC20 sellToken = IERC20(_swapParams.sellTokenAddress);
        sellToken.safeTransferFrom(msg.sender, address(this), _swapParams.sellAmount);
        uint256 amountSwapped = _swap(_swapParams);
        _bridge(
            _swapParams.buyTokenAddress, amountSwapped, _minAmount, _dstChainId, _srcPoolId, _dstPoolId, _dstAccount
        );
    }

    /// @inheritdoc IZap
    function bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) external payable {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _bridge(_token, _amount, _minAmount, _dstChainId, _srcPoolId, _dstPoolId, _dstAccount);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IZap
    function setStargateDestinations(uint16[] calldata chainIds, address[] calldata destinations) external onlyOwner {
        uint256 len = chainIds.length;
        if (len == 0) revert Error.ZeroAmount();
        if (len != destinations.length) revert Error.ArrayLengthMismatch();

        for (uint256 i = 0; i < len; ++i) {
            uint16 chainId = chainIds[i];
            if (chainId == 0) revert InvalidChainId();
            // Zero address is ok here to allow for cancelling of chains
            stargateDestinations[chainId] = destinations[i];
        }

        emit StargateDestinationsSet(chainIds, destinations);
    }

    /*///////////////////////////////////////////////////////////////
    					    INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Bridges tokens to a specific chain using Stargate
     *  @param _token The token address
     *  @param _amount The amount of token to bridge
     *  @param _minAmount The minimum amount of bridged tokens caller is willing to accept
     *  @param _dstChainId The destination chain ID
     *  @param _srcPoolId The source pool ID
     *  @param _dstPoolId The destination pool ID
     *  @param _dstAccount The destination account
     */
    function _bridge(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _dstAccount
    ) internal {
        address dstStargateReceiver = stargateDestinations[_dstChainId];
        if (_token == address(0)) revert Error.ZeroAddress();
        if (_amount == 0) revert Error.ZeroAmount();
        if (dstStargateReceiver == address(0)) revert InvalidChainId();
        if (_dstAccount == address(0)) revert Error.ZeroAddress();

        ERC20Utils._approve(IERC20(_token), stargateRouter, _amount);

        bytes memory data = abi.encode(_dstAccount);

        IStargateRouter(stargateRouter).swap{ value: msg.value }(
            _dstChainId,
            _srcPoolId,
            _dstPoolId,
            payable(msg.sender),
            _amount,
            _minAmount,
            IStargateRouter.lzTxObj(DST_GAS, 0, "0x"),
            abi.encodePacked(dstStargateReceiver),
            data
        );
    }

    /**
     * @notice Calls the stakeFor function of a Pool contract
     * @param _pool The pool address
     * @param _token The token used in the pool
     * @param _amount The stake amount
     */
    function _stake(address _pool, address _token, uint256 _amount) internal {
        ERC20Utils._approve(IERC20(_token), _pool, _amount);
        IPool(_pool).stakeFor(msg.sender, _amount);
    }

    /**
     * @notice Calls IAsyncSwapper.Swap() using delegateCall
     * @param _swapParams A struct containing all necessary params allowing a token swap
     * @return The amount of tokens which got swapped
     */
    function _swap(SwapParams memory _swapParams) internal returns (uint256) {
        bytes memory returnedData = swapper.functionDelegateCall(
            abi.encodeWithSelector(IAsyncSwapper.swap.selector, _swapParams), _delegateSwapFailed
        );
        return abi.decode(returnedData, (uint256));
    }

    /**
     * @notice A default revert function used in case the error
     * from a reverted delegatecall isn't returned
     */
    // slither-disable-start dead-code
    function _delegateSwapFailed() internal pure {
        revert DelegateSwapFailed();
    }

    // slither-disable-end dead-code

    /*///////////////////////////////////////////////////////////////
    					    MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /// @notice modifier checking if a pool is registered
    modifier poolExists(address _pool) {
        if (!IRegistry(registry).hasPool(_pool, false)) revert PoolNotRegistered();
        _;
    }
}
