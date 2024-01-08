pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20.sol";

contract HugToken is ERC20, AccessControl {

    bytes32 public constant BURNER_ROLE = keccak256(abi.encode("BURNER_ROLE"));

    /**
     * Constructor for HugToken
     * Mints total fixed supply 150M tokens
     * Uses AccessControl to allocate BURNER_ROLE accounts
     */
    constructor() ERC20("HugToken", "HUGU") {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _mint(_msgSender(), 150000000 * 10 ** decimals());
    }

    /**
     * Implement the burn method for owned tokens, requiring the BURNER_ROLE
     */
    function burn(uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

}