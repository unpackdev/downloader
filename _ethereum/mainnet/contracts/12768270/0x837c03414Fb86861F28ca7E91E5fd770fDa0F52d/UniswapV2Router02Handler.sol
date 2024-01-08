// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./IHandler.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./TokenUtils.sol";
import "./Tokens.sol";
import "./IWETH.sol";
import "./FUniswapV2.sol";

/// @notice UniswapV2 Handler used to execute an order via UniswapV2Router02
/// @dev This does NOT implement the standard IHANDLER
contract UniswapV2Router02Handler is IHandler {
    using TokenUtils for address;

    // solhint-disable var-name-mixedcase
    IUniswapV2Router02 public UNI_ROUTER;
    address public immutable WETH;

    // solhint-enable var-name-mixedcase

    constructor(IUniswapV2Router02 _uniRouter, address _weth) {
        UNI_ROUTER = _uniRouter;
        WETH = _weth;
    }

    /// @notice receive ETH from UniV2Router02 during swapXForEth
    receive() external payable override {
        require(
            msg.sender != tx.origin,
            "UniswapV2Router02Handler#receive: NO_SEND_ETH_PLEASE"
        );
    }

    /**
     * @notice Handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountOutMin - Address of the output token
     * @param _data - (module, relayer, fee, intermediatePath)
     * @return bought - Amount of output token bought
     */
    // solhint-disable-next-line function-max-lines
    function handle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external payable override returns (uint256 bought) {
        (
            address inToken,
            address outToken,
            uint256 amountIn,
            address[] memory path,
            address relayer,
            uint256 fee,
            address[] memory feePath
        ) = _handleInputData(_inToken, _outToken, _data);

        // Swap and charge fee in ETH
        if (inToken == WETH || inToken == ETH) {
            if (inToken == WETH) IWETH(WETH).withdraw(fee);
            bought = _swap(amountIn - fee, _amountOutMin, path, msg.sender);
        } else if (outToken == WETH || outToken == ETH) {
            bought = _swap(amountIn, _amountOutMin + fee, path, address(this));
            if (outToken == WETH) IWETH(WETH).withdraw(fee);
            outToken.transfer(msg.sender, bought - fee);
        } else {
            uint256 feeAmountIn =
                _swapTokensForExactETH(
                    UNI_ROUTER,
                    fee, // amountOut (in ETH)
                    amountIn, // amountInMax (in inputToken)
                    feePath,
                    address(this),
                    block.timestamp + 1 // solhint-disable-line not-rely-on-time
                );
            _swap(amountIn - feeAmountIn, _amountOutMin, path, msg.sender);
        }

        // Send fee to relayer
        (bool successRelayer, ) = relayer.call{value: fee}("");
        require(
            successRelayer,
            "UniswapV2Router02Handler#handle: TRANSFER_ETH_TO_RELAYER_FAILED"
        );
    }

    /**
     * @notice Check whether can handle an order execution
     * @param _inToken - Address of the input token
     * @param _outToken - Address of the output token
     * @param _amountIn - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - (module, relayer, fee, intermediatePath)
     * @return bool - Whether the execution can be handled or not
     */
    // solhint-disable-next-line code-complexity
    function canHandle(
        IERC20 _inToken,
        IERC20 _outToken,
        uint256 _amountIn,
        uint256 _minReturn,
        bytes calldata _data
    ) external view override returns (bool) {
        (
            address inToken,
            address outToken,
            ,
            address[] memory path,
            ,
            uint256 fee,
            address[] memory feePath
        ) = _handleInputData(_inToken, _outToken, _data);

        if (inToken == WETH || inToken == ETH) {
            if (_amountIn <= fee) return false;
            return _getAmountOut(_amountIn - fee, path) >= _minReturn;
        } else if (outToken == WETH || outToken == ETH) {
            uint256 bought = _getAmountOut(_amountIn, path);
            if (bought <= fee) return false;
            return bought - fee >= _minReturn;
        } else {
            uint256 inTokenFee = _getAmountIn(fee, feePath);
            if (inTokenFee >= _amountIn) return false;
            return _getAmountOut(_amountIn - inTokenFee, path) >= _minReturn;
        }
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recipient
    ) private returns (uint256 bought) {
        bought = _swapExactXForX(
            WETH,
            UNI_ROUTER,
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        );
    }

    function _getAmountOut(uint256 _amountIn, address[] memory _path)
        private
        view
        returns (uint256 amountOut)
    {
        uint256[] memory amountsOut =
            UNI_ROUTER.getAmountsOut(_amountIn, _path);
        amountOut = amountsOut[amountsOut.length - 1];
    }

    function _getAmountIn(uint256 _amountOut, address[] memory _path)
        private
        view
        returns (uint256 amountIn)
    {
        uint256[] memory amountsIn = UNI_ROUTER.getAmountsIn(_amountOut, _path);
        amountIn = amountsIn[0];
    }

    function _handleInputData(
        IERC20 _inToken,
        IERC20 _outToken,
        bytes calldata _data
    )
        private
        view
        returns (
            address inToken,
            address outToken,
            uint256 amountIn,
            address[] memory path,
            address relayer,
            uint256 fee,
            address[] memory feePath
        )
    {
        inToken = address(_inToken);
        outToken = address(_outToken);

        // Load real initial balance, don't trust provided value
        amountIn = inToken.balanceOf(address(this));

        // Decode extra data;
        (, relayer, fee, path, feePath) = abi.decode(
            _data,
            (address, address, uint256, address[], address[])
        );
    }
}
