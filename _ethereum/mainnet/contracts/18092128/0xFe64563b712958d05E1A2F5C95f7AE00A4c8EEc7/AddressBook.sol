// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

library AddressBook {
    address internal constant MILADY = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5;
    address internal constant REMILIO = 0xD3D9ddd0CF0A5F0BFB8f7fcEAe075DF687eAEBaB;
    address internal constant PIXELADY = 0x8Fc0D90f2C45a5e7f94904075c952e0943CFCCfd;

    function isMilady(address addr) public view returns (bool) {
        return IERC20(MILADY).balanceOf(addr) > 0 || IERC20(REMILIO).balanceOf(addr) > 0
            || IERC20(PIXELADY).balanceOf(addr) > 0;
    }
}
