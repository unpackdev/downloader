pragma solidity 0.5.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MPHToken is ERC20, ERC20Burnable, Ownable {
    string public constant name = "88mph.app";
    string public constant symbol = "MPH";
    uint8 public constant decimals = 18;
    
    bool public initialized;

    function init() public {
        require(!initialized, "MPHToken: initialized");
        initialized = true;

        _transferOwnership(msg.sender);
    }

    function ownerMint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }
}
