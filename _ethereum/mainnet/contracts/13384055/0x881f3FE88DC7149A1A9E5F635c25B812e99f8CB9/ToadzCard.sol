// contracts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract ToadzCard is ERC721Enumerable, Ownable {

    ERC721 CrypToadz = ERC721(0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6);

    string _varBaseURI;

    // Free claim for CrypToadz Owners
    // 0.0096 ETH for public mint
    uint256 public constant PUBLIC_MINT_PRICE = 0.0096 ether;
    uint256 public publicSupply = 0;

    constructor(string memory baseURI) public ERC721("Toadz Card", "ToadzCard") {
        setBaseURI(baseURI);
    }

    function crypToadzOwnerClaim(uint256 tokenId) public {
        require(tokenId > 0 && tokenId < 6970, "Token ID invalid");
        require(CrypToadz.ownerOf(tokenId) == msg.sender, "Not owner");
        _safeMint(_msgSender(), tokenId);
    }

    function crypToadzOwnerClaimMultiple(uint256[] memory tokenIds) public {
        for (uint256 i=0; i< tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 0 && tokenId < 6970, "Token ID invalid");
            require(CrypToadz.ownerOf(tokenId) == msg.sender, "Not all owner");
            _safeMint(_msgSender(), tokenId);
        }
    }

    function publicMint(uint256 _quantity) public payable {
        require( publicSupply < 2728, "No more tokens to mint");
        require(msg.value >= PUBLIC_MINT_PRICE * _quantity, "Ether amount is not correct");

        for (uint i = 0; i < _quantity; i++) {
            publicSupply = publicSupply + 1;
            _safeMint(msg.sender, 6969 + publicSupply);
        }
    }

    function getPrice(uint256 _quantity) public pure returns(uint256) {
        return PUBLIC_MINT_PRICE * _quantity;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "You are not the owner");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _varBaseURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _varBaseURI = baseURI;
    }

}
