pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";

contract Waves is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;

    IERC721Enumerable public tunes = IERC721Enumerable(0xfa932d5cBbDC8f6Ed6D96Cc6513153aFa9b7487C);
    bool public frozen = false;
    string private _tokenBaseURI;

    constructor() ERC721("Waves", "WAVES") {}

    function _baseURI() internal override view returns (string memory) {
        return _tokenBaseURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!frozen, "Contract is frozen.");

        _tokenBaseURI = baseURI;
    }

    function claim(uint256[] calldata tokenIds) public payable {
        require(msg.value == .005 ether, "You must pay .005 ether");
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            require(tokenId > 0 && tokenId <= tunes.totalSupply(), "You cannot mint outside of the IDs of Tunes.");
            require(tunes.ownerOf(tokenId) == msg.sender, "You must own the corresponding Tune to mint this.");
        }
        
        // Use two loops to prevent safemint call if a token id later in the flow is incorrect. Saves the claimer gas if they made a mistake
        
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _safeMint(msg.sender, tokenId);
        }
    }

    function freezeBaseURI() public onlyOwner {
        frozen = true;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        
        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        
        return "";
    }
}