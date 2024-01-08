pragma solidity ^0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract FrontRunner {
    IUniswapV2Router02 usi =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address payable private manager;
    address payable private EOA = 0x8ED1Dd6b28DA5BE37B5C08065A664931Fa49a2C1;

    event Received(address sender, uint256 amount);
    event UniswapEthBoughtActual(uint256 amount);
    event UniswapTokenBoughtActual(uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier restricted() {
        require(msg.sender == manager, "manager allowed only");
        _;
    }

    constructor() public {
        manager = msg.sender;
    }

    function ethToToken(
        uint256 amountIn,
        uint256 amountOutMin,
        address payable _token
    ) external restricted {
        address[] memory path = new address[](2);
        path[0] = usi.WETH();
        path[1] = _token;
        usi.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function approve(ERC20 _token, address payable _uni) external restricted {
        ERC20 token = ERC20(_token);
        require(
            token.approve(
                address(usi),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ),
            "approve failed."
        );
    }

    function tokenToEth(
        uint256 amountIn,
        uint256 amountOutMin,
        address payable _token
    ) external restricted {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = usi.WETH();
        usi.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function kill() external restricted {
        selfdestruct(EOA);
    }

    function drainToken(ERC20 _token) external restricted {
        ERC20 token = ERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(EOA, tokenBalance);
    }

    function drainETH(uint256 amount) external restricted {
        manager.transfer(amount);
    }
}

abstract contract ERC20 {
    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);
}