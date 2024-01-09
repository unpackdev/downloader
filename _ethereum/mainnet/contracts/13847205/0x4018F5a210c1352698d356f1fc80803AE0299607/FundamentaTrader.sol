// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Steve Medley
// https://github.com/Civitas-Fundamenta
// steve@fundamenta.network

import "./SafeERC20.sol";
import "./SecureContract.sol";
import "./DexInterface.sol";

struct Dex {
    uint256 id;
    address wrappedTokenAddress;
    address router;
    address factory;
    uint256 fee;
}

contract FundamentaTrader is SecureContract
{
    using SafeERC20 for IERC20;

    mapping(uint256 => Dex) private _dexs;

    event Initialized();

    constructor() {}

    function initialize() public initializer
    {
        SecureContract.init();
        emit Initialized();
    }

    function addDex(uint256 id, address wrappedTokenAddress, address router, address factory, uint256 fee) public isAdmin
    {
        _dexs[id] = Dex(id, wrappedTokenAddress, router, factory, fee);
    }

    function queryDex(uint256 id) public view returns (Dex memory) { return _dexs[id]; }

    function calculateFee(uint256 id, uint256 amount) public view returns (uint256) { return (amount / 10000) * _dexs[id].fee; }

    function swapExactTokensForETH(uint256 id, uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, amountIn);
        uint256 finalAmount = amountIn - fee;

        IERC20 token = IERC20(path[0]);

        approve(token, address(this), dex.router, amountIn);

        token.safeTransferFrom(msg.sender, address(this), amountIn);

        return DexInterface(dex.router).swapExactTokensForETH(finalAmount, amountOutMin, path, msg.sender, deadline);
    }

    function swapExactETHForTokens(uint256 id, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public payable pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, msg.value);

        return DexInterface(dex.router).swapExactETHForTokens{ value: msg.value - fee }(amountOutMin, path, msg.sender, deadline);
    }

    function swapExactTokensForTokens(uint256 id, uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, amountIn);

        IERC20 token = IERC20(path[0]);

        approve(token, address(this), dex.router, amountIn);

        token.safeTransferFrom(msg.sender, address(this), amountIn);

        return DexInterface(dex.router).swapExactTokensForTokens(amountIn - fee, amountOutMin, path, msg.sender, deadline);
    }

    function getAmountsOut(uint256 id, uint256 amountIn, address[] calldata path)
        public view pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, amountIn);
        uint256 finalAmount = amountIn - fee;

        return DexInterface(dex.router).getAmountsOut(finalAmount, path);
    }

    function approve(IERC20 token, address owner, address spender, uint256 amount) private
    {
        uint256 allowance = token.allowance(owner, spender);

        if (amount > allowance)
            token.approve(spender, type(uint256).max);
    }

    function withdrawEth(address to) public isAdmin
    {
        payable(to).transfer(address(this).balance);
    }

    function withdrawToken(address to, address token) public isAdmin
    {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }
}