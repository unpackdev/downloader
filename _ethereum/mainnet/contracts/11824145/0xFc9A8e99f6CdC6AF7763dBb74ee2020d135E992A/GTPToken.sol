pragma solidity ^0.6.0;


import "./AccessControl.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";

contract GTPToken is Context, AccessControl, Ownable, ERC20, ERC20Pausable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


    string public tokenName = "GTP";
    string public tokenSymbol = "GTP";
    uint8 public tokenDecimals = 4;
    uint256 public initialSupply = 1000000000 * (10 ** uint256(tokenDecimals));
    constructor() public ERC20(tokenName, tokenSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupDecimals(tokenDecimals);
        _mint(msg.sender, initialSupply);   
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

   
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}