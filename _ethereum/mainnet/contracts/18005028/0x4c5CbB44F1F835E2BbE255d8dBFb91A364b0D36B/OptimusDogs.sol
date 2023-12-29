// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

error SaleNotActive();
error SaleNotInWLOGPhase();
error InvalidMerkleProof();
error ExceedsMaxPerTransaction();
error ExceedsMaxPerAddress();
error ExceedsMaxSupply();
error ExceedsMaxPerPublic();
error InsufficientPayment();
error TransferFailed();
error ExceedsMaxPerTeam();
error AmountNotMultipleOfBatchSize();
error LargerCollectionSizeNeeded();

contract OptimusDogs is ERC721A, Ownable, ReentrancyGuard, ERC2981 {
    using Strings for uint256;
    

    uint256 public MINT_PRICE = 0.04 ether; 
    uint256 public WL_PRICE = 0.03 ether; 
    uint256 public OG_PRICE = 0.026 ether; 
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable AmountforTeam;
    uint256 public immutable AmountForPublic;
    uint256 public immutable maxBatchSizeForWL;
    uint256 public  remainingTeamMints;
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;
    
    uint256 public salePhase = 0; // 0 = no sale, 1 = WL & OG phase, 2 = public phase


    bytes32 public merkleRootWL;
    bytes32 public merkleRootOG;

    bool public revealed = false;

    
    

    
    mapping(address => uint256) public _mintedPerAddress;
    

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 AmountForPublic_,
        uint256 AmountforTeam_,
        string memory _hiddenMetadataUri
    ) ERC721A("OptimusDogs", "OPDOGS", maxBatchSize_, collectionSize_) {
        _setDefaultRoyalty(msg.sender, 500); // 5% royalties
        setHiddenMetadataUri(_hiddenMetadataUri);
        maxPerAddressDuringMint = maxBatchSize_;
        maxBatchSizeForWL = maxBatchSize_ / 2;
        AmountForPublic = AmountForPublic_;
        AmountforTeam = AmountforTeam_;
        remainingTeamMints = AmountforTeam_;
        require(
            AmountForPublic_ <= collectionSize_,
            "larger collection size needed"
        );

    }

    function _verifyMerkleProof(address account, bytes32[] memory proof, bytes32 merkleRoot) private pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

   

     function setSalePhase(uint256 phase) external onlyOwner {
        salePhase = phase;
    }
    
    function setMerkleRootWL(bytes32 merkleRoot) external onlyOwner {
        merkleRootWL = merkleRoot;
    }

    function setMerkleRootOG(bytes32 merkleRoot) external onlyOwner {
        merkleRootOG = merkleRoot;
    }




    function mintForTeam(uint256 amount) external nonReentrant onlyOwner {
        if (totalSupply() + amount > collectionSize) revert ExceedsMaxSupply();
        if (remainingTeamMints < amount) revert ExceedsMaxPerTeam();
        if (amount % maxBatchSize != 0) revert AmountNotMultipleOfBatchSize();
        
        uint256 SizeforTeam = amount / maxBatchSize;
        for (uint256 i = 0; i < SizeforTeam ; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
        
        remainingTeamMints -= amount; 
        
    }
    
    function mintForWL(uint256 amount, bytes32[] calldata merkleProof) external payable nonReentrant {
        if (salePhase != 1) revert SaleNotInWLOGPhase();
        if (!_verifyMerkleProof(msg.sender, merkleProof, merkleRootWL)) revert InvalidMerkleProof();
        if (amount > maxBatchSizeForWL) revert ExceedsMaxPerTransaction();
        if (_mintedPerAddress[msg.sender] + amount > maxBatchSizeForWL) revert ExceedsMaxPerAddress();
        if (totalSupply() + amount > AmountForPublic) revert ExceedsMaxPerPublic();
        
        uint256 totalPrice = WL_PRICE * amount;
        if (msg.value < totalPrice) revert InsufficientPayment();
        _mintedPerAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForOG(uint256 amount, bytes32[] calldata merkleProof) external payable nonReentrant {
        if (salePhase != 1) revert SaleNotInWLOGPhase();
        if (!_verifyMerkleProof(msg.sender, merkleProof, merkleRootOG)) revert InvalidMerkleProof();
        if (amount > maxPerAddressDuringMint) revert ExceedsMaxPerTransaction();
        if (_mintedPerAddress[msg.sender] + amount > maxPerAddressDuringMint) revert ExceedsMaxPerAddress();
        if (totalSupply() + amount > AmountForPublic) revert ExceedsMaxPerPublic();
        
        uint256 totalPrice = OG_PRICE * amount;
        if (msg.value < totalPrice) revert InsufficientPayment();
        
        _mintedPerAddress[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }


    function mintForPublic(uint256 amount) external payable nonReentrant {
        if (salePhase != 2) revert SaleNotActive();
        if (amount > maxBatchSizeForWL) revert ExceedsMaxPerTransaction();
        if (_mintedPerAddress[msg.sender] + amount > maxBatchSizeForWL) revert ExceedsMaxPerAddress();
        if (totalSupply() + amount > AmountForPublic) revert ExceedsMaxPerPublic();

        _mintedPerAddress[msg.sender] += amount; 

        uint256 totalPrice = MINT_PRICE * amount ; 
        if (msg.value < totalPrice) revert InsufficientPayment();
        
        _safeMint(msg.sender, amount);
        
    }
    

    
    
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }    

    

   function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

      if (revealed == false) {
        return hiddenMetadataUri;
      }
      
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
         ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
         : '';
    }

   function setRevealed(bool _state) public onlyOwner {
     revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        
        uriPrefix = _uriPrefix;
    }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
     uriSuffix = _uriSuffix;
    }


  function _baseURI() internal view virtual override returns (string memory) {
     return uriPrefix;
    }


    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
