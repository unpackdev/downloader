//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

contract dyorktown is ERC721A, ERC2981, Ownable {

    string private collectionURI;
    uint96 public maxMint;
    uint256 public maxSupply;
    string private OpenseaContractURI;
    bool private revealed = false;
    string private revealUrl;
    bool private mintOpen = false;


    constructor(uint96 _royaltyFeesInBips, uint96 _maxMint, uint256 _maxSupply, string memory _openseaContractURI, string memory _revealUrl) ERC721A("dyorktown.wtf", "DYOR") {
        setRoyaltyInfo(msg.sender, _royaltyFeesInBips);
        maxMint = _maxMint;
        maxSupply = _maxSupply;
        OpenseaContractURI = _openseaContractURI;
        revealUrl = _revealUrl;

    }

    function mint (uint256 quantity) external {
        require(mintOpen == true, "Mint not live yet");
        require(quantity <= maxMint, "Max amount per mint exceeded");
        require((totalSupply() + quantity) <= maxSupply );
        _safeMint(msg.sender, quantity);
    }

    function _startTokenId() internal view override returns (uint256){
        return 1;
    }

    function _baseURI() internal view override returns (string memory){
        return collectionURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();

        if (revealed == true){
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
        } else {
            return revealUrl;
        }   
    }

    function supportsInterface (bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool){
        return 
            interfaceId == type(IERC2981).interfaceId || 
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f;  // ERC165 interface ID for ERC721Metadata.
    }

    function setRoyaltyInfo (address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator) ;
    }

    function setContractURI (string calldata _contractURI) external onlyOwner {
        collectionURI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return OpenseaContractURI;
    }

    function revealCollection(string memory _collectionURI) external onlyOwner  {
        collectionURI = _collectionURI;
        revealed = true;

    }

    function initMint (uint256 quantity) external onlyOwner {
        require((totalSupply() + quantity) <= maxSupply );
        _safeMint(msg.sender, quantity);
    }

    function toggleMintOpen() external onlyOwner {
        if(mintOpen == false){
            mintOpen = true;
        }
        else{
            mintOpen = false;
        }
    }

}
