// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract RGBSquares is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;
    
    uint256 public immutable MAX_SUPPLY;

    bool public mintStatusActive;
    bool public checkPhaseActive;
    uint256 public MAX_MINT_PER_WALLET = 2;
    uint256 public MINT_PHASE = 1;
    uint256 public PRICE = 0 ether;

    event PriceUpdated(uint256 previousValue, uint256 value);
    event MintStatusChanged();
    event CheckPhaseChanged();
    event Minted(address minter, uint256 amount);

    mapping(uint256 => string) private _tokenURIs;

    string public baseURI;
    string public baseExtension = ".json";

    constructor(string memory _initURI, uint256 _collectionSize) ERC721A("RGB Squares", "RGBSQUARE", 2, _collectionSize) {
        MAX_SUPPLY = _collectionSize;
        setBaseURI(_initURI);
        mintStatusActive = true;
        checkPhaseActive = true;
    }

    function mint( uint256 tokenQuantity ) external payable {
        require(mintStatusActive, "(mint): Public mint is not Active");
        require(tx.origin == msg.sender, "(mint): Contract is not allowed to mint.");
        require(numberMinted(msg.sender) + tokenQuantity <= MAX_MINT_PER_WALLET, "(mint): Max public mint amount per wallet exceeded");
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "(mint): Exceed max supply");
        require((PRICE * tokenQuantity) <= msg.value, "(mint): Ether value sent is not correct");        

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, 1);
        } 

        if(MINT_PHASE < 4 && checkPhaseActive){
            if(MINT_PHASE == 1 && totalSupply() >= 1000){
                MINT_PHASE = 2;
                PRICE = 0.01 ether;
                MAX_MINT_PER_WALLET = 5;
            }

            if(MINT_PHASE == 2 && totalSupply() >= 5000){
                MINT_PHASE = 3;
                PRICE = 0.1 ether;
                MAX_MINT_PER_WALLET = 15;
            }

            if(MINT_PHASE == 3 && totalSupply() >= 15000){
                MINT_PHASE = 4;
                PRICE = 1 ether;
                MAX_MINT_PER_WALLET = 500;
            }    
        }     
        
        emit Minted(msg.sender, tokenQuantity);
        
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "(tokenURI): URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() external nonReentrant onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "(withdraw): Transfer failed.");
    }

    function setPrice(uint256 value) external onlyOwner {
        uint256 previousValue = PRICE;
        PRICE = value;
        emit PriceUpdated(previousValue, value);
    }    

    function toggleMintStatus() external onlyOwner {
        mintStatusActive = !mintStatusActive;
        emit MintStatusChanged();
    }

    function toggleCheckPhase() external onlyOwner {
        checkPhaseActive = !checkPhaseActive;
        emit CheckPhaseChanged();
    }

    function numberMinted(address owner) internal view returns (uint256) {
        return _numberMinted(owner);
    }

    function batchMint(address to, uint256 tokenQuantity) external onlyOwner {
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "(batchMint): Exceed max supply");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(to, 1);
        }

        if(MINT_PHASE < 4 && checkPhaseActive){
            if(MINT_PHASE == 1 && totalSupply() >= 1000){
                MINT_PHASE = 2;
                PRICE = 0.01 ether;
                MAX_MINT_PER_WALLET = 5;
            }

            if(MINT_PHASE == 2 && totalSupply() >= 5000){
                MINT_PHASE = 3;
                PRICE = 0.1 ether;
                MAX_MINT_PER_WALLET = 15;
            }

            if(MINT_PHASE == 3 && totalSupply() >= 15000){
                MINT_PHASE = 4;
                PRICE = 1 ether;
                MAX_MINT_PER_WALLET = 500;
            }    
        }     

        emit Minted(to, tokenQuantity);
    }   

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
    
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}