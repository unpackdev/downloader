// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV3Router {
    function exactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external payable returns (uint256 amountOut);
}

contract DividendDistributor {
    IERC20 public rewardsToken;
    IERC20 public parentToken;
    IUniswapV3Router public uniswapRouter;

    mapping(address => uint256) public dividendBalanceOf;
    mapping(address => uint256) public lastDividendAt;

    uint256 public totalDistributed;

    event DividendDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);


    uint24 public constant poolFee = 3000;

    address private constant wKasAddress = 0x112b08621E27e10773ec95d250604a041f36C582;
    address private constant wEthAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(address _parentToken, address _uniswapRouter) {
        parentToken = IERC20(_parentToken);
        rewardsToken = IERC20(wKasAddress);
        uniswapRouter = IUniswapV3Router(_uniswapRouter);
    }

    function distributeDividends() public payable {
        require(msg.value > 0, "No ETH sent for dividends");

        uint256 balanceBefore = rewardsToken.balanceOf(address(this));

        uniswapRouter.exactInputSingle{ value: msg.value }(
            wEthAddress,
            wKasAddress,
            poolFee,
            address(this),
            block.timestamp + 15 minutes,
            msg.value,
            0,
            0
        );

        uint256 amount = rewardsToken.balanceOf(address(this)) - balanceBefore;
        require(amount > 0, "No wKAS received");

        totalDistributed += amount;
        emit DividendDistributed(msg.sender, amount);
    }

    function withdrawDividend() public {
        uint256 owing = withdrawableDividend(msg.sender);
        require(owing > 0, "No dividends available for withdrawal");

        lastDividendAt[msg.sender] = totalDistributed;

        require(rewardsToken.transfer(msg.sender, owing), "Dividend transfer failed");
        emit DividendWithdrawn(msg.sender, owing);
    }

    function withdrawableDividend(address _owner) public view returns (uint256) {
        uint256 totalReceived = totalDistributed - lastDividendAt[_owner];
        uint256 balance = parentToken.balanceOf(_owner);
        uint256 totalSupply = parentToken.totalSupply();
        return (balance * totalReceived) / totalSupply;
    }
}