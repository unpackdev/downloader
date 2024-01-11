// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PausableToken.sol";
import "./ERC20Snapshot.sol";

contract SnapshotToken is PausableToken, ERC20Snapshot {

    constructor(string memory name_, string memory symbol_)
    PausableToken( name_, symbol_){
        
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

     function _beforeTokenTransfer(  address from,
        address to,
        uint256 amount
    )virtual internal override(ERC20Pausable, ERC20Snapshot)  {
        super._beforeTokenTransfer(from, to, amount);
    }


}


