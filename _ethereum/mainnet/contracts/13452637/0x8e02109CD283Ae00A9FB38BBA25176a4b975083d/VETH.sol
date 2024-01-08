pragma solidity 0.8.9;

import "./ERC20PresetMinterPauser.sol";

contract VETH is ERC20PresetMinterPauser("Veridicas", "vETH") {
  constructor(address ownerAccount) {
    // Mint the total supply to the owner and multiply by 100 to include the 2 decimals
    mint(ownerAccount, 10000000 ether);

    // Revoke from the deployer's account all the roles that are setup by the ERC20PresetMinterPauser
    renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    renounceRole(MINTER_ROLE, _msgSender());
    renounceRole(PAUSER_ROLE, _msgSender());

    // Setup the roles correctly for the owner's account
    _setupRole(DEFAULT_ADMIN_ROLE, ownerAccount);
    _setupRole(MINTER_ROLE, ownerAccount);
    _setupRole(PAUSER_ROLE, ownerAccount);
  }
}
