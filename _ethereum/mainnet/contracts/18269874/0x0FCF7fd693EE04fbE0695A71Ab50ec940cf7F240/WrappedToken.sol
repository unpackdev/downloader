//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract WrappedToken is ERC20, AccessControl {
    
    uint8 _decimals;
    bytes32 constant  public MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant  public BURNER_ROLE = keccak256("BURNER_ROLE");


    constructor(string memory _name, string memory _symbol, uint256 dec, address owner, address bridge) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, bridge);
        _setupRole(BURNER_ROLE, bridge);
        _decimals = uint8(dec);
    }

    function mint(address to, uint amount) external  {
        require(hasRole(MINTER_ROLE, msg.sender), "CALLER_IS_NOT_A_MINTER");
        _mint(to, amount);
    }

    function burn(uint256 amount) external  {
        require(hasRole(BURNER_ROLE, msg.sender), "CALLER_IS_NOT_A_BURNER");
        _burn(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}