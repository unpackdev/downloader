// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IUniswapV2Router02.sol";
import "./IV3SwapRouter.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVault.sol";
import "./Address.sol";
import "./IWETH.sol";
import "./Migratable.sol";
import "./OracleReader.sol";
import "./Utils.sol";
import "./Strings.sol";
import "./Distributor.sol";
import "./DexTracker.sol";
import "./BytesLib.sol";
import "./UniV3PathEncoding.sol";
import "./IPiteasRouter.sol";

/**
 * @title contract for swapping tokens
 * @notice use this contract for only the most basic simulation
 * @dev function calls are currently implemented without side effects
 * @notice multicall was not included here because sender
 * is less relevant outside of a swap
 * which already allows for multiple swaps
 */
contract InternetMoneySwapRouter is Utils, Migratable, OracleReader, Distributor, DexTracker {
    using Address for address payable;
    using SafeERC20 for IERC20;
    /** a single dex entry */

    error NativeMissing(uint256 pathIndex);
    error FeeMissing(uint256 expected, uint256 provided, string message);
    error ValueMismatch(uint256 consumed, uint256 provided);
    error FunderMismatch(address expected, address provided);
    error Deadline();

    event IMSwap(
        // keccak256 of inToken and outToken addresses
        bytes32 indexed inAndOutTokens,
        uint256 amountIn,
        address indexed sender,
        uint256 indexed dexId
    );

    event FeesCollected(
        uint256 indexed amount,
        bool indexed isNative
    );

    /**
     * sets up the wallet swap contract
     * @param _destination where native currency will be sent
     * @param _wNative the address that is used to wrap and unwrap tokens
     * @notice wNative does not have to have the name wNative
     * it is just a placeholder for wrapped native currency
     * @notice the destination address must have a receive / fallback method
     * to receive native currency
     */
    constructor(
        address payable _destination, address payable _wNative, uint96 _fee
    )
        Utils(_wNative, _destination, _fee)
    {}

    /**
     * this method transfers funds from the sending address
     * and returns the delta of the balance of this contracat
     * @param sourceTokenId is the token id to transfer from the sender
     * @param amountIn is the amount that you desire to transfer from the sender
     * @return delta the amount that was actually transferred, using a `balanceOf` check
     */
    function collectFunds(address sourceTokenId, uint256 amountIn) internal returns(uint256) {
        uint256 balanceBefore = IERC20(sourceTokenId).balanceOf(address(this));
        IERC20(sourceTokenId).safeTransferFrom(msg.sender, address(this), amountIn);
        return IERC20(sourceTokenId).balanceOf(address(this)) - balanceBefore;
    }

    function _wNativeFromDex(address payable _wNative) internal view returns(address payable) {
        return _wNative == address(0) ? wNative : _wNative;
    }

    function _handleBalancerV2FeeMath(uint256 dexId, uint256 amountIn, uint256 msgValue, address inToken, address outToken ) internal {
        address[] memory assetAddresses = new address[](2);
        assetAddresses[0] = inToken;
        assetAddresses[1] = outToken;
        (, uint256 minimum) = _getFeeMinimum(
            IUniswapV2Router02(dexInfo[dexId >> 128].router).factory(),
            amountIn,
            assetAddresses
        );
        _feeWithTolerance(msgValue, minimum);
        emit FeesCollected(msgValue, true);
    }

    /**
     * @notice This function is used to swap tokens on Balancer V2, with our fee being taken either before or after as ETH or WETH, depending on tokens swapped
     * @dev "uint256(deltas[deltas.length - 1] * -1))" is because
     * (1) fewer vars because stack too deep
     * (2) deltas are negative for tokens that exit balancer's vault, so we take the last one, our outToken, multiply by negative one, then cast to uint
     */
    function swapBalancerV2(
        uint256 dexId,
        IVault.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        IVault.FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline,
        uint256 inTokenIndex,  // Index of the input token in the assets array
        uint256 outTokenIndex,  // Index of the output token in the assets array
        uint256 amountIn  // Amount of input tokens
    ) external payable {
        if (dexInfo[dexId].disabled) {
            revert DexDisabled();
        }

        bool outIsNative = address(assets[outTokenIndex]) == address(0) || address(assets[outTokenIndex]) == _wNativeFromDex(dexInfo[dexId].wNative);
        uint256 remainingValue = msg.value;
        address payable recipient = funds.recipient;
        if (address(assets[inTokenIndex]) == address(0)) {
            // set limit for ETH (inToken is 0 address)
            limits[inTokenIndex] == int256(msg.value - (msg.value * feeNumerator / feeDenominator));
            remainingValue -= (msg.value * feeNumerator / feeDenominator);
            emit FeesCollected((msg.value * feeNumerator / feeDenominator), true);
        } else if (address(assets[inTokenIndex]) == _wNativeFromDex(dexInfo[dexId].wNative)) {
            // set limit for wNative (inToken is wNative)
            limits[inTokenIndex] == int256(amountIn - (amountIn * feeNumerator / feeDenominator));
            remainingValue = 0;
            emit FeesCollected((amountIn * feeNumerator / feeDenominator), false);
        } else if (!outIsNative) {
            _handleBalancerV2FeeMath(
                dexId,
                amountIn,
                msg.value,
                address(assets[inTokenIndex]),
                address(assets[outTokenIndex])
            );
        }

        if (address(this) != funds.sender) {
            revert FunderMismatch(address(this), funds.sender);
        }

        if (address(assets[inTokenIndex]) != address(0)) {
            // Dealing with an ERC20 contract
            // ik this is spaghetti code because of local var constraints but basically only deduct fee from erc20 amount if not weth
            amountIn = collectFunds(address(assets[inTokenIndex]), amountIn) - (
                address(assets[inTokenIndex]) == _wNativeFromDex(dexInfo[dexId].wNative)
                ? (amountIn * feeNumerator / feeDenominator)
                : 0
            );
            limits[inTokenIndex] = int256(amountIn);
            IERC20(address(assets[inTokenIndex])).approve(dexInfo[dexId].router, amountIn);
        }

        if (outIsNative) {
            funds.recipient = payable(address(this));
        }

        int256[] memory deltas = IVault(dexInfo[dexId].router)
        .batchSwap
        {value: remainingValue}
        (IVault.SwapKind.GIVEN_IN, swaps, assets, funds, limits, deadline);

        if (address(assets[outTokenIndex]) == _wNativeFromDex(dexInfo[dexId].wNative)) {
            IERC20(address(assets[outTokenIndex]))
                .safeTransfer(recipient, _removeFees(uint256(deltas[deltas.length - 1] * -1)));
            emit FeesCollected(
                uint256(deltas[deltas.length - 1] * -1) - _removeFees(uint256(deltas[deltas.length - 1] * -1)),
                false
            );
        } else if (address(assets[outTokenIndex]) == address(0)) {
            recipient.sendValue(_removeFees(uint256(deltas[deltas.length - 1] * -1)));
            emit FeesCollected(
                uint256(deltas[deltas.length - 1] * -1) - _removeFees(uint256(deltas[deltas.length - 1] * -1)),
                true
            );
        }

        emit IMSwap(
            keccak256(abi.encode(address(assets[inTokenIndex]), address(assets[outTokenIndex]))),
            amountIn,
            recipient,
            dexId
        );
    }

    function swapUniswapV3(
        uint256 dexId,
        IV3SwapRouter.ExactInputParams memory params
    ) external payable {
        Dex memory dex = dexInfo[dexId];
        if (dex.disabled) {
            revert DexDisabled();
        }
        uint256 msgValue = msg.value;
        address[] memory pathDecoded = UniV3PathEncoding._decodePath(params.path);
        address tokenIn = pathDecoded[0];
        address tokenOut = pathDecoded[pathDecoded.length - 1];
        address payable _wNative = _wNativeFromDex(dex.wNative);
        bool outIsNative = tokenOut == address(0) || tokenOut == _wNative;
        uint256 amountIn = params.amountIn;
        address recipient = params.recipient;
        uint256 requiredFee;

        // this event is at the beginning of the function because we change some of these values to account for native assets/fees/etc. to be consistent we want the event to be the raw amounts and values put in by the user. we can always cross reference with other events
        emit IMSwap(
            keccak256(abi.encode(tokenIn, tokenOut)),
            amountIn,
            recipient,
            dexId
        );

        if (tokenIn == address(0)) {
            uint256 nativeFee = (msgValue * feeNumerator) / feeDenominator;
            msgValue -= nativeFee;
            emit FeesCollected(
                nativeFee,
                true
            );
        } else if (tokenIn == _wNative) {
            requiredFee = (amountIn * feeNumerator) / feeDenominator;
            emit FeesCollected(
                requiredFee,
                false
            );
        } else if (!outIsNative) {
            (, uint256 minimum) = _getFeeMinimum(
                IUniswapV2Router02(dexInfo[dexId >> 128].router).factory(),
                amountIn,
                pathDecoded
            );
            _feeWithTolerance(msgValue, minimum);
            emit FeesCollected(
                msgValue,
                true
            );
        }
        if (tokenIn == address(0)) {
            tokenIn = _wNative;
            params.path = UniV3PathEncoding._replaceFirstAddress(params.path, _wNative);
            amountIn = msgValue;
            params.amountIn = amountIn;
            IWETH(_wNative).deposit{ value: amountIn }();
        } else {
            // dealing with erc20 contract
            amountIn = collectFunds(tokenIn, amountIn) - requiredFee;
            params.amountIn = amountIn;
        }
        // if native is coming out, make a pit stop to collect fees
        if (outIsNative) {
            params.recipient = address(this);
        }
        // if tokenOut is address(0) use the address that the factory understands
        if (tokenOut == address(0)) {
            params.path = UniV3PathEncoding._replaceLastAddress(params.path, wNative);
        }
        // does not handle native so we have to approve
        IERC20(tokenIn).approve(dex.router, amountIn);
        // do swap
        uint256 amountOut = IV3SwapRouter(dex.router)
            .exactInput(params);
        if (tokenOut == _wNative) {
            if (msgValue > 0) {
                revert FeeMissing(0, msgValue, "fees paid from output");
            }
            IERC20(tokenOut).safeTransfer(recipient, _removeFees(amountOut));
            emit FeesCollected(
                amountOut - _removeFees(amountOut),
                false
            );
        } else if (tokenOut == address(0)) {
            _sendNativeTokensOutAfterUnwrap(_wNative, _removeFees(amountOut), payable(recipient));
            emit FeesCollected(
                amountOut - _removeFees(amountOut),
                true
            );
        }

    }

    /**
     * @dev piteasCalldata should not include the first four bytes for the function selector, have the client truncate it: 8218b58f
     */
    function swapPiteas(uint256 dexId, bytes calldata piteasCalldata) external payable {
        Dex memory dex = dexInfo[dexId];
        if (dex.disabled) {
            revert DexDisabled();
        }

        (IPiteasRouter.Detail memory detail, bytes memory remainingCalldata) = abi.decode(
        piteasCalldata,
        (IPiteasRouter.Detail, bytes));

        uint256 msgValue = msg.value;
        address tokenIn = address(detail.srcToken);
        address tokenOut = address(detail.destToken);
        uint256 amountIn = detail.srcAmount;
        detail.destAccount = payable(address(this));
        bool outIsNative = tokenOut == address(0) || tokenOut == _wNativeFromDex(dex.wNative);


        if (tokenIn == address(0)) {
            uint256 nativeFee = (msgValue * feeNumerator) / feeDenominator;
            uint256 expectedAmount = amountIn + nativeFee;
            if (msgValue != expectedAmount) {
                revert FeeMissing(expectedAmount, msgValue, "swapPiteas():: insuff msg.value fee when native asset is inToken");
            }
            msgValue = amountIn;
            emit FeesCollected(
                nativeFee,
                true
            );

        } else if (tokenIn == _wNativeFromDex(dex.wNative)) {
            uint256 amountToCollect = (amountIn * feeDenominator) / (feeDenominator - feeNumerator);
            uint256 wNativeFee = amountToCollect - amountIn;
            uint256 amountCollected = collectFunds(tokenIn, amountToCollect);
            IERC20(_wNativeFromDex(dex.wNative)).approve(dex.router, amountIn);
            if (amountCollected < amountToCollect) {
                revert FeeMissing(amountToCollect, amountCollected, "swapPiteas():: insuff fee for wNative asset");
            }
            emit FeesCollected(
                wNativeFee,
                false
            );
        } else if (!outIsNative) {
            address[] memory assetAddresses = new address[](2);
            assetAddresses[0] = tokenIn;
            assetAddresses[1] = tokenOut;
            (, uint256 minimum) = _getFeeMinimum(
                IUniswapV2Router02(dexInfo[dexId >> 128].router).factory(),
                amountIn,
                assetAddresses
            );
            _feeWithTolerance(msgValue, minimum);
            emit FeesCollected(
                msgValue,
                true
            );
        } else {
            if (msgValue != 0) {
                revert ValueMismatch(0, msgValue);
            }
        }

        if (tokenIn != address(0) && tokenIn != _wNativeFromDex(dex.wNative)) {
            uint256 amountCollected = collectFunds(tokenIn, amountIn);
            if (amountCollected < amountIn) {
                revert ValueMismatch(amountIn, amountCollected);
            }
            IERC20(tokenIn).approve(dex.router, amountIn);
        }

        if (tokenIn != address(0)) {
            msgValue = 0;
        }

        uint256 amountBefore;
        if (tokenOut == address(0)) {
            amountBefore = address(this).balance;
        } else {
            amountBefore = IERC20(tokenOut).balanceOf(address(this));
        }

        uint256 amountOut = IPiteasRouter(dex.router).swap{value: msgValue}(detail, remainingCalldata);

        uint256 amountAfter;
        if (tokenOut == address(0)) {
            amountAfter = address(this).balance;
        } else {
            amountAfter = IERC20(tokenOut).balanceOf(address(this));
        }

        if (amountOut != amountAfter - amountBefore) {
            revert ValueMismatch(amountOut, amountAfter - amountBefore);
        }

        if (tokenOut == _wNativeFromDex(dex.wNative)) {
            IERC20(tokenOut).safeTransfer(msg.sender, _removeFees(amountOut));
            emit FeesCollected(
                amountOut - _removeFees(amountOut),
                false
            );
        } else if (tokenOut == address(0)) {
            _sendNativeTokensOutAfterUnwrap(_wNativeFromDex(dex.wNative), _removeFees(amountOut), payable(msg.sender));
            emit FeesCollected(
                amountOut - _removeFees(amountOut),
                true
            );
        } else {
            IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        }

        emit IMSwap(
            keccak256(abi.encode(tokenIn, tokenOut)),
            amountIn,
            msg.sender,
            dexId
        );

    }

    function _removeFees(uint256 amountOut) internal view returns(uint256) {
        return amountOut - (amountOut * feeNumerator) / feeDenominator;
    }
    function _sendNativeTokensOutAfterUnwrap(
        address payable _wNative,
        uint256 amountOut,
        address payable recipient
    ) internal {
        uint256 balance = IERC20(_wNative).balanceOf(address(this));
        if (balance > 0) {
            IWETH(_wNative).withdraw(balance);
        }
        recipient.sendValue(amountOut);
    }

    /**
     * @notice Swap erc20 token, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice anyone using this method will be costing themselves more
     * than simply going through the router they wish to swap through
     * so anything that comes through really acts like a high yeilding voluntary donation box
     * @notice if wNative is passed in as the first or last step of the path
     * then fees will be calculated from that number available at that time
     * @notice fee is only paid via msg.value if and only if the
     * first and last of the path are not a wrapped token
     * @notice if first or last of the path is wNative
     * then msg.value is required to be zero
     */
    function swapTokenV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        _swapTokenV2(msg.value, _dexId, recipient, _path, _amountIn, _minAmountOut, _deadline);
        emit IMSwap(
            keccak256(abi.encode(_path[0], _path[_path.length - 1])),
            _amountIn,
            recipient,
            _dexId
        );
    }

     function _feeWithTolerance(uint256 msgValue, uint256 _minimum) internal pure returns(uint256 minimum) {
        // introduce fee tolerance here
        minimum = (_minimum * 9) / 10;
        if (minimum == 0) {
            revert FeeMissing(0, msgValue, "unable to compute fees");
        }
        if (msgValue < minimum) {
            revert FeeMissing(minimum, msgValue, "not enough fee value");
        }
    }

    function _swapTokenV2(
        uint256 msgValue,
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) internal {
        address first = _path[0];
        address last = _path[_path.length - 1];
        address payable _wNative = _wNativeFromDex(dexInfo[_dexId].wNative);
        uint256 nativeFee = 0;
        if (first == _wNative) {
            nativeFee = (_amountIn * feeNumerator) / feeDenominator;
            if (msgValue != 0) {
                revert FeeMissing(0, msgValue, "fees paid from input");
            }
            emit FeesCollected(
                nativeFee,
                false
            );
        } else if (last != _wNative) {
            (, uint256 minimum) = _getFeeMinimum(
                IUniswapV2Router02(dexInfo[_dexId].router).factory(),
                _amountIn,
                _path
            );
            _feeWithTolerance(msgValue, minimum);
            emit FeesCollected(
                msgValue,
                true
            );
        }
        // run transfer as normal
        uint256 actualAmountIn = collectFunds(first, _amountIn) - nativeFee;
        uint256 actualAmountOut = swapExactTokenForTokenV2(
            _dexId,
            _path,
            actualAmountIn,
            _minAmountOut,
            _deadline
        );
        uint256 actualAmountOutAfterFees = actualAmountOut;
        if (last == _wNative) {
            actualAmountOutAfterFees -= (actualAmountOut * feeNumerator) / feeDenominator;
            if (msgValue != 0) {
                revert FeeMissing(0, msgValue, "fees paid from output");
            }
            emit FeesCollected(
                actualAmountOut - actualAmountOutAfterFees,
                false
            );
        }
        IERC20(last).safeTransfer(recipient, actualAmountOutAfterFees);
    }

    /**
     * wraps the provided msg value to be used as a token
     * useful when chaining calls together
     */
    function wrap(address payable _wNative) public payable {
        IWETH(_wNative).deposit{value: msg.value}();
        IWETH(_wNative).transfer(msg.sender, msg.value);
    }

    /**
     * @notice Swap native currency, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice this method does not require an approval step from the user
     * @notice because of use of msg.value if this method is used with internal
     * delegatecall to chain calls together, it will, in most cases, not have any msg.value to use
     */
    function swapNativeToV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        uint256 minimal = (msg.value * feeNumerator) / feeDenominator;
        address payable _wNative = _wNativeFromDex(dexInfo[_dexId].wNative);
        if (msg.value != _amountIn + minimal) {
            revert FeeMissing(_amountIn + minimal, msg.value, "amount + fees must = total");
        }
        if (_path[0] != _wNative) {
            revert NativeMissing(0);
        }
        emit FeesCollected(minimal, true);
        // convert native to wNative
        IWETH(_wNative).deposit{value: _amountIn}();
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, _amountIn, _minAmountOut, _deadline);
        IERC20(_path[_path.length - 1]).safeTransfer(recipient, actualAmountOut);
        emit IMSwap(
            keccak256(abi.encode(_path[0], _path[_path.length - 1])),
            _amountIn,
            recipient,
            _dexId
        );
    }

    /**
     * @notice Swap ERC-20 Token, end with native currency
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     */
    function swapToNativeV2(
        uint256 _dexId,
        address payable recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        address payable _wNative = _wNativeFromDex(dexInfo[_dexId].wNative);
        if (_path[_path.length - 1] != _wNative) {
            revert NativeMissing(_path.length - 1);
        }
        uint256 actualAmountIn = collectFunds(_path[0], _amountIn);
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, actualAmountIn, _minAmountOut, _deadline);
        uint256 actualAmountOutAfterFee = actualAmountOut - ((actualAmountOut * feeNumerator) / feeDenominator);
        emit FeesCollected(actualAmountOut - actualAmountOutAfterFee, false);
        _sendNativeTokensOutAfterUnwrap(_wNative, actualAmountOutAfterFee, recipient);
        emit IMSwap(
            keccak256(abi.encode(_path[0], _path[_path.length - 1])),
            _amountIn,
            recipient,
            _dexId
        );
    }

    function swapExactTokenForTokenV2(
        uint256 dexId,
        address[] calldata _path,
        uint256 _amountIn, // this value has been checked
        uint256 _minAmountOut, // this value will be met
        uint256 _deadline
    ) internal returns (uint256) {
        Dex memory dex = dexInfo[dexId];
        if (dex.disabled) {
            revert DexDisabled();
        }
        address last = _path[_path.length - 1];
        // approve router to swap tokens
        IERC20(_path[0]).approve(dex.router, _amountIn);
        // call to swap exact tokens
        uint256 balanceBefore = IERC20(last).balanceOf(address(this));
        IUniswapV2Router02(dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _minAmountOut,
            _path,
            address(this),
            _deadline
        );
        return IERC20(last).balanceOf(address(this)) - balanceBefore;
    }
}