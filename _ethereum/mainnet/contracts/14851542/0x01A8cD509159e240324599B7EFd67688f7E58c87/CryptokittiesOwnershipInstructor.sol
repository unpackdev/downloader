//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IERC165.sol";
import "./Ownable.sol";
import "./IOwnershipInstructor.sol";


interface ICryptokittiesContract {
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

/**
 * Cryptokitties Wrapper for the Cryptokitties contract,
 *
 * This is because Cryptokitties does not support the ERC721 interface.
 */
contract CryptokittiesOwnershipInstructor is IERC165,IOwnershipInstructor,Ownable{
    address immutable implementation = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    constructor(){
    }

    /**
    * Checks if the given contract is the implementation address
    * It should obtain an address as input and should return a boolean value;
    * @dev Contains a set of instructions to check the given _impl is the implementation contract
    * @param _impl address we want to check.
    * @return bool
    * 
    */
    function isValidInterface (address _impl) public view override returns (bool){
        return _impl == implementation;
    }

    /**
    * See {OwnershipInstructor.sol}
    * It should obtain a uint256 token Id as input and the address of the implementation 
    * It should return an address (or address zero is no owner);
    *
    * @param _tokenId token id we want to grab the owner of.
    * @param _impl Address of the NFT contract
    * @param _potentialOwner (OPTIONAL) A potential owner, set address zero if no potentialOwner;
    * @return address
    * 
    */
    function ownerOfTokenOnImplementation(address _impl,uint256 _tokenId,address _potentialOwner) public view override returns (address){
        require(isValidInterface(_impl),"Invalid interface");
        return ICryptokittiesContract(_impl).ownerOf(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IOwnershipInstructor).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}