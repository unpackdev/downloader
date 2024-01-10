// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPublicMintable.sol";
import "./Ownable.sol";
import "./Address.sol";

contract UniverseMachinePublicSale is Ownable {
    using Address for address payable;

    IPublicMintable immutable parent;

    constructor(IPublicMintable _parent) {
        parent = _parent;
    }
    
    event RefundReceived(uint256 value);
    event RefundForwarded(address to, uint256 value);

    receive() external payable {
        emit RefundReceived(msg.value);
    }

    function publicMint(uint256 n) external payable {
        
        parent.mintPublic{value: msg.value}(msg.sender, n);

        // ethier Seller contract will refund here so we need to propagate it
        // and always have a zero balance at the end. This will only happen if
        // there's a race condition for the final token.
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).sendValue(balance);
            emit RefundForwarded(msg.sender, balance);
        }
        assert(address(this).balance == 0);
    }    
}