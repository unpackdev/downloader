// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./Ownable.sol";

contract Depositor is Ownable {
    /*
     * accepts ether sent with no txData
     */
    receive() external payable {}

    /*
     * refuses ether sent with txData that does not match any function signature in the  contract
     */
    fallback() external {}

    /**
     * @dev Get the contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Withdraw an amount of value to a specific address
     * @param to_ address that will receive the value
     * @param value to be sent to the address
     */
    function withdrawTo(address to_, uint256 value) public onlyOwner {
        require(getContractBalance() >= value, "too much");
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "Function call not successful");
    }
}
