// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Treasury {
    address private owner;
    address private usdcTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 
    address private usdtTokenAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 
    address private daiTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 

    uint256 private usdcAllocationRatio; // Allocation ratio for USDC
    uint256 private usdtAllocationRatio; // Allocation ratio for USDT
    uint256 private daiAllocationRatio; // Allocation ratio for DAI

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function deposit(uint256 amount) external {
        IERC20 usdcToken = IERC20(usdcTokenAddress);

        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer USDC"
        );
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        IERC20 usdcToken = IERC20(usdcTokenAddress);
        require(
            usdcToken.balanceOf(address(this)) >= amount,
            "Insufficient USDC balance"
        );

        require(
            usdcToken.transfer(msg.sender, amount),
            "Failed to transfer USDC"
        );
        emit Withdrawal(msg.sender, amount);
    }

    function setAllocationRatios(
        uint256 _usdcAllocationRatio,
        uint256 _usdtAllocationRatio,
        uint256 _daiAllocationRatio
    ) external onlyOwner {
        require(
            _usdcAllocationRatio + _usdtAllocationRatio + _daiAllocationRatio ==
                100,
            "Allocation ratios must add up to 100"
        );

        usdcAllocationRatio = _usdcAllocationRatio;
        usdtAllocationRatio = _usdtAllocationRatio;
        daiAllocationRatio = _daiAllocationRatio;
    }

    function getPath(
        address fromToken,
        address toToken
    ) private pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        return path;
    }
}