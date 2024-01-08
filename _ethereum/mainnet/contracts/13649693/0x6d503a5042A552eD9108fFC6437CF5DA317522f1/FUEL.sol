// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dao: MEME
/// @author: Wizard

/*


                █████▒█    ██ ▓█████  ██▓    
              ▓██   ▒ ██  ▓██▒▓█   ▀ ▓██▒    
              ▒████ ░▓██  ▒██░▒███   ▒██░    
              ░▓█▒  ░▓▓█  ░██░▒▓█  ▄ ▒██░    
              ░▒█░   ▒▒█████▓ ░▒████▒░██████▒
              ▒ ░   ░▒▓▒ ▒ ▒ ░░ ▒░ ░░ ▒░▓  ░
              ░     ░░▒░ ░ ░  ░ ░  ░░ ░ ▒  ░
              ░ ░    ░░░ ░ ░    ░     ░ ░   
                        ░        ░  ░    ░  ░


*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./AccessControl.sol";

contract FUEL is ERC20, ERC20Burnable, ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant DENOMINATOR = 10000;

    uint256 public fuelAmount = 30000000000000000000000000;
    address public fuelTreasury;
    uint256 public fuelToTreasury = 5555000000000000000000000;

    constructor(address _treasury)
        ERC20("Rocket Fuel", "FUEL")
        ERC20Capped(355550000000 * (10**uint256(18)))
    {
        fuelTreasury = _treasury;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
        _;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "caller is not owner"
        );
        _;
    }

    function setFuelTreasury(address treasury) public virtual onlyOwner {
        fuelTreasury = treasury;
    }

    function setFuelAmount(uint256 amount) public virtual onlyOwner {
        fuelAmount = amount;
    }

    function mint(address account) public onlyMinter {
        _mint(account, fuelAmount);
        _mint(fuelTreasury, fuelToTreasury);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20, ERC20Capped)
    {
        require(ERC20.totalSupply() + amount <= cap(), "cap exceeded");
        super._mint(account, amount);
    }
}
