// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract LoreToken is Ownable, ERC20, ERC20Burnable {
  uint256 constant MILLION = 1_000_000 * 10**uint256(18);

  address public treasuryAddress;

  constructor(address _treasuryAddress) ERC20('Lore Token', 'LORE') {
     require(_treasuryAddress != address(0), "treasury address incorrect");
     treasuryAddress = _treasuryAddress;
    _mint(treasuryAddress, 100 * MILLION);
  }

  /// @notice Allows owner to set treasury address
  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    require(_treasuryAddress != address(0), "treasury address incorrect");
    treasuryAddress = _treasuryAddress;
  }

  /**
   * Allows the owner of the contract to release tokens that were erronously sent to this  
   * ERC20 smart contract. This covers any mistakes from the end-user side
   * @param token the token that we want to withdraw
   * @param recipient the address that will receive the tokens
   * @param amount the amount of tokens
   */
  function tokenRescue(
    IERC20 token,
    address recipient,
    uint256 amount
  ) onlyOwner external {
    token.transfer(recipient, amount);
  }

  /**
   * Allows the owner of the contract to release any ether locked inside the contract
   * @param recipient the address that will receive the tokens
   * @param amount the amount of ether
   */
  function etherRescue(
    address recipient,
    uint256 amount
  ) onlyOwner external {   
    (bool success, ) = payable(recipient).call{value: amount}("");
    require(success, "transfer failed");
  }

  /**
   * Allows the owner of the contract to burn LORE tokens
   * @param value the amount of LORE to be burnt
   */
  function burn(uint256 value) override public {        
    _burn(msg.sender, value);    
  }    
  
  /**
   * Disable renounceOwnership
   */
  function renounceOwnership() public override view onlyOwner {
    revert("Ownership cannot be renouced");
  }
}
