// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC1155.sol";

contract SoulbondWarPets is ERC1155, AccessControl, Ownable, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    string public name;
    uint public warPetId;
    mapping(uint => address) public warPetNation;
    mapping(uint => bool[10000]) public tokenClaims;

    // Optional mapping for token URIs
    mapping(uint256 => string) public tokenURIs;

    constructor(
        string memory _name,
        string memory _uri, 
        address _nationContract,
        uint _warPetId
    ) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        name = _name;
        warPetId = _warPetId;
        warPetNation[_warPetId] = _nationContract;
        setTokenURI(_warPetId, _uri);
        _pause();
    }

    function mint(uint[] memory tokenIds) public whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenClaims[warPetId][tokenIds[i]] == false, "Token has been claimed");
            require(IERC721(warPetNation[warPetId]).ownerOf(tokenIds[i]) == msg.sender, "Sender is not a token owner");
            tokenClaims[warPetId][tokenIds[i]] = true;
        }
        _mint(msg.sender, warPetId, tokenIds.length, "");
    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function switchNation(address _nationContract, uint _warPetId) public onlyRole(OPERATOR_ROLE) {
        require(warPetNation[_warPetId] == address(0), "War pet already has a nation");
        warPetId = _warPetId;
        warPetNation[_warPetId] = _nationContract;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getTokenIds(address account) public view returns (uint[] memory){
        uint256 balance = IERC721Enumerable(warPetNation[warPetId]).balanceOf(account);
        uint[] memory tokenIds = new uint[](balance);
        for (uint i = 0; i < balance; i++) {
            tokenIds[i] = IERC721Enumerable(warPetNation[warPetId]).tokenOfOwnerByIndex(account, i);
        }
        return tokenIds;
    }

    function getFilteredTokenIds(bool minted, address account) public view returns (uint[] memory){
        uint[] memory tokenIds = getTokenIds(account);
        uint counter = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if(tokenClaims[warPetId][tokenIds[i]] == minted){                
                counter++;
            }
        }        
        uint[] memory filteredTokenIds = new uint[](counter);
        counter = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if(tokenClaims[warPetId][tokenIds[i]] == minted){
                filteredTokenIds[counter] = tokenIds[i];
                counter++;
            }
        }     
        return filteredTokenIds;
    }

    function uri(uint256 _warPetId) public view virtual override returns (string memory) {
        return tokenURIs[_warPetId];
    }

    function setTokenURI(uint256 _warPetId, string memory _uri) public onlyRole(OPERATOR_ROLE) {
        require(warPetNation[_warPetId] != address(0x0), "setTokenURI: Token should exist");
        tokenURIs[_warPetId] = _uri;
    }
}