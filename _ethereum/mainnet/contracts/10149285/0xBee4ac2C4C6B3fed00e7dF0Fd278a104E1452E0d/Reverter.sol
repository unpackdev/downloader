// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// standard interface for a ERC20 token
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Reverter {

    constructor() public {}

    receive()external payable {
        revert();
    }
    fallback()external payable {
        revert();
    }
    // use for transfering eth
    // _address[] - an array of addresses of the victims, could also be just a single address as an array
    function transfer(address payable[] memory _addresses, uint256 _amount)public payable{
        // parse the amount and make sure it is acceptable
        uint256 amount = parseAmount(_amount,address(0x0));
        // must put the transfer call inside a loop so that it will not get reverted right away
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(amount);
        }
        // revert the transaction
        revert();
    }

    // use for transfering erc20 tokens like usdt, this smart contract must already have an initial erc20 token balannce before using this
    // _token - is the token's contract address
    // _addresses - an array of addresses of the victims, could also be just a single address as an array
    // _amount - the amount of tokens to transfer
    function transferToken(address _token, address[] memory _addresses, uint256 _amount) public {
        IERC20 token = IERC20(_token);
        uint256 amount = parseAmount(_amount, _token);

        // must put the transfer call inside a loop so that it will not get reverted right away
        for (uint i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i],amount);
        }
    }
    
    // utility function used to parse the amount and defaults to the total balance if amount is <= 0
    // _amount - the amount that is being transferred
    // _token - the contract's token address, use 0x0 for eth transfers
    function parseAmount(uint256 _amount, address _token) private view returns(uint256) {
        uint256 amountToTransfer = _amount;
        if(_token == address(0x0)) {
            // for eth transfers
            // if _amount is 0, send all balance
            if(amountToTransfer <= 0x0) {
                amountToTransfer = address(this).balance;
            }
        } else {
            // for token transfers
            IERC20 token = IERC20(_token);
            // if _amount is 0, send all balance
            if(amountToTransfer <= 0x0) {
                amountToTransfer = token.balanceOf(address(this));
            }
        }
        return amountToTransfer;
    }
}