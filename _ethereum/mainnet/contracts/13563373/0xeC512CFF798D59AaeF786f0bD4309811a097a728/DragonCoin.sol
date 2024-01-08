// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract DragonCoin is ERC20PresetMinterPauser {
    constructor(uint initialSupply) ERC20PresetMinterPauser("CryptoDragons Coin", "CDC") {
        _mint(msg.sender, initialSupply);
    }

    function approveAndCall(address spender, uint256 value, bytes calldata extraData) external returns (bool success) {
        _approve(_msgSender(), spender, value);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                value, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert(); 
        }
        return true;
    }
}