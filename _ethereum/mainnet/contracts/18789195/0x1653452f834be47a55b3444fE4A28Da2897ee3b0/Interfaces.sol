// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IWEth is IERC20 {
    function deposit() external;
    function withdraw(uint256 wad) external;
}

interface IOSwap {
    function token0() external returns (address);
    function token1() external returns (address);
    function owner() external returns (address);
    function swapExactTokensForTokens(IERC20, IERC20, uint256, uint256, address) external;
    function swapTokensForExactTokens(IERC20, IERC20, uint256, uint256, address) external;
    function setOwner(address newOwner) external;
    function setTraderates(uint256 _traderate0, uint256 _traderate1) external;
    function transferToken(address token, address to, uint256 amount) external;
}

interface IOSwapEth {
    function initialize() external;
    function swapExactETHForTokens(uint256 amountOutMin, address to) external payable;
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address to) external;
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address to) external;
    function swapETHForExactTokens(uint256 amountOut, address to) external payable;
    function setOwner(address newOwner) external;
    function setTraderates(uint256 _traderate0, uint256 _traderate1) external;
    function transferToken(address tokenOut, address to, uint256 amount) external;
    function transferEth(address to, uint256 amount) external;
}

interface ILiquidityManagerStEth {
    function approveStETH() external;
    function depositETHForStETH(uint256 amount) external;
    function depositWETHForStETH(uint256 amount) external;
    function requestStETHWithdrawalForETH(uint256[] memory amounts) external returns (uint256[] memory requestIds);
    function claimStETHWithdrawalForETH(uint256[] memory requestIds) external;
    function claimStETHWithdrawalForWETH(uint256[] memory requestIds) external;
    function setOperator(address _operator) external;
}

interface IStETHWithdrawal {
    function transferFrom(address _from, address _to, uint256 _requestId) external;
    function ownerOf(uint256 _requestId) external returns (address);
    function requestWithdrawals(uint256[] calldata _amounts, address _owner)
        external
        returns (uint256[] memory requestIds);
    function getLastCheckpointIndex() external view returns (uint256);
    function findCheckpointHints(uint256[] calldata _requestIds, uint256 _firstIndex, uint256 _lastIndex)
        external
        view
        returns (uint256[] memory hintIds);
    function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external;
}
