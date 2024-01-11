//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC165.sol";
import "./IOwnershipInstructorRegisterV1.sol";
import "./IOwnershipInstructor.sol";
import "./Ownable.sol";

/**
 * Goes through a register of contracts and checks for ownership of an on-chain token.
 */
contract OwnershipCheckerV1 is ERC165,Ownable {

    string internal _name;
    string internal _symbol;

    address public register;

    event NewRegister(address indexed register);

    constructor(address _register){
        _name="OwnershipCheckerV1";
        _symbol = "CHECK";
        register = _register;
    }

    function name() public view returns (string memory){
        return _name;
    }
    
    function symbol() public view returns (string memory){
        return _symbol;
    }

    function setRegisterImplementation(address _register) public onlyOwner{
         register = _register;
        emit NewRegister( _register);
    }


    function ownerOfTokenAt(address _impl,uint256 _tokenId,address _potentialOwner) external view  returns (address){
        IOwnershipInstructorRegisterV1.Instructor memory object = IOwnershipInstructorRegisterV1(register).instructorGivenImplementation(_impl);
        if(object._impl == address(0)){
            return address(0);
        }else{
            return IOwnershipInstructor(object._impl).ownerOfTokenOnImplementation(_impl, _tokenId, _potentialOwner);
        }
    }

    
}
