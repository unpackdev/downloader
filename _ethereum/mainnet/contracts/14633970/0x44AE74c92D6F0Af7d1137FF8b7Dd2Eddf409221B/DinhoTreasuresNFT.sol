// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721A.sol";  
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract DinhoTreasuresNFT is ERC721A, Ownable, AccessControl {

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Create a new role identifier for the owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");    

    using Strings for uint256;
    
    string private baseURI;

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return            
            interfaceId == type(IAccessControl).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    constructor(string memory _baseUri) ERC721A("Dinho Treasures NFT", "Dinho Treasures") {        
        baseURI = _baseUri;        
        _grantRole(OWNER_ROLE,msg.sender);
    }

    function _startTokenId() internal override pure returns (uint256) {
        return 1;
    }

    function totalMinted() external view returns(uint256){
        return _totalMinted();
    }
  
    function mint(address buyer,uint256 _quantity) public onlyRole(MINTER_ROLE) {
        _safeMint(buyer, _quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'));
        
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newUri) public onlyRole(OWNER_ROLE) {
        baseURI = newUri;
    }
    
    function setupMinterRole(address account) public onlyRole(OWNER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public onlyRole(OWNER_ROLE) {
        _revokeRole(MINTER_ROLE, account);
    }
}