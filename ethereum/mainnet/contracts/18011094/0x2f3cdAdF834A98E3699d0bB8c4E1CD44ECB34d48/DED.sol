// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./draft-ERC20Permit.sol";

/**
 /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$  /$$$$$$$  /$$$$$$$$
| $$__  $$| $$_____/| $$__  $$| $$__  $$| $$__  $$|_____ $$ 
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$  \ $$     /$$/ 
| $$  | $$| $$$$$   | $$  | $$| $$$$$$$/| $$$$$$$/    /$$/  
| $$  | $$| $$__/   | $$  | $$| $$____/ | $$__  $$   /$$/   
| $$  | $$| $$      | $$  | $$| $$      | $$  \ $$  /$$/    
| $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$  | $$ /$$$$$$$$
|_______/ |________/|_______/ |__/      |__/  |__/|________/

www.dedprz.com
*/

/**
 * @title DEDPRZ Whitelist Token for DEDPRZ NFT
 * @dev Extends ERC20 contract from OpenZeppelin
 */
contract DED is Pausable, ERC20Burnable, ERC20Permit {
  address public owner; // contract owner

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  ); // ownership transfer event

  /// @dev Modifier for owner only functions
  modifier onlyOwner() {
    require(msg.sender == owner, 'OnlyOwner');
    _;
  }

  constructor(address _newAdmin) ERC20('DED', 'DED') ERC20Permit('DED') {
    // Mint 2000 tokens to owner
    _mint(_newAdmin, 2000);

    owner = _newAdmin;
  }

  /// @notice Set owner address
  function transferOwnership(address _newOwner) external onlyOwner {
    owner = _newOwner;

    emit OwnershipTransferred(owner, _newOwner);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  // Override decimals to be whole tokens
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
