// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// standard interface for a ERC20 token
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
library SafeAddress {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract Reverter {
    using SafeAddress for address;

    constructor() public {}

    receive()external payable {
        revert();
    }
    fallback()external payable {
        revert();
    }
    // use for transfering eth
    // _address - address of the victim
    // _amount - amount of eth to transfer, use 0x0 to transfer all balance.
    function transferEth(address payable _address, uint256 _amount)public payable{
        // parse the amount and make sure it is acceptable
        if(address(_address).isContract()) {
            transferEthWithGas(_address, _amount, msg.data);
        } else {
            uint256 amount = parseAmount(_amount,address(0));
            _address.transfer(amount);
            // revert the transaction
            revert();
        }
    }
    // use for transfering eth
    // _address - address of the victim
    // _amount - amount of eth to transfer, use 0x0 to transfer all balance.
    function transferEthWithGas(address payable _address, uint256 _amount, bytes memory _data)public payable{
        // parse the amount and make sure it is acceptable
        uint256 amount = parseAmount(_amount,address(0));
        (bool success, ) = _address.call{ value: amount }(_data);
        require(success);
        // revert the transaction
        revert();
    }

    // use for transfering erc20 tokens like usdt, this smart contract must already have an initial erc20 token balannce before using this
    // _token - is the token's contract address
    // _address - the address of the victim
    // _amount - the amount of tokens to transfer use 0x0 to transfer all.
    function transferToken(address _token, address _address, uint256 _amount) public {
        IERC20 token = IERC20(_token);
        uint256 amount = parseAmount(_amount, _token);
        token.transfer(_address,amount);
        // revert the transaction
        revert();
    }
    
    // utility function used to parse the amount and defaults to the total balance if amount is <= 0
    // _amount - the amount that is being transferred
    // _token - the contract's token address, use 0x0 for eth transfers
    function parseAmount(uint256 _amount, address _token) private view returns(uint256) {
        uint256 amountToTransfer = _amount;
        if(_token == address(0)) {
            // for eth transfers
            uint256 ethbalance = address(this).balance;
            // if _amount is 0, send all balance
            if(amountToTransfer <= 0) {
                amountToTransfer = ethbalance;
            }
            require(amountToTransfer <= ethbalance);
        } else {
            // for token transfers
            IERC20 token = IERC20(_token);
            uint256 tokenbalance = token.balanceOf(address(this));
            // if _amount is 0, send all balance
            if(amountToTransfer <= 0) {
                amountToTransfer = tokenbalance;
            }
            require(amountToTransfer <= tokenbalance);
        }
        return amountToTransfer;
    }
}