// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CountersUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";

contract SUBToken is Initializable,ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    IERC721 amb;
    IERC721 did;
    IERC721 ssr;
    using StringsUpgradeable for uint256;

    error TokenIsSoulbound();
    
    string public baseURI;
    mapping (address=>address) public belongsTo;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(    
        address _ambAddr,
        address _didAddr,
        address _ssrAddr) initializer public {
        __ERC721_init("SUBTOKEN", "SUB");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        baseURI = "https://raw.githubusercontent.com/NutiDAODEV1/metadata_test/main/SUB/SUB_";
        amb = IERC721(_ambAddr);
        did = IERC721(_didAddr);
        ssr = IERC721(_ssrAddr);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    // 1 to 1 bound
    function safeMintTo(address subAddr) public {
        require(amb.balanceOf(msg.sender) == 1, "Unauthorized to mint");
        require(did.balanceOf(subAddr) == 1, "not NUTs user");
        require(amb.balanceOf(subAddr)==0 && ssr.balanceOf(subAddr) == 0,
        "Unauthorized to receive");
        require(balanceOf(subAddr) == 0, "Not reclaimable");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(subAddr, tokenId);
        belongsTo[subAddr] = msg.sender;
    }

    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }
    
    function safeTransferFrom(address from, address to, uint256 id)  public onlyOwner override {
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public override {
        onlySoulbound(from, to);
        super.safeTransferFrom(from, to, id, data);
    }

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
 
//     function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (bool) {
//     return ERC721Upgradeable.supportsInterface(interfaceId) || ERC721URIStorageUpgradeable.supportsInterface(interfaceId);
//   }

  

}


