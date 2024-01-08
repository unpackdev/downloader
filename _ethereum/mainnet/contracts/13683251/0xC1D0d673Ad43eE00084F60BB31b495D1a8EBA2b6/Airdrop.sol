// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GPO.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    GPO public gpo;

    constructor(address _gpo) {
        gpo = GPO(_gpo);
    }

    function doAirdrop(address[] memory _addresses, uint256[] memory _amounts) onlyOwner public {
        require(_addresses.length == _amounts.length);

        for(uint256 i = 0; i < _addresses.length; i++) {
            gpo.transfer(_addresses[i], _amounts[i]);
        }
    } 

    function doAirdropLocked(address[] memory _addresses, uint256[] memory _amounts) onlyOwner public {
        require(_addresses.length == _amounts.length);

        for(uint256 i = 0; i < _addresses.length; i++) {
            gpo.transfer(_addresses[i], _amounts[i]);
            gpo.lockUnlockWallet(_addresses[i], true, _amounts[i]);
        }
    }
}