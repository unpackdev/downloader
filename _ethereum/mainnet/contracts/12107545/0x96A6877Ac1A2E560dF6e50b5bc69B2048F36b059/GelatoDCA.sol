// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./DSMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Utils.sol";
import "./IKyberProxy.sol";
import "./IChainlinkOracle.sol";
import "./IOracleAggregator.sol";
import "./ITaskStorage.sol";
import "./IUniswapV2Router02.sol";
import "./FToken.sol";
import "./SimpleServiceStandard.sol";
import "./ReentrancyGuard.sol";
import "./FPayment.sol";
import "./CTokens.sol";
import "./SGelato.sol";
import "./IGelato.sol";

contract GelatoDCA is SimpleServiceStandard, ReentrancyGuard, Utils {
    using SafeERC20 for IERC20;

    struct SubmitOrder {
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 numTrades;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        address platformWallet;
        uint256 platformFeeBps;
    }

    struct ExecOrder {
        address user;
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 nTradesLeft;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        uint256 lastExecutionTime;
        address platformWallet;
        uint256 platformFeeBps;
    }

    enum Dex {KYBER, UNISWAP, SUSHISWAP}

    bytes public constant HINT = "";
    uint256 internal constant _MAX_AMOUNT = type(uint256).max;

    IUniswapV2Router02 public immutable uniRouterV2;
    IUniswapV2Router02 public immutable sushiRouterV2;
    IKyberProxy public immutable kyberProxy;

    mapping(address => mapping(address => uint256)) public platformWalletFees;

    event LogTaskSubmitted(uint256 indexed id, ExecOrder order);
    event LogTaskCancelled(uint256 indexed id, ExecOrder order);
    event LogTaskUpdated(uint256 indexed id, ExecOrder order);
    event LogDCATrade(uint256 indexed id, ExecOrder order, uint256 outAmount);
    event ClaimedPlatformFees(
        address[] wallets,
        address[] tokens,
        address claimer
    );

    constructor(
        IKyberProxy _kyberProxy,
        IUniswapV2Router02 _uniRouterV2,
        IUniswapV2Router02 _sushiRouterV2,
        address _gelato
    ) SimpleServiceStandard(_gelato) {
        kyberProxy = _kyberProxy;
        uniRouterV2 = _uniRouterV2;
        sushiRouterV2 = _sushiRouterV2;
    }

    function submit(SubmitOrder memory _order, bool _isSubmitAndExec)
        public
        payable
    {
        if (_order.inToken == ETH) {
            uint256 value =
                _isSubmitAndExec
                    ? _order.amountPerTrade * (_order.numTrades + 1)
                    : _order.amountPerTrade * _order.numTrades;
            require(
                msg.value == value,
                "GelatoDCA.submit: mismatching amount of ETH deposited"
            );
        }
        ExecOrder memory order =
            ExecOrder({
                user: msg.sender,
                inToken: _order.inToken,
                outToken: _order.outToken,
                amountPerTrade: _order.amountPerTrade,
                nTradesLeft: _order.numTrades,
                minSlippage: _order.minSlippage,
                maxSlippage: _order.maxSlippage,
                delay: _order.delay, // solhint-disable-next-line not-rely-on-time
                lastExecutionTime: block.timestamp,
                platformWallet: _order.platformWallet,
                platformFeeBps: _order.platformFeeBps
            });

        // store order
        _storeOrder(order);
    }

    // solhint-disable-next-line function-max-lines
    function submitAndExec(
        SubmitOrder memory _order,
        Dex _protocol,
        uint256 _minReturnOrRate,
        address[] calldata _tradePath
    ) external payable {
        require(
            _order.numTrades > 1,
            "GelatoDCA.submitAndExec: cycle must have 2 or more trades"
        );

        // 1. Submit future orders
        _order.numTrades = _order.numTrades - 1;
        submit(_order, true);

        // 2. Exec 1st Trade now
        if (_order.inToken != ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                msg.sender,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeIncreaseAllowance(
                getProtocolAddress(_protocol),
                _order.amountPerTrade
            );
        }

        if (_protocol == Dex.KYBER) {
            _doKyberTrade(
                _order.inToken,
                _order.outToken,
                _order.amountPerTrade,
                _minReturnOrRate,
                payable(msg.sender),
                payable(_order.platformWallet),
                _order.platformFeeBps
            );
        } else {
            _doUniswapTrade(
                _protocol == Dex.UNISWAP ? uniRouterV2 : sushiRouterV2,
                _tradePath,
                _order.amountPerTrade,
                _minReturnOrRate,
                payable(msg.sender),
                payable(_order.platformWallet),
                _order.platformFeeBps
            );
        }
    }

    function cancel(ExecOrder calldata _order, uint256 _id)
        external
        nonReentrant
    {
        _removeTask(abi.encode(_order), _id, msg.sender);
        if (_order.inToken == ETH) {
            uint256 refundAmount = _order.amountPerTrade * _order.nTradesLeft;
            (bool success, ) = _order.user.call{value: refundAmount}("");
            require(success, "GelatoDCA.cancel: Could not refund ETH");
        }

        emit LogTaskCancelled(_id, _order);
    }

    // solhint-disable-next-line function-max-lines
    function editNumTrades(
        ExecOrder calldata _order,
        uint256 _id,
        uint256 _newNumTradesLeft
    ) external payable nonReentrant {
        require(
            _order.nTradesLeft != _newNumTradesLeft,
            "GelatoDCA.editNumTrades: order does not need update"
        );
        require(_newNumTradesLeft > 0, "GelatoDCA.editNumTrades: cannot be 0");
        ExecOrder memory newOrder =
            ExecOrder({
                user: _order.user,
                inToken: _order.inToken,
                outToken: _order.outToken,
                amountPerTrade: _order.amountPerTrade,
                nTradesLeft: _newNumTradesLeft, // the only updateable field for now
                minSlippage: _order.minSlippage,
                maxSlippage: _order.maxSlippage,
                delay: _order.delay,
                lastExecutionTime: _order.lastExecutionTime,
                platformWallet: _order.platformWallet,
                platformFeeBps: _order.platformFeeBps
            });
        _updateTask(abi.encode(_order), abi.encode(newOrder), _id, msg.sender);
        if (_order.inToken == ETH) {
            if (_order.nTradesLeft > _newNumTradesLeft) {
                uint256 refundAmount =
                    _order.amountPerTrade *
                        (_order.nTradesLeft - _newNumTradesLeft);
                (bool success, ) = _order.user.call{value: refundAmount}("");
                require(success, "GelatoDCA.editNumTrades: revert on transfer");
            } else {
                uint256 topUpAmount =
                    _order.amountPerTrade *
                        (_newNumTradesLeft - _order.nTradesLeft);

                require(
                    topUpAmount == msg.value,
                    "GelatoDCA.editNumTrades: mismatching amount of ETH deposited"
                );
            }
        }

        emit LogTaskUpdated(_id, newOrder);
    }

    function claimPlatformFees(
        address[] calldata _platformWallets,
        address[] calldata _tokens
    ) external nonReentrant {
        for (uint256 i = 0; i < _platformWallets.length; i++) {
            for (uint256 j = 0; j < _tokens.length; j++) {
                uint256 fee =
                    platformWalletFees[_platformWallets[i]][_tokens[j]];
                if (fee > 1) {
                    platformWalletFees[_platformWallets[i]][_tokens[j]] = 1;
                    _transferEthOrToken(
                        payable(_platformWallets[i]),
                        _tokens[j],
                        fee - 1
                    );
                }
            }
        }
        emit ClaimedPlatformFees(_platformWallets, _tokens, msg.sender);
    }

    // solhint-disable-next-line function-max-lines
    function exec(
        ExecOrder calldata _order,
        uint256 _id,
        Dex _protocol,
        Fee memory _fee,
        address[] calldata _tradePath
    )
        external
        gelatofy(
            _fee.isOutToken ? _order.outToken : _order.inToken,
            _order.user,
            abi.encode(_order),
            _id,
            _fee.amount,
            _fee.swapRate
        )
    {
        // task cycle logic
        if (_order.nTradesLeft > 1) {
            _updateAndSubmitNextTask(_order, _id);
        } else {
            _removeTask(abi.encode(_order), _id, _order.user);
        }

        // action exec
        uint256 outAmount;
        if (_protocol == Dex.KYBER) {
            outAmount = _actionKyber(_order, _fee.amount, _fee.isOutToken);
        } else {
            outAmount = _actionUniOrSushi(
                _order,
                _protocol,
                _tradePath,
                _fee.amount,
                _fee.isOutToken
            );
        }

        if (_fee.isOutToken) {
            _transferEthOrToken(
                payable(_order.user),
                _order.outToken,
                outAmount
            );
        }

        emit LogDCATrade(_id, _order, outAmount);
    }

    function isTaskSubmitted(ExecOrder calldata _order, uint256 _id)
        external
        view
        returns (bool)
    {
        return verifyTask(abi.encode(_order), _id, _order.user);
    }

    function getMinReturn(ExecOrder memory _order)
        public
        view
        returns (uint256 minReturn)
    {
        // 4. Rate Check
        (uint256 idealReturn, ) =
            IOracleAggregator(IGelato(gelato).getOracleAggregator())
                .getExpectedReturnAmount(
                _order.amountPerTrade,
                _order.inToken,
                _order.outToken
            );

        require(
            idealReturn > 0,
            "GelatoKrystal.getMinReturn: idealReturn cannot be 0"
        );

        // check time (reverts if block.timestamp is below execTime)
        uint256 timeSinceCanExec =
            // solhint-disable-next-line not-rely-on-time
            block.timestamp - (_order.lastExecutionTime + _order.delay);

        uint256 minSlippageFactor = BPS - _order.minSlippage;
        uint256 maxSlippageFactor = BPS - _order.maxSlippage;
        uint256 slippage;
        if (minSlippageFactor > timeSinceCanExec) {
            slippage = minSlippageFactor - timeSinceCanExec;
        }

        if (maxSlippageFactor > slippage) {
            slippage = maxSlippageFactor;
        }

        minReturn = (idealReturn * slippage) / BPS;
    }

    function isSwapPossible(address _inToken, address _outToken)
        external
        view
        returns (bool isPossible)
    {
        (uint256 idealReturn, ) =
            IOracleAggregator(IGelato(gelato).getOracleAggregator())
                .getExpectedReturnAmount(1e18, _inToken, _outToken);
        isPossible = idealReturn == 0 ? false : true;
    }

    // ############# PRIVATE #############
    function _actionKyber(
        ExecOrder memory _order,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (uint256 inAmount, uint256 minReturn, address payable receiver) =
            _preExec(_order, _fee, _outTokenFee, Dex.KYBER);

        received = _doKyberTrade(
            _order.inToken,
            _order.outToken,
            inAmount,
            _getKyberRate(inAmount, minReturn, _order.inToken, _order.outToken),
            receiver,
            payable(_order.platformWallet),
            _order.platformFeeBps
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    function _doKyberTrade(
        address _inToken,
        address _outToken,
        uint256 _inAmount,
        uint256 _minRate,
        address payable _receiver,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) private returns (uint256 received) {
        uint256 ethToSend = _inToken == ETH ? _inAmount : uint256(0);

        received = kyberProxy.tradeWithHintAndFee{value: ethToSend}(
            IERC20(_inToken),
            _inAmount,
            IERC20(_outToken),
            _receiver,
            _MAX_AMOUNT,
            _minRate,
            _platformWallet,
            _platformFeeBps,
            HINT
        );
    }

    function _actionUniOrSushi(
        ExecOrder memory _order,
        Dex _protocol,
        address[] memory _tradePath,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (uint256 inAmount, uint256 minReturn, address payable receiver) =
            _preExec(_order, _fee, _outTokenFee, _protocol);

        require(
            _order.inToken == _tradePath[0] &&
                _order.outToken == _tradePath[_tradePath.length - 1],
            "GelatoDCA.action: trade path does not match order."
        );

        received = _doUniswapTrade(
            _protocol == Dex.UNISWAP ? uniRouterV2 : sushiRouterV2,
            _tradePath,
            inAmount,
            minReturn,
            receiver,
            payable(_order.platformWallet),
            _order.platformFeeBps
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    // @dev fee will always be paid be srcToken
    // solhint-disable-next-line function-max-lines
    function _doUniswapTrade(
        IUniswapV2Router02 _router,
        address[] memory _tradePath,
        uint256 _inAmount,
        uint256 _minReturn,
        address payable _receiver,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) private returns (uint256 received) {
        uint256 feeAmount = (_inAmount * _platformFeeBps) / BPS;
        uint256 actualSellAmount = _inAmount - feeAmount;
        address actualInToken;
        address actualOutToken;
        {
            uint256 tradeLen = _tradePath.length;
            actualInToken = _tradePath[0];
            actualOutToken = _tradePath[tradeLen - 1];
            if (_tradePath[0] == address(ETH)) {
                _tradePath[0] = _router.WETH();
            }
            if (_tradePath[tradeLen - 1] == address(ETH)) {
                _tradePath[tradeLen - 1] = _router.WETH();
            }

            // add platform fee to platform wallet account
            _addFeeToPlatform(_platformWallet, actualInToken, feeAmount);
        }

        uint256[] memory amounts;
        if (actualInToken == ETH) {
            amounts = _router.swapExactETHForTokens{value: actualSellAmount}(
                _minReturn,
                _tradePath,
                _receiver,
                _MAX_AMOUNT
            );
        } else {
            if (actualOutToken == address(ETH)) {
                amounts = _router.swapExactTokensForETH(
                    actualSellAmount,
                    _minReturn,
                    _tradePath,
                    _receiver,
                    _MAX_AMOUNT
                );
            } else {
                amounts = _router.swapExactTokensForTokens(
                    actualSellAmount,
                    _minReturn,
                    _tradePath,
                    _receiver,
                    _MAX_AMOUNT
                );
            }
        }

        return amounts[amounts.length - 1];
    }

    // solhint-disable function-max-lines
    function _preExec(
        ExecOrder memory _order,
        uint256 _fee,
        bool _outTokenFee,
        Dex _protocol
    )
        private
        returns (
            uint256 inAmount,
            uint256 minReturn,
            address payable receiver
        )
    {
        if (_outTokenFee) {
            receiver = payable(this);
            minReturn = getMinReturn(_order) + _fee;
            inAmount = _order.amountPerTrade;
        } else {
            receiver = payable(_order.user);
            minReturn = getMinReturn(_order);
            inAmount = _order.amountPerTrade - _fee;
        }

        if (_order.inToken != ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                _order.user,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeIncreaseAllowance(
                getProtocolAddress(_protocol),
                inAmount
            );
        }
    }

    function _updateAndSubmitNextTask(ExecOrder memory _order, uint256 _id)
        private
    {
        bytes memory lastOrder = abi.encode(_order);
        // update next order
        _order.nTradesLeft = _order.nTradesLeft - 1;
        // solhint-disable-next-line not-rely-on-time
        _order.lastExecutionTime = block.timestamp;

        _updateTask(lastOrder, abi.encode(_order), _id, _order.user);
        emit LogTaskSubmitted(_id, _order);
    }

    function _storeOrder(ExecOrder memory _order) private {
        uint256 id = _storeTask(abi.encode(_order), _order.user);
        emit LogTaskSubmitted(id, _order);
    }

    function _getKyberRate(
        uint256 _amountIn,
        uint256 _minReturn,
        address _inToken,
        address _outToken
    ) private view returns (uint256) {
        uint256 newAmountIn =
            _to18Decimals(
                _inToken,
                _amountIn,
                "GelatoDCA:_getKyberRate: newAmountIn revert"
            );
        uint256 newMinReturn =
            _to18Decimals(
                _outToken,
                _minReturn,
                "GelatoDCA:_getKyberRate: newMinReturn revert"
            );
        return wdiv(newMinReturn, newAmountIn);
    }

    function _addFeeToPlatform(
        address _wallet,
        address _token,
        uint256 _amount
    ) private {
        if (_amount > 0) {
            platformWalletFees[_wallet][_token] =
                platformWalletFees[_wallet][_token] +
                _amount;
        }
    }

    function getProtocolAddress(Dex _dex) public view returns (address) {
        if (_dex == Dex.KYBER) return address(kyberProxy);
        if (_dex == Dex.UNISWAP) return address(uniRouterV2);
        if (_dex == Dex.SUSHISWAP) return address(sushiRouterV2);
        revert("GelatoDCA: getProtocolAddress: Dex not found");
    }

    function getExpectedReturnKyber(
        IERC20 _src,
        IERC20 _dest,
        uint256 _inAmount,
        uint256 _platformFee,
        bytes calldata _hint
    ) external view returns (uint256 outAmount, uint256 expectedRate) {
        try
            kyberProxy.getExpectedRateAfterFee(
                _src,
                _dest,
                _inAmount,
                _platformFee,
                _hint
            )
        returns (uint256 rate) {
            expectedRate = rate;
        } catch {
            expectedRate = 0;
        }
        outAmount = calcDestAmount(_src, _dest, _inAmount, expectedRate);
    }

    function getExpectedReturnUniswap(
        IUniswapV2Router02 _router,
        uint256 _inAmount,
        address[] calldata _tradePath,
        uint256 _platformFee
    ) external view returns (uint256 outAmount, uint256 expectedRate) {
        if (_platformFee >= BPS) return (0, 0);
        uint256 srcAmountAfterFee = (_inAmount * (BPS - _platformFee)) / BPS;
        if (srcAmountAfterFee == 0) return (0, 0);

        try _router.getAmountsOut(srcAmountAfterFee, _tradePath) returns (
            uint256[] memory amounts
        ) {
            outAmount = amounts[_tradePath.length - 1];
        } catch {
            outAmount = 0;
        }
        expectedRate = calcRateFromQty(
            srcAmountAfterFee,
            outAmount,
            getDecimals(IERC20(_tradePath[0])),
            getDecimals(IERC20(_tradePath[_tradePath.length - 1]))
        );
    }
}
