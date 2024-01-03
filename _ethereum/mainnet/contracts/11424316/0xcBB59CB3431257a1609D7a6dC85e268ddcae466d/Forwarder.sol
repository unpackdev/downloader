// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.1;


import "./IERC20.sol";

contract Forwarder {

    // Address to which any funds sent to this contract will be forwarded
    address public parentAddress;
    // to -> to which funds are forwarded
    event ForwarderDeposited(address from, address indexed to, uint value);

    event TokensFlushed(
        address tokenContractAddress, // The contract address of the token
        address to, // the contract - multisig - to which erc20 tokens were forwarded
        uint value // Amount of token sent
    );

    constructor (address multisigWallet) {
        parentAddress = multisigWallet;
    }


    function forwardERC20(address tokenAddress) public returns (bool){
        IERC20 token = IERC20(tokenAddress);
        uint value = token.balanceOf(address (this));
        if (value > 0 ) {
            if (token.transfer(parentAddress, value)) {
                emit TokensFlushed(tokenAddress, parentAddress, value);
                return true;
            }
        }
        return false;
    }


    function forward() payable public {

        (bool success, ) = parentAddress.call{value: address(this).balance}("");
        require(success, 'Deposit failed');
        emit ForwarderDeposited(msg.sender, parentAddress, msg.value);
    }

    receive () payable external {
        forward();
    }

}
