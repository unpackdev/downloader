pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC20.sol";


contract Dor is ERC20, AccessControl, Ownable{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address gnosis) public ERC20("Dor","DOR"){
        _setupRole(DEFAULT_ADMIN_ROLE, gnosis);
        _setupRole(MINTER_ROLE, gnosis);
    }

    function mint(address to, uint256 amount) public{
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function burn(uint256 amount) public{
        _burn(msg.sender, amount);
    }

}