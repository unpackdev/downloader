//SPDX-License-Identifier: MIT

/*  
             _          _       _     
            |_|        | |     | |    
   __      ___ _______ | | __ _| |__  
   \ \ /\ / / |_  /_  /| |/ _` | '_ \ 
    \ V  V /| |/ / / / | | (_| | |_) |
     \_/\_/ |_/___/___/|_|\__,_|_.__/ 

    Contract by: Alexander Kalen

*/

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Counters.sol";
import "Strings.sol";
import "Address.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";

contract elOtro is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    //URI
    bool public revealed;
    string private _baseTokenURI;
    string public notRevealedUri;

    uint256 public MAX_SUPPLY;
    uint256 public MAX_MINT;
    bool public mintingIsLive;
    Counters.Counter private _tokenIdtoTransfer;
    uint256 public cost = 60000000000000000;

    constructor(uint256 collectionSize_, uint256 amountToTransfer_)
        ERC721A("NoFaltabaTanto", "NFT")
    {
        MAX_SUPPLY = collectionSize_;
        MAX_MINT = amountToTransfer_;
        revealed = false;
        mintingIsLive = false;
    }

    //TokenURI mapping
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public TokensPerAddress;

    //Minting
    function mint(uint256 _quantity) public payable {
        require(mintingIsLive, "El minting no esta activado...");
        require(
            _totalMinted() + _quantity <= (MAX_SUPPLY),
            "Se acabo lo que se daba"
        );

        require(
            TokensPerAddress[msg.sender] + _quantity <= MAX_MINT,
            "Suficientes sombreros"
        );

        require(msg.value >= cost * _quantity, "No tienes suficiente ETH!");

        TokensPerAddress[msg.sender] += 1;

        _safeMint(msg.sender, _quantity);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    // Metadata URI
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function switchMintingState() external onlyOwner {
        mintingIsLive = !mintingIsLive;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function mintRemaining() external onlyOwner {
        require(!mintingIsLive, "El minting esta activado");
        require(_totalMinted() <= (MAX_SUPPLY), "Se acabo lo que se daba");
        _safeMint(msg.sender, (MAX_SUPPLY - _totalMinted()));
    }
}
