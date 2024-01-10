pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./ERC20Burnable.sol";

contract EGGS is Context, AccessControlEnumerable, ERC20, ERC20Burnable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor () ERC20("Chicken DAO", "EGGS") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }
}
