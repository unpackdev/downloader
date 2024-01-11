pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: MIT

import "./ERC777.sol";
import "./Ownable.sol";
import "./recovery.sol";

contract GoldToken is ERC777, Ownable, recovery {

    string constant _name   = "Peculi Gold";
    string constant _symbol = "PECS";
    address[]       nilOps;

    mapping(address => bool)    public authorisedMinters;
    mapping(address => bool)    public admins;

    event AuthChanged(address user,bool auth);
    event AdminChanged(address user,bool auth);


    modifier onlyMinter {
        require(authorisedMinters[msg.sender]  || msg.sender == owner(),"Not Authorised");
        _;
    }

    modifier onlyAdmins {
        require(admins[msg.sender] || msg.sender == owner(),"Not an admin.");
        _;
    }

    function setAuthorisedMinter(address user, bool auth) public onlyAdmins {
        authorisedMinters[user] = auth;
        emit AuthChanged(user,auth);
    }

    function setAdmin(address user, bool auth) public onlyAdmins {
        admins[user] = auth;
        emit AdminChanged(user,auth);
    }


    constructor(address newOwner, address secondAdmin) ERC777(_name,_symbol,nilOps) {
        transferOwnership(newOwner);
        authorisedMinters[secondAdmin] = true;
        admins[secondAdmin] = true;
        emit AuthChanged(secondAdmin, true);
        emit AdminChanged(secondAdmin, true);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        bytes memory userData;
        bytes memory operatorData;

        _mint(
            to, 
            amount, 
            userData, 
            operatorData
        );
    }

    function burnTokens(uint256 amount) external {
        bytes memory userData;
        bytes memory operatorData;
        _burn(
            msg.sender,
            amount,
            userData, 
            operatorData
        );
    }
}
