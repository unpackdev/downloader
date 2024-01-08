// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";


/**
* @title TokenRecover
* @dev Allow to recover any ERC20 sent into the contract for error
*/
contract TokenRecover is Ownable {

  /**
  * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
  * @param tokenAddress The token contract address
  * @param tokenAmount Number of tokens to be sent
  */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}


contract DTX  is ERC20Burnable, ERC20Pausable, TokenRecover, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // 0x4d494e5445525f524f4c45
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
  bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
  bytes32 public constant FROZEN_ROLE = keccak256("FROZEN_ROLE");

  constructor() ERC20("DT Ethereum Token", "DTX") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
    _setupRole(FREEZER_ROLE, _msgSender());
  }

  function mint(address to, uint256 value) public {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
    _mint(to, value);
  }

  function batchMint(address[] memory to, uint256[] memory value) public {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
    require(to.length == value.length, "Recipient and amount list sizes dont match.");
    for (uint i = 0; i < to.length; i++) {
      _mint(to[i], value[i]);
    }
  }

  function pause() public virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller must have pauser role");
    _pause();
  }

  function unpause() public virtual {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller must have pauser role");
    _unpause();
  }

  function renounceRole(bytes32 role, address account) public override {
    require(!hasRole(FROZEN_ROLE, _msgSender()),
    "ModifiedAccessControl: cannot revoke default admin role"
  );
  super.renounceRole(role, account);
}

function burnFrom(address account, uint256 amount) public virtual override(ERC20Burnable)
{
  require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");
  _burn(account, amount);
}
event Swap(address indexed account, uint256 value, uint16 chainId);

function swapBurn(uint256 amount, uint16 chainId) public virtual  {
  emit Swap(msg.sender, amount, chainId);
  _burn(_msgSender(), amount);
}

function swapMint(address[] memory to, uint256[] memory value) public {
  require(hasRole(SWAPPER_ROLE, msg.sender), "Caller is not a minter");
  require(to.length == value.length, "Recipient and amount list sizes dont match.");
  for (uint i = 0; i < to.length; i++) {
    _mint(to[i], value[i]);
  }
}

/**
* @dev See {ERC20-_beforeTokenTransfer}.
*/

function _beforeTokenTransfer(address from, address to, uint256 amount)
internal
virtual override(ERC20, ERC20Pausable)
{
  // require(!hasRole(FROZEN_ROLE, to), "Must be not be frozen to receive token");
  require(!hasRole(FROZEN_ROLE, from), "Must be not be frozen to send token");
  super._beforeTokenTransfer(from, to, amount);
}

}
