// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./AccessControl.sol";
import "./Math.sol";

contract PCOGToken is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl {

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    uint256 public maxSupply;

    constructor(address _ownerMultisigContract, address _tokensDistrbutionWallet) 
        ERC20("Precog Token", "PCOG") 
        
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _ownerMultisigContract);
        _grantRole(SNAPSHOT_ROLE, _msgSender());
        maxSupply = 98 * 10 ** 24;
        _mint( _tokensDistrbutionWallet, (maxSupply));
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot) 
    {     
        super._beforeTokenTransfer(from, to, amount);
    }
}