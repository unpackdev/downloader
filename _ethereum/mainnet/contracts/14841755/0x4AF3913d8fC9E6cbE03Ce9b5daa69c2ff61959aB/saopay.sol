// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./OwnableUpgradeable.sol";

abstract contract Saopay is OwnableUpgradeable {
    
    /**
     * @dev ETH is deposited.
    */
    function deposit() payable public onlyOwner {
    }

    /**
     * @dev ETH can be withdraw by owner of contract.
    */
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev read function to view balance of contract.
    */
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}