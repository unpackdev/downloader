// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

contract TransferToCoinbase {
    receive() external payable {}
    uint256[] public uselessArray;

    function transferToCoinbase() external {
        uselessArray.push(1);
        uselessArray.push(1);
        block.coinbase.transfer(address(this).balance);
    }
}
