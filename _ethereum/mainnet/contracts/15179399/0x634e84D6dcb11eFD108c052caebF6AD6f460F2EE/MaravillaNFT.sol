// SPDX-License-Identifier: MIT
pragma solidity = 0.8.15;

import "./ERC721A.sol";  
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract MaravillaNFT is ERC721A, Ownable, AccessControl {

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Create a new role identifier for the owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");    

    using Strings for uint256;
    
    uint256 private immutable maxSupply;
    string private baseURI;

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return            
            interfaceId == type(IAccessControl).interfaceId || 
            super.supportsInterface(interfaceId);
    }
    constructor(uint256 _maxSupply,string memory _baseUri) ERC721A("Maravilla NFT", "Maravilla") {        
        maxSupply = _maxSupply;
        baseURI = _baseUri;
        _setupRole(OWNER_ROLE,msg.sender);
    }

    function _startTokenId() internal override pure returns (uint256) {
        return 1;
    }

    function totalMinted() external view returns(uint256){
        return _totalMinted();
    }
  
    function mint(address buyer,uint256 _quantity) public onlyRole(MINTER_ROLE) {
        require((getMaxSupply() - _totalMinted()) > _quantity,"Maravilla NFT: remaining token supply is not enough.");                         
        _safeMint(buyer, _quantity); 
    }
   
    function setupMinterRole(address account) public onlyRole(OWNER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function setupOwnerRole(address account) public onlyRole(OWNER_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'));
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newUri) public onlyRole(OWNER_ROLE){
        baseURI = newUri;
    }
}