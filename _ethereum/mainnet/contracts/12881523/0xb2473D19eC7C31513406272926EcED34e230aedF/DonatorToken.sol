// SPDX-License-Identifier: MIT

pragma solidity   >=0.6.0 <0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";

contract DonatorToken is Context, AccessControl, Ownable, ERC20, ERC20Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


    string public tokenName = "Donator";
    string public tokenSymbol = "DONO";
    uint8 public tokenDecimals = 7;
    uint256 public initialSupply = 250000000 * (10 ** uint256(tokenDecimals));
    constructor() public ERC20(tokenName, tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupDecimals(tokenDecimals);
        _mint(msg.sender, initialSupply);   
    }

   
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}