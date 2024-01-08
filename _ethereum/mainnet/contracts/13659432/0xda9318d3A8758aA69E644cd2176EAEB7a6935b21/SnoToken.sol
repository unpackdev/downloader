// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SnoToken is ERC20, Ownable {

    address public auctionAddress;
    
    modifier onlyAuction() {
        require(msg.sender == auctionAddress, "Not Auction");
        _;
    }

    constructor() ERC20("Snow", "SNO") {
        auctionAddress = msg.sender;
    }

    function mint(address _to, uint256 _amount) public onlyAuction {
        _mint(_to, _amount);
    }

    function setAuctionAddress(address _auctionAddress) public onlyOwner {
        auctionAddress = _auctionAddress;
    }
}