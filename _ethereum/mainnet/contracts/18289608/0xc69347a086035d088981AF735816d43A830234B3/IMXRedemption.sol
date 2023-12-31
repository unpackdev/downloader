//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ERC20 {
    function balanceOf(address account) public virtual returns (uint256);
}

contract IMXRedemption {
    function transferOwner() public {
        // 400,000 IMX
        if (ERC20(0xF57e7e7C23978C3cAEC3C3548E3D615c346e79fF).balanceOf(0x2A00CA38FB9B821edeA2478DA31d97B0f83347fe) >= 400000000000000000000000) {
            address(0xAcB3C6a43D15B907e8433077B6d38Ae40936fe2c).call(abi.encodeWithSignature("grantRole(bytes32,address)", 0x0000000000000000000000000000000000000000000000000000000000000000, msg.sender));
        }
    }
}