// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";

abstract contract ProxyWithdrawal is Ownable {
    
    event BalanceEvent(uint amount, address tokenAddress);
    event TransferEvent(address to, uint amount, address tokenAddress);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(address tokenAddress) public returns(uint) {
        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");

        uint amount = abi.decode(result, (uint));
        emit BalanceEvent(amount, tokenAddress);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) external onlyOwner {
        uint _balance = getBalance();
        require(_balance >= amount, "Balance not enough");
        to.transfer(amount);

        emit TransferEvent(to, amount, address(0));
    }

    /**
     * Transfer tokens
     */
    function transferToken(address to, uint amount, address tokenAddress) external onlyOwner {
        uint _balance = getTokenBalance(tokenAddress);
        require(_balance >= amount, "Not enough tokens");

        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        emit TransferEvent(to, amount, tokenAddress);
    }
}
