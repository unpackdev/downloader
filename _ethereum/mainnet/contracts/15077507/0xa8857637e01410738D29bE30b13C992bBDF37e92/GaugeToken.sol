// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BlacklistToken.sol";



contract GaugeToken is BlacklistToken {

     constructor(string memory name_, string memory symbol_, address _blacklist)
    BlacklistToken( name_, symbol_, _blacklist){
        _mint(msg.sender, 500_000_000 ether);
    }

    function transferBatch(address[] memory accounts, uint256[] memory amounts) public {
        require(accounts.length == amounts.length, 'transferBatch: Arrays must be the same length');

        for(uint16 i = 0; i < accounts.length; i++){
            _transfer(msg.sender, accounts[i], amounts[i]);
        }
    }

}