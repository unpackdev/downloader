// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BurnOwner {

    address public tokenAddress = 0xfA3E941D1F6B7b10eD84A0C211bfA8aeE907965e;

    // burns owner address 
    function burnOwnerAddress() public {
        require(tokenAddress != address(0));
        (bool success,) = tokenAddress.call(abi.encodeWithSignature("acceptOwnership()"));
        require(success);
        tokenAddress = address(0);
    }
}