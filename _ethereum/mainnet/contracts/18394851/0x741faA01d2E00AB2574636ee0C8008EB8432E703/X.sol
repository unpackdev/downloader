// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) 
        external 
        payable 
        returns (uint[] memory amounts);
}

contract X {
    IUniswapV2Router02 public uniswapRouter;
    address private owner;

    // State variables for the commit-reveal scheme
    bytes32 private commitHash;
    bool private revealPhase = false;

    constructor() {
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        owner = msg.sender;
    }

    function Kaulo(bytes32 _commitHash) external {
        require(msg.sender == owner, "GTFO");
        require(!revealPhase, "Revealing");

        commitHash = _commitHash;
        revealPhase = true;
    }

    function SakMaDak(uint amountOutMin, address[] calldata path, uint deadline, uint secret, address tokenAddress) external payable {
        require(msg.sender == owner, "GTFO");
        require(revealPhase, "Not revealing");
        require(keccak256(abi.encodePacked(amountOutMin, path, deadline, secret)) == commitHash, "Commit-reveal values do not match");

        // Do it
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        uniswapRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, msg.sender, deadline);
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Ait");

        // Go bak
        revealPhase = false;
    }
}