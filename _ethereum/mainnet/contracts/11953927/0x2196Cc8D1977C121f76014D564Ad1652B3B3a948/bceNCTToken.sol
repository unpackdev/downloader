// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./AccessControl.sol";


/**
 * @title bceNCT ERC20 token
 * @dev This is the base token to allow for name changing of the 
 * limited run: BlockChained Elite Collection
 *
 *  This Token Contract was inspired by the following open-source projects:
 *
 *  https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-/master/contracts/presets/ERC20PresetMinterPauser.sol
 *      
 */
contract bceNCTToken is ERC20, AccessControl{
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  event MinterAdded(address newMinter);

  constructor () ERC20("BlockChained Elite Name Change Token", "bceNCT") {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
  }

  /**
 * @dev Returns true if the given address has MINTER_ROLE.
 *
 * Requirements:
 *
 * - the caller must have the `MINTER_ROLE`.
 */
  function isMinter(address _address) public view returns(bool){
    return hasRole(MINTER_ROLE, _address);
  }

  function addMinter(address _address) public {
      require(hasRole(0x00, _msgSender()),"BCE: Role");
      grantRole(MINTER_ROLE, _address);
      emit MinterAdded(_address);
  } 
    
  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) public virtual returns(bool){
      require(hasRole(MINTER_ROLE, _msgSender()), "BCE: Not Minter");
      _mint(to, amount);
      return true;
  }

  function burn(uint256 amount) public {
      _burn(_msgSender(), amount);
  }

}
