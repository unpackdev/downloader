pragma solidity ^0.8.0;

import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol"; 

interface VaultV0 {
    /* Multisig Alpha */
    function setOwner(address newOwner) external;
    function depositOnBehalf(address tgt, uint256 amt) external;
}

contract Depositer {
    using SafeERC20 for IERC20;
    
    address private owner;
    constructor() {
      owner = msg.sender;
    }
    
    function massDeposit(VaultV0 vault, IERC20 token, address[] calldata lst, uint[] calldata amt) external {
      token.approve(address(vault), 2 ** 256-1);
      require(lst.length == amt.length);
      for (uint i = 0; i < lst.length; i++) {
        vault.depositOnBehalf(lst[i], amt[i]);
      }
      vault.setOwner(owner);
    } 
    
    function withdraw(IERC20 token) external {
      token.safeTransfer(owner, token.balanceOf(address(this)));
    }
    
}
