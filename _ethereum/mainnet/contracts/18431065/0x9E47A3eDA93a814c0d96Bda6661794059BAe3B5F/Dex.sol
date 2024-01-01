// contracts/FlashLoan.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Dex {
    address payable public owner;

    // address private constant wethAddress =
    //     0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address private constant daiAddress =
    //     0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address private constant usdcAddress =
    //     0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // address private constant UNISWAP_ROUTER_ADDRESS =
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router public uniswapRouter;
    IUniswapV2Router public sushiswapRouter;

    IERC20 private dai;
    IERC20 private usdc;
    IERC20 private weth;

    constructor(
        address _uRouter,
        address _sRouter,
        address _dai,
        address _usdc,
        address _weth
    ) {
        owner = payable(msg.sender);

        uniswapRouter = IUniswapV2Router(_uRouter);
        sushiswapRouter = IUniswapV2Router(_sRouter);
        dai = IERC20(_dai);
        usdc = IERC20(_usdc);
        weth = IERC20(_weth);
    }

    function setFirstRouter(address _router) external {
        require(
            _router != address(0),
            "Router address must not be zero address"
        );
        uniswapRouter = IUniswapV2Router(_router);
    }

    function setSecondRouter(address _router) external {
        require(
            _router != address(0),
            "Router address must not be zero address"
        );
        sushiswapRouter = IUniswapV2Router(_router);
    }

    function setQuoteToken(address _token) external {
        require(_token != address(0), "Token must be balid");
        dai = IERC20(_token);
    }

    function setBaseToken(address _token) external {
        require(_token != address(0), "Token must be balid");
        usdc = IERC20(_token);
    }

    // Just buy DAI for USDC and resell it to pay back
    // replace this logic to whatever you want
    function simpleTrades(uint _amount) external {
        // get the loan from flashloan contract
        depositUSDC(msg.sender, _amount);
        // buy other token
        buyDAI(msg.sender);
        // get purchased token
        depositDAI(msg.sender, dai.balanceOf(msg.sender));
        // sell it to pay back loan
        sellDAI(msg.sender);
    }

    function depositUSDC(address _sender, uint256 _amount) public {
        uint256 allowance = usdc.allowance(_sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        usdc.transferFrom(_sender, address(this), _amount);
    }

    function depositDAI(address _sender, uint256 _amount) public {
        uint256 allowance = dai.allowance(_sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        dai.transferFrom(_sender, address(this), _amount);
    }

    function buyDAI(address _recipient) public {
        uint256 usdcBalances = usdc.balanceOf(address(this));

        usdc.approve(address(uniswapRouter), usdcBalances);

        address[] memory path;
        path = new address[](3);
        path[0] = address(usdc);
        path[1] = address(weth);
        path[2] = address(dai);

        uniswapRouter.swapExactTokensForTokens(
            usdcBalances,
            1,
            path,
            _recipient,
            block.timestamp
        );
    }

    function sellDAI(address _recipient) public {
        uint256 daiBalance = dai.balanceOf(address(this));

        dai.approve(address(uniswapRouter), daiBalance);

        address[] memory path;
        path = new address[](3);
        path[0] = address(dai);
        path[1] = address(weth);
        path[2] = address(usdc);

        uniswapRouter.swapExactTokensForTokens(
            daiBalance,
            1,
            path,
            _recipient,
            block.timestamp
        );
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}
}
