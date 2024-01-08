// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IUniswapRouter.sol";

contract Incinerator {

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapRouter public router;
    address public management;
    mapping (address => uint) public tokensBurned;

    event TokensIncinerated(address tokenAddr, uint amount);
    event ManagementUpdated(address oldManagement, address newManagement);
    event RouterUpdated(address oldRouter, address newRouter);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address routerAddr, address mgmt) {
        router = IUniswapRouter(routerAddr);
        management = mgmt;
    }

    // change which exchange we send tokens to
    function setRouter(address newRouter) external managementOnly {
        address oldRouter = address(router);
        router = IUniswapRouter(newRouter);
        emit RouterUpdated(oldRouter, newRouter);
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    // buy tokens at market rate and burn them
    function incinerate(address tokenAddr) external payable {
        // set amountMin to 0 since we don't care how many tokens we burn
        uint amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = tokenAddr;

        address burnAddress = address(0);
        uint deadline = block.timestamp + 1;
        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, burnAddress, deadline);
        tokensBurned[tokenAddr] += amounts[1];
        emit TokensIncinerated(tokenAddr, amounts[1]);
    }

//    function incineratePath(address[] memory path, address inputToken) external payable {
//        // set amountMin to 0 since we don't care how many tokens we burn
//        uint amountOutMin = 0;
//
//        address burnAddress = address(0);
//        uint deadline = block.timestamp + 1;
//        uint[] memory amounts = router.swapTokensForExactTokens(amountOutMin, path, burnAddress, deadline);
//        uint lastAmount = amounts[amounts.length - 1];
//        address lastAddress = path[path.length - 1];
//        tokensBurned[lastAddress] += lastAmount;
//        emit TokensIncinerated(lastAddress, lastAmount);
//    }

}
