//SPDX-License-Identifier: MIT

/*
          _____                    _____                    _____                            _____                    _____                   _______         
         /\    \                  /\    \                  /\    \                          /\    \                  /\    \                 /::\    \        
        /::\    \                /::\    \                /::\____\                        /::\    \                /::\    \               /::::\    \       
       /::::\    \              /::::\    \              /:::/    /                       /::::\    \              /::::\    \             /::::::\    \      
      /::::::\    \            /::::::\    \            /:::/   _/___                    /::::::\    \            /::::::\    \           /::::::::\    \     
     /:::/\:::\    \          /:::/\:::\    \          /:::/   /\    \                  /:::/\:::\    \          /:::/\:::\    \         /:::/~~\:::\    \    
    /:::/__\:::\    \        /:::/__\:::\    \        /:::/   /::\____\                /:::/  \:::\    \        /:::/__\:::\    \       /:::/    \:::\    \   
   /::::\   \:::\    \      /::::\   \:::\    \      /:::/   /:::/    /               /:::/    \:::\    \      /::::\   \:::\    \     /:::/    / \:::\    \  
  /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/   /:::/   _/___            /:::/    / \:::\    \    /::::::\   \:::\    \   /:::/____/   \:::\____\ 
 /:::/\:::\   \:::\____\  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \          /:::/    /   \:::\ ___\  /:::/\:::\   \:::\    \ |:::|    |     |:::|    |
/:::/  \:::\   \:::|    |/:::/  \:::\   \:::\____\|:::|   /:::/   /::\____\        /:::/____/     \:::|    |/:::/  \:::\   \:::\____\|:::|____|     |:::|    |
\::/   |::::\  /:::|____|\::/    \:::\  /:::/    /|:::|__/:::/   /:::/    /        \:::\    \     /:::|____|\::/    \:::\  /:::/    / \:::\    \   /:::/    / 
 \/____|:::::\/:::/    /  \/____/ \:::\/:::/    /  \:::\/:::/   /:::/    /          \:::\    \   /:::/    /  \/____/ \:::\/:::/    /   \:::\    \ /:::/    /  
       |:::::::::/    /            \::::::/    /    \::::::/   /:::/    /            \:::\    \ /:::/    /            \::::::/    /     \:::\    /:::/    /   
       |::|\::::/    /              \::::/    /      \::::/___/:::/    /              \:::\    /:::/    /              \::::/    /       \:::\__/:::/    /    
       |::| \::/____/               /:::/    /        \:::\__/:::/    /                \:::\  /:::/    /               /:::/    /         \::::::::/    /     
       |::|  ~|                    /:::/    /          \::::::::/    /                  \:::\/:::/    /               /:::/    /           \::::::/    /      
       |::|   |                   /:::/    /            \::::::/    /                    \::::::/    /               /:::/    /             \::::/    /       
       \::|   |                  /:::/    /              \::::/    /                      \::::/    /               /:::/    /               \::/____/        
        \:|   |                  \::/    /                \::/____/                        \::/____/                \::/    /                 ~~              
         \|___|                   \/____/                  ~~                               ~~                       \/____/                                  
*/                                                                                                                                                          

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Pausable.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract RawToken is ERC20, ERC20Snapshot, AccessControl, ERC20Pausable {
    bytes32 public constant ROLE_MINT = keccak256("ROLE_MINT");
    bytes32 public constant ROLE_PAUSE = keccak256("ROLE_PAUSE");
    bytes32 public constant ROLE_SNAP = keccak256("ROLE_SNAP");

    constructor(address admin) ERC20("RAW DAO", "RAW") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ROLE_PAUSE, admin);
        _setupRole(ROLE_MINT, admin);
    }

    function pause() public {
        require(hasRole(ROLE_PAUSE, msg.sender), "must have pauser role");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(ROLE_PAUSE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function snapshot() public {
        require(hasRole(ROLE_SNAP, msg.sender), "must have snapshoter role");
        _snapshot();
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(ROLE_MINT, msg.sender), "must have minter role");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}