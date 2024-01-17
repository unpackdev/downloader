//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Payable {
    /**
     * @dev enables easy access to check the contract balance
     **/
    function getContractBalance() public view returns (uint256) {
        //view amount of ETH the contract contains
        return address(this).balance;
    }

    /**
     * @dev facilitates receiving eth to the smart contract address
     **/
    function depositUsingParameter(uint256 deposit) external payable {
        //deposit ETH using a parameter
        require(msg.value == deposit);
    }
}
