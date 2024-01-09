// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Counters.sol";
import "./Clothees.sol";

contract MagentaClotheeMinter {
    using Counters for Counters.Counter;

    Counters.Counter private _MagentaCounter;

    uint public constant MAX_MAGENTA = 223;
    uint public constant MAGENTA_SALE_PRICE = .07 ether;

    address public nft;
    address payable treasury;

    constructor (address payable _treasury, address _nft) payable {
        treasury = _treasury;
        nft = _nft;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier nftPrice(uint _amount) {
        if (msg.value < _amount)
            revert("Not enough Ether sent with function call.");
        _;
    }

    function MagentaSale()
        public
        payable
        nftPrice(MAGENTA_SALE_PRICE)
    {
        _MagentaCounter.increment();
        require( _MagentaCounter.current() <= MAX_MAGENTA, "Sold Out");
        treasury.transfer(msg.value);
        Clothees(address(nft)).safeMint(msg.sender);
    }   
}