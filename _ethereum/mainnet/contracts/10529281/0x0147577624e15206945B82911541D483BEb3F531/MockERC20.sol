// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
import "./ERC20.sol";

contract MockERC20 {
    struct Transfer {
        address to;
        uint256 value;
    }
    struct TransferFrom {
        address from;
        address to;
        uint256 value;
    }
    Transfer lastTransfer;
    TransferFrom lastTransferFrom;

    function transfer(address to, uint256 value) public returns (bool success) {
        lastTransfer = Transfer(to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        lastTransferFrom = TransferFrom(from, to, value);
        return true;
    }

    function getLastTransfer()
        public
        view
        returns (
            address,
            uint256
        )
    {
        return (lastTransfer.to, lastTransfer.value);
    }

    function getLastTransferFrom()
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (lastTransferFrom.from, lastTransferFrom.to, lastTransferFrom.value);
    }
}
