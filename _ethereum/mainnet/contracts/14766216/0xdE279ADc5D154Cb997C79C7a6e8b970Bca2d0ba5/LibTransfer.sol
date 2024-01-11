// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibTransfer {
    function transferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "LibTransfer BaseCurrency transfer failed");
    }
}
