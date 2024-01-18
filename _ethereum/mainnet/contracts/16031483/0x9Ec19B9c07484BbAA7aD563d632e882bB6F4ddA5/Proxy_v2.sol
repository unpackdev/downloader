// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ProxyWithdrawal.sol";

contract DeBridgesProxy is Ownable, ProxyWithdrawal {

    event SendDepositEvent(string hash, address from, address to, address tokenAddress, uint amount, bytes data);

    /**
     * Add coins
     */
    function addCoins() public payable {}

    /**
     * Send deposit
     */
    function sendDeposit(string memory hash, address from, address tokenAddress, uint amount, bytes calldata data, address to) public onlyOwner {
        if (tokenAddress == address(0)) {
            sendCoins(to, amount, data);
        } else {
            sendTokens(tokenAddress, to, amount, data);
        }

        emit SendDepositEvent(hash, from, to, tokenAddress, amount, data);
    }

    /**
     * Send coins
     */
    function sendCoins(address to, uint amount, bytes memory data) internal onlyOwner {
        require(getBalance() >= amount, "Balance not enough");
        (bool success, ) = to.call{value: amount}(data);
        require(success, "Transfer not sended");
    }

    /**
     * Send tokens
     */
    function sendTokens(address contractAddress, address to, uint amount, bytes memory data) internal onlyOwner {
        require(getTokenBalance(contractAddress) >= amount, "Not enough tokens");

        (bool success, ) = contractAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = contractAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        (success, ) = to.call(data);
        require(success, "transfer data request failed");
    }
}
