// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CountersUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
// import "./draft-EIP712Upgradeable.sol";
// import "./draft-ERC721VotesUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract SSRToken is Initializable,AccessControlUpgradeable,ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");


    using StringsUpgradeable for uint256;

    error TokenIsSoulbound();

    string public baseURI;

    //SSR availability
    struct SSRinfo{
    
    uint256 joinTime;
    uint256 endTime;
    }
    mapping (uint256 => SSRinfo) public SSRaval;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    function initialize() initializer public {
        __ERC721_init("SSRToken", "SSR");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setupRole(MINTER_ROLE,msg.sender);
        _setupRole(MINTER_ADMIN,msg.sender);
        _setRoleAdmin(MINTER_ROLE,MINTER_ADMIN);
        baseURI = "https://raw.githubusercontent.com/NutiDAODEV1/NutsDAO_SSR/main/SSR_";
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    //check availability of SSR
    function checkAvaliable(uint256 tokenId) public view returns(bool){
        _requireMinted(tokenId);
        SSRinfo storage ssr = SSRaval[tokenId];
        return block.timestamp < ssr.endTime;
    }

    function checkRemaining(uint256 tokenId) public view returns(uint256){
        _requireMinted(tokenId);
        SSRinfo storage ssr = SSRaval[tokenId];
        return ssr.endTime - block.timestamp ;
    }
    // 1 to 1 bound
    function safeMint() public {
      require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized to mint");
      require(balanceOf(msg.sender) == 0, "Not reclaimable");      
        
        uint256 tokenId = _tokenIdCounter.current();
        SSRinfo storage ssr = SSRaval[tokenId];
        ssr.joinTime = block.timestamp;
        ssr.endTime = block.timestamp + 365 days;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }


    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }

    
    // function safeTransferFrom(address from, address to, uint256 id)  public onlyOwner override {
    //     super.safeTransferFrom(from, to, id);
    // }


    // function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public override {
    //     onlySoulbound(from, to);
    //     super.safeTransferFrom(from, to, id, data);
    // }


        function transferFrom(address from, address to, uint256 id) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }


    // The following two functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }


    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    //     returns (string memory)
    // {
    //     return super.tokenURI(tokenId);
    // }


    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner{

        _setTokenURI(tokenId, _tokenURI);
    }

    
    function burn(uint256 tokenId)
        public onlyOwner{
        _burn(tokenId);
        }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
  

    function tokenURI(uint256 tokenId)
        public view virtual 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        _requireMinted(tokenId);
        string memory tokenBaseURI = _baseURI();
        string memory tokenJon = string(abi.encodePacked(tokenId.toString(),".json"));
        return bytes(tokenBaseURI).length > 0 ? string(abi.encodePacked(tokenBaseURI, tokenJon)) : "";
    }


    function grantMinterRole(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)){
        
    _grantRole(MINTER_ROLE, account);
    }


    function revokeMinterRole(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)){
        
    _revokeRole(MINTER_ROLE, account);
    }


    // function grantSSR(address account) public virtual onlyOwner{

    // _grantRole(MINTER_ADMIN, account);
    // }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
    return ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
  }

  

}


