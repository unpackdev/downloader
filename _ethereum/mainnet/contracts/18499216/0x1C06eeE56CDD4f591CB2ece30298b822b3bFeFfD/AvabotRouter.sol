// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IAvabotRouter.sol";
import "./IAdapter.sol";
import "./IUniV2likeAdapter.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./SafeERC20.sol";
import "./Maintainable.sol";
import "./AvabotViewUtils.sol";
import "./Recoverable.sol";
import "./SafeERC20.sol";
import "./IUniswapFactory.sol";

contract AvabotRouter is Maintainable, Recoverable, IAvabotRouter {
    using SafeERC20 for IERC20;
    using OfferUtils for Offer;

    address public immutable WNATIVE;
    address public constant NATIVE = address(0);
    string public constant NAME = "AvabotRouter";
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public MIN_FEE = 0;
    address public FEE_CLAIMER;
    address[] public TRUSTED_TOKENS;
    address[] public ADAPTERS;

    // Avabot
    error TransferToZeroAddressAttempt();
    error TokenTransferFailed(address token, address dest, uint256 amount);
    error CallerIsNotFeeClaimer(address caller);
    error TransactionTooOld();

    event AvabotSwapFee(address indexed _token, address indexed _sender, string _referral, uint256 _feeAmount);

    modifier onlyFeeClaimer() {
        _checkFeeClaimer();
        _;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    function _checkFeeClaimer() internal view virtual {
        address msgSender = _msgSender();
        if (msgSender != FEE_CLAIMER) revert CallerIsNotFeeClaimer(msgSender);
    }

    function _checkDeadline(uint256 deadline) internal view virtual {
        if (deadline < block.timestamp) revert TransactionTooOld();
    }

    constructor(
        address[] memory _adapters,
        address[] memory _trustedTokens,
        address _feeClaimer,
        address _wrapped_native
    ) {
        setAllowanceForWrapping(_wrapped_native);
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        WNATIVE = _wrapped_native;
    }

    // -- SETTERS --

    function setAllowanceForWrapping(address _wnative) public onlyMaintainer {
        IERC20(_wnative).safeApprove(_wnative, type(uint256).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens) public override onlyMaintainer {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
    }

    function setAdapters(address[] memory _adapters) public override onlyMaintainer {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setMinFee(uint256 _fee) external override onlyMaintainer {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer) public override onlyMaintainer {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    //  -- GENERAL --

    function trustedTokensCount() external view override returns (uint256) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() external view override returns (uint256) {
        return ADAPTERS.length;
    }

    // Fallback
    receive() external payable {}

    // -- HELPERS --

    function _applyFee(uint256 _amountIn, uint256 _fee) internal view returns (uint256) {
        require(_fee >= MIN_FEE, "AvabotRouter: Insufficient fee");
        return (_amountIn * (FEE_DENOMINATOR - _fee)) / FEE_DENOMINATOR;
    }

    function _wrap(uint256 _amount) internal {
        IWETH(WNATIVE).deposit{ value: _amount }();
    }

    function _unwrap(uint256 _amount) internal {
        IWETH(WNATIVE).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for ETH
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            if (_token == NATIVE) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function _transferFrom(
        address token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from != address(this)) IERC20(token).safeTransferFrom(_from, _to, _amount);
        else IERC20(token).safeTransfer(_to, _amount);
    }

    // -- QUERIES --

    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external view override returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint256 amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) public view override returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < _options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view override returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) external view override returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "AvabotRouter: Invalid max-steps");
        Offer memory queries = OfferUtils.newOffer(_amountIn, _tokenIn);
        uint256 gasPriceInExitTkn = _gasPrice > 0 ? getGasPriceInExitTkn(_gasPrice, _tokenOut) : 0;
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, gasPriceInExitTkn);
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return queries.format();
    }

    // Find the market price between gas-asset(native) and token-out and express gas price in token-out
    function getGasPriceInExitTkn(uint256 _gasPrice, address _tokenOut) internal view returns (uint256 price) {
        // Avoid low-liquidity price appreciation (https://github.com/yieldyak/yak-aggregator/issues/20)
        FormattedOffer memory gasQuery = findBestPath(1e18, WNATIVE, _tokenOut, 2);
        if (gasQuery.path.length != 0) {
            // Leave result in nWei to preserve precision for assets with low decimal places
            price = (gasQuery.amounts[gasQuery.amounts.length - 1] * _gasPrice) / 1e9;
        }
    }

    /**
     * Return path with best returns between two tokens
     */
    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) public view override returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "AvabotRouter: Invalid max-steps");
        Offer memory queries = OfferUtils.newOffer(_amountIn, _tokenIn);
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, 0);
        // If no paths are found return empty struct
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return queries.format();
    }

    function _findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        Offer memory _queries,
        uint256 _tknOutPriceNwei
    ) internal view returns (Offer memory) {
        Offer memory bestOption = _queries.clone();
        uint256 bestAmountOut;
        uint256 gasEstimate;
        bool withGas = _tknOutPriceNwei != 0;

        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = queryNoSplit(_amountIn, _tokenIn, _tokenOut);

        if (queryDirect.amountOut != 0) {
            if (withGas) {
                gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
            }
            bestOption.addToTail(queryDirect.amountOut, queryDirect.adapter, queryDirect.tokenOut, gasEstimate);
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps > 1 && _queries.adapters.length / 32 <= _maxSteps - 2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i = 0; i < TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = queryNoSplit(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut == 0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                Offer memory newOffer = _queries.clone();
                if (withGas) {
                    gasEstimate = IAdapter(bestSwap.adapter).swapGasEstimate();
                }
                newOffer.addToTail(bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPath(
                    bestSwap.amountOut,
                    TRUSTED_TOKENS[i],
                    _tokenOut,
                    _maxSteps,
                    newOffer,
                    _tknOutPriceNwei
                ); // Recursive step
                address tokenOut = newOffer.getTokenOut();
                uint256 amountOut = newOffer.getAmountOut();
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint256 gasCostDiff = (_tknOutPriceNwei * (newOffer.gasEstimate - bestOption.gasEstimate)) /
                            1e9;
                        uint256 priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) {
                            continue;
                        }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;
    }

    // -- SWAPPERS --
    // Avabot: fee on transfer default, only fee on transfer adapter
    function _swapNoSplit(
        Trade calldata _trade,
        address _from,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        string memory _referral
    ) internal checkDeadline(_deadline) returns (uint256) {
        {
            uint256 totalAmountIn;
            if (_fee > 0 || MIN_FEE > 0) {
                if (_trade.path[_trade.path.length - 1] != WNATIVE) {
                    totalAmountIn = _applyFee(_trade.amountIn, _fee);
                    emit AvabotSwapFee(_trade.path[0], msg.sender, _referral, _trade.amountIn - totalAmountIn);
                } else {
                    totalAmountIn = _trade.amountIn;
                }
            } else {
                totalAmountIn = _trade.amountIn;
            }
            if(IAdapter(_trade.adapters[0]).isUniV2like()) {
                address factory = IUniV2likeAdapter(_trade.adapters[0]).factory();
                _transferFrom(_trade.path[0], _from, IUniswapFactory(factory).getPair(_trade.path[0], _trade.path[1]), totalAmountIn);
            } else {
                _transferFrom(_trade.path[0], _from, _trade.adapters[0], totalAmountIn);
            }
        }

        uint256[] memory amounts = new uint256[](2);
        // stack too deep explain
        // amounts[0]: _toBalance
        // amounts[1]: _swapAmount

        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress;
            if (_trade.path[_trade.path.length - 1] == WNATIVE) {
                targetAddress = i < _trade.adapters.length - 1 ? _trade.adapters[i + 1] : address(this);
            } else {
                targetAddress = i < _trade.adapters.length - 1 ? _trade.adapters[i + 1] : _to;
            }

            amounts[0] = IERC20(_trade.path[i + 1]).balanceOf(targetAddress);
            IAdapter(_trade.adapters[i]).swap(0, 0, _trade.path[i], _trade.path[i + 1], targetAddress);
            if (i == _trade.adapters.length - 1) {
                uint256 diff = IERC20(_trade.path[i + 1]).balanceOf(targetAddress) - amounts[0];
                require(diff >= _trade.amountOut, "AvabotRouter: Insufficient output amount");
                amounts[1] = diff;
            }
        }

        uint256 totalAmountOut;
        if (_fee > 0 || MIN_FEE > 0) {
            if (_trade.path[_trade.path.length - 1] == WNATIVE) {
                totalAmountOut = _applyFee(amounts[1], _fee);
                require(totalAmountOut >= _trade.amountOut, "AvabotRouter: Insufficient output amount");
                emit AvabotSwapFee(
                    _trade.path[_trade.path.length - 1],
                    msg.sender,
                    _referral,
                    amounts[1] - totalAmountOut
                );
            } else {
                totalAmountOut = amounts[1];
            }
        } else {
            totalAmountOut = amounts[1];
        }
        if (_trade.path[_trade.path.length - 1] == WNATIVE && _to != address(this)) {
            IERC20(_trade.path[_trade.path.length - 1]).safeTransfer(_to, totalAmountOut);
        }
        emit AvabotSwap(
            _trade.path[0],
            _trade.path[_trade.path.length - 1],
            _trade.amountIn,
            totalAmountOut,
            msg.sender,
            _fee
        );
        return totalAmountOut;
    }

    function swapNoSplit(
        Trade calldata _trade,
        uint256 _fee,
        uint256 _deadline,
        string calldata _referral
    ) public override {
        _swapNoSplit(_trade, msg.sender, msg.sender, _fee, _deadline, _referral);
    }

    function swapNoSplitFromETH(
        Trade calldata _trade,
        uint256 _fee,
        uint256 _deadline,
        string calldata _referral
    ) external payable override {
        require(_trade.path[0] == WNATIVE, "AvabotRouter: Path needs to begin with WETH");
        _wrap(_trade.amountIn);
        _swapNoSplit(_trade, address(this), msg.sender, _fee, _deadline, _referral);
    }

    function swapNoSplitToETH(
        Trade calldata _trade,
        uint256 _fee,
        uint256 _deadline,
        string calldata _referral
    ) public override {
        require(_trade.path[_trade.path.length - 1] == WNATIVE, "AvabotRouter: Path needs to end with WETH");
        uint256 returnAmount = _swapNoSplit(_trade, msg.sender, address(this), _fee, _deadline, _referral);
        _unwrap(returnAmount);
        _returnTokensTo(NATIVE, returnAmount, msg.sender);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapNoSplitWithPermit(
        Trade calldata _trade,
        uint256 _fee,
        uint256 _deadline,
        string calldata _referral,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplit(_trade, _fee, _deadline, _referral);
    }

    /**
     * Swap token to ETH without the need to approve the first token
     */
    function swapNoSplitToETHWithPermit(
        Trade calldata _trade,
        uint256 _fee,
        uint256 _deadline,
        string calldata _referral,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplitToETH(_trade, _fee, _deadline, _referral);
    }

    // Avabot

    /**
     * @dev Utility method to be able to transfer native tokens out of Smart Account
     * @notice only owner/ signatory of Smart Account with enough gas to spend can call this method
     * @notice While enabling multisig module and renouncing ownership this will not work
     * @param _dest Destination address
     * @param _amount Amount of native tokens
     */
    function transfer(address payable _dest, uint256 _amount) external onlyFeeClaimer {
        if (_dest == address(0)) revert TransferToZeroAddressAttempt();
        bool success;
        assembly {
            success := call(gas(), _dest, _amount, 0, 0, 0, 0)
        }
        if (!success) revert TokenTransferFailed(address(0), _dest, _amount);
    }

    /**
     * @dev Utility method to be able to transfer ERC20 tokens out of Smart Account
     * @notice only owner/ signatory of Smart Account with enough gas to spend can call this method
     * @notice While enabling multisig module and renouncing ownership this will not work
     * @param _token Token address
     * @param _dest Destination/ Receiver address
     * @param _amount Amount of tokens
     */
    function pullTokens(
        address _token,
        address _dest,
        uint256 _amount
    ) external onlyFeeClaimer {
        if (_dest == address(0)) revert TransferToZeroAddressAttempt();
        IERC20(_token).safeTransfer(_dest, _amount);
    }
}
