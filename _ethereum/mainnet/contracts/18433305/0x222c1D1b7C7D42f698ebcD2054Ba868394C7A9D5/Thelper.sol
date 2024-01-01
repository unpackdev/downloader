//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface ISwapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut); // V3
}

//import "./TransferHelper.sol";
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }
}

contract Thelper {
    address public immutable _owner;
    ISwapRouterV3 public _swapRouter =
        ISwapRouterV3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniswapV3 SwapRouter
    address public _approveAddr =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor() {
        _owner = msg.sender;
    }

    function adminSetSwapRouter(address swapRouter, address approveAddr)
        external
    {
        require(msg.sender == _owner, "Only admin");
        _swapRouter = ISwapRouterV3(swapRouter);
        _approveAddr = address(approveAddr);
    }

    function trade(
        address tokenToSell,
        address tokenToBuy,
        uint24 uniswapV3PoolFee,
        uint256 amountSellOptional
    ) external {
        require(msg.sender == _owner, "Only admin");

        if (amountSellOptional == 0x0) {
            amountSellOptional = IERC20(tokenToSell).balanceOf(address(this));
        }

        TransferHelper.safeApprove(
            tokenToSell,
            _approveAddr,
            amountSellOptional
        );

        ISwapRouterV3.ExactInputSingleParams memory params = ISwapRouterV3
            .ExactInputSingleParams(
                tokenToSell, // tokenIn
                tokenToBuy, // tokenOut
                uniswapV3PoolFee, // fee
                address(this), // recipient
                block.timestamp + 1, // deadline now+1s
                amountSellOptional, // amountIn
                1, // amountOutMinimum
                0 // sqrtPriceLimitX96
            );
        _swapRouter.exactInputSingle(params);
        uint256 amountOut = IERC20(tokenToBuy).balanceOf(address(this));

        TransferHelper.safeTransfer(tokenToBuy, msg.sender, amountOut);
    }

    function claimTokens(address _token) external {
        if (_token == address(0x0)) {
            payable(_owner).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(_owner, balance);
    }
}