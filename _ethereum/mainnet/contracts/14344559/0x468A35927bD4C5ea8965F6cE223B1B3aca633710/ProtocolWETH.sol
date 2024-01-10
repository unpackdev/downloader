// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface WethInterface {
    function approve(address, uint256) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}

abstract contract ProtocolWETH {

    address public immutable wethAddr;

    constructor(address _wethAddr) {
        wethAddr = _wethAddr;
    }

    function convertEthToWeth(
        bool isEth,
        WethInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(
        bool isEth,
        WethInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }

    function approve(
        WethInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }
}
