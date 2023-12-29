// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

contract MetallicOrdinals is 
        ERC721A,
        DefaultOperatorFilterer,
        ERC2981, 
        Ownable, 
        ReentrancyGuard {

    using Strings for uint256;
    

    uint256 public maxSupply = 60;

    uint256 public price = 0.04 ether;
    uint256 public maxPerMint = 2; 

    bool public open = false; 
    bool public isWhitelistSale = false; 
    bool public isPublicSale = false;    
    bool public isRevealed = false;
    bytes32 public merkleRoot;
    string public metaDataURI = 'ipfs://bafybeibt2ahkyjjijcjv5mn6xm7a4nbv6tdk3t24xdq7f2w7fbzo7g4y2e/';

    address private OwnerAdress = 0x4c0CCd9cc894c1CCA6995b088c5886C9d0E3aaB5;
    mapping (address => bool) public walletMintedWL;
    mapping (address => bool) public walletMintedPub;

    error MaxSupplyExceeded();

    constructor() ERC721A("MetallicOrdinals", "MTLORD") {
      
    }

    // ========= CONTRACT STATES =========
    function isContractActive() public onlyOwner {
        open = !open;
    }

    function isWhitelisteSaleActive() public onlyOwner {
        isWhitelistSale = !isWhitelistSale;
    }

    function isPublicSaleActive() public onlyOwner {
        isPublicSale = !isPublicSale;
    }   


    // ========= MODIFIER =========
    modifier mintModifier(uint256 amount) {
        require(open, 'Contract is not active');
        require(totalSupply() + amount <= maxSupply, 'Max supply exceeded!'); 
        require(amount <= maxPerMint, 'Max 2 per wallet!');
        uint256 fullPrice = amount * price;
        require(fullPrice == msg.value, 'Insufficient funds!'); 
        _;   
    }

    // ========= MINT =========
    function whitelistMint(uint256 amount, bytes32[] calldata proof) external payable mintModifier(amount) {
        require(isWhitelistSale, 'WL Sale is not active');
        require(!walletMintedWL[_msgSender()], 'Wallet already minted!');
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Incorrect proof" );
        walletMintedWL[_msgSender()] = true;
        _safeMint(_msgSender(), amount);
    } 

    function publicMint(uint256 amount) external payable mintModifier(amount) {
        require(isPublicSale, 'WL Sale is not active');
        require(!walletMintedPub[_msgSender()], 'Wallet already minted!');
        walletMintedPub[_msgSender()] = true;
        _safeMint(_msgSender(), amount);
    }


// ========= AIRDROP =========
function airdrop(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) public onlyOwner nonReentrant {
        require(open, 'Contract is not active');
        uint256 length = _accounts.length;

        for (uint256 i = 0; i < length; ) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];

            if (totalSupply() + amount > maxSupply)
                revert MaxSupplyExceeded();

            _safeMint(account, amount);

            unchecked {
                i += 1;
            }
        }
    }

// ========= OWNER MINT =========
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(open, 'Contract is not active');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
    
    }


// ========= METADATA =========
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'TokenID does not exsist!');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
      : '';
    }


// ========= SET FUNCTIONS =========

        //Set supply
    function setMaxSupply (uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    //max per Wallet
    function setMaxPerMint (uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
    }

    //Set price
    function setPrice (uint256 _price) external onlyOwner {
        price = _price;
    }

    //Merkel root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRevealed() public onlyOwner {
    isRevealed = !isRevealed;
    }     

    function setBaseURI(string memory _metaDataURI) external onlyOwner {
    metaDataURI = _metaDataURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return metaDataURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    // ========= BURN =========
    function burn(uint256 tokenId) external {
        require(open, 'Contract is not active');
        _burn(tokenId, true);
    }

// ========= WITHDRAW =========
    function withdraw() public onlyOwner {
    payable(OwnerAdress).transfer(address(this).balance); 
    }

 // ========= ROYALTY =========

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}