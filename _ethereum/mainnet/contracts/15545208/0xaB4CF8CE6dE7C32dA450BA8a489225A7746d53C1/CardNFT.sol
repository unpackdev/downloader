// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
   
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
   
contract CardNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    bool public _revealed = false;
   
    string baseURI;


    address public management;

    string public notRevealedUri;
    string public baseExtension = ".json";
   
    mapping(uint256 => string) private _tokenURIs;
   
    constructor(string memory name,string memory symbol,string memory initBaseURI, string memory initNotRevealedUri)
        ERC721(name, symbol)
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    } 
    function mint(address owner) public {
        require(owner != address(0),"owner error");
        require(msg.sender == management,"msg.sender error");
       uint256 mintIndex = totalSupply();
        _mint(owner, mintIndex);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
   
        if (_revealed == false) {
            return notRevealedUri;
        }
   
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
   
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }
   
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
   
   
   
    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }
   
   
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
   
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setManagement(address _management) public onlyOwner {
        management = _management;
    }
   
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
   
   
}