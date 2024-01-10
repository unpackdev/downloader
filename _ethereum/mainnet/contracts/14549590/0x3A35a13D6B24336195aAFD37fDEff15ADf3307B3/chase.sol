// SPDX-License-Identifier: MIT

/// @title: $CHASE ERC20 Contract for Idol Idol
/// @author: PxGnome
/// @notice: For more information checkout idolidol.io
/// @dev: This is Version 1.0
//       ,a8a,                                           ,a8a,                                 
//      ,8" "8,         8I               ,dPYb,         ,8" "8,         8I               ,dPYb,
//      d8   8b         8I               IP'`Yb         d8   8b         8I               IP'`Yb
//      88   88         8I               I8  8I         88   88         8I               I8  8I
//      88   88         8I               I8  8'         88   88         8I               I8  8'
//      Y8   8P   ,gggg,8I    ,ggggg,    I8 dP          Y8   8P   ,gggg,8I    ,ggggg,    I8 dP 
//      `8, ,8'  dP"  "Y8I   dP"  "Y8ggg I8dP           `8, ,8'  dP"  "Y8I   dP"  "Y8ggg I8dP  
// 8888  "8,8"  i8'    ,8I  i8'    ,8I   I8P       8888  "8,8"  i8'    ,8I  i8'    ,8I   I8P   
// `8b,  ,d8b, ,d8,   ,d8b,,d8,   ,d8'  ,d8b,_     `8b,  ,d8b, ,d8,   ,d8b,,d8,   ,d8'  ,d8b,_ 
//   "Y88P" "Y8P"Y8888P"`Y8P"Y8888P"    8P'"Y88      "Y88P" "Y8P"Y8888P"`Y8P"Y8888P"    8P'"Y88
//
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

contract ChaseToken is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable, Ownable  {
    uint256 private immutable _SUPPLY_CAP;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        uint256 _cap
    ) ERC20("Idol Idol CHASE Token", "CHASE") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _SUPPLY_CAP = _cap;
    }

    /**
     * @notice Mint tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        require(totalSupply() + amount <= _SUPPLY_CAP, "Supply Cap exceeded");
        _mint(account, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @notice View supply cap
     */
    function SUPPLY_CAP() external view returns (uint256) {
        return _SUPPLY_CAP;
    }
}