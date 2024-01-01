// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Swap {
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public owner;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public MINT = 0x73DDE7E47FDe397ceC1B91d8863D4d61caf24810;

    constructor () {
      owner = msg.sender;
    }

    function swapExactInputSingleHop(
        uint amountIn,
        uint amountOutMinimum
    ) external returns (uint amountOut) {
        require(msg.sender == owner);
        IERC20(MINT).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: MINT,
                tokenOut: WETH,
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

    function withdraw(address token, uint amount) public {
      require(msg.sender == owner);
      IERC20(token).transfer(msg.sender, amount);
    }

}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}
