// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

contract FeeCollector {
    using SafeERC20 for IERC20;

    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address payable public constant DEV1 = payable(0xe74f008AB37F60f2F3f6be7aC6C64738Ea2301c1);
    address payable public constant DEV2 = payable(0x0dF8b3Fb69a2752bD5f92dAf44Da6C5B47a3CdC0);

    receive() external payable {}

    function collect() public {
        uint256 share = address(this).balance / 2;
        Address.sendValue(DEV1, share);
        Address.sendValue(DEV2, share);

        share = WETH.balanceOf(address(this)) / 2;
        WETH.safeTransfer(DEV1, share);
        WETH.safeTransfer(DEV2, share);

        share = USDC.balanceOf(address(this)) / 2;
        USDC.safeTransfer(DEV1, share);
        USDC.safeTransfer(DEV2, share);

        share = DAI.balanceOf(address(this)) / 2;
        DAI.safeTransfer(DEV1, share);
        DAI.safeTransfer(DEV2, share);
    }

    function collectToken(IERC20 token) public {
        uint256 share = token.balanceOf(address(this)) / 2;
        token.safeTransfer(DEV1, share);
        token.safeTransfer(DEV2, share);
    }
}
