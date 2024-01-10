// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract SakuraProjectNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.06 ether;
    uint256 public whiteListCost = 0.06 ether;
    uint256 public maxSupply = 5678;
    uint256 public mintPerAddressLimit = 5;
    uint256 public mintPerAddressLimitPreSale = 2;
    uint256 public amountForDevs = 100;

    bool public paused = true;
    bool public orderpresaleActive = false;
    bool public seedlingpresaleActive = false;
    bool public revealed = false;

    mapping(address => uint256) public addressMintedBalance;

    bytes32 public orderMerkleRoot;
    bytes32 public seedlingMerkleRoot;

  constructor() ERC721A("Sakura Project", "SKPJ", 5) {
    setHiddenMetadataUri("ipfs://QmX4xQie2kEZp6GPCCokSvDJm6h47KZhKHYkwz57jPKjPy/hidden.json");
  }
  
    // Verifications

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isValidMerkleProofTwo(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(
            price * quantity == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender, 
            "The caller is another contract"
        );
        _;
    }

    // internal

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory) 
    {
        return baseURI;
    }

    // Public Sale

     function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(quantity > 0, "need to mint at least 1 NFT");
        require(quantity <= mintPerAddressLimit, "max mint amount per session exceeded");
        require(supply + quantity <= maxSupply, "max NFT limit exceeded");
        require(numberMinted(msg.sender) + quantity <= mintPerAddressLimit, "this would exceed your Sakura Project mint limit.");

        if (msg.sender != owner()) {
            require(msg.value >= cost * quantity, "insufficient funds");
        }

        _safeMint(msg.sender, quantity);
      
    }

    // Order Mint Phase

    function orderMint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        payable
        isValidMerkleProof(merkleProof, orderMerkleRoot)
        isCorrectPayment(whiteListCost, quantity)
        callerIsUser
    {
        uint256 supply = totalSupply();
        require(quantity > 0, "need to mint at least 1 NFT");
        require(orderpresaleActive, "Order Presale is inactive!");
        require(supply + quantity <= maxSupply, "max NFT limit exceeded");
        require(numberMinted(msg.sender) + quantity <= mintPerAddressLimitPreSale, "this would exceed your Sakura Project mint limit.");
        _safeMint(msg.sender, quantity);
    }


    // Seedling Mint Phase

    function seedlingMint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        payable
        isValidMerkleProofTwo(merkleProof, seedlingMerkleRoot)
        callerIsUser
    {
        uint256 supply = totalSupply();
        require(quantity > 0, "need to mint at least 1 NFT");
        require(seedlingpresaleActive, "Seedling Presale is inactive!");
        require(supply + quantity <= maxSupply, "max NFT limit exceeded");
        require(numberMinted(msg.sender) + quantity <= mintPerAddressLimitPreSale, "this would exceed your Sakura Project mint limit.");
        _safeMint(msg.sender, quantity);
    }

    // Dev Mint

    function devMint(uint256 quantity) 
        external 
        onlyOwner 
    {
        require(totalSupply() + quantity <= amountForDevs, "You already did this or there's not enough left");
        require(quantity % maxBatchSize == 0,"can only mint a multiple of the maxBatchSize" );
        uint256 numChunks = quantity / maxBatchSize;

        for (uint256 i = 0; i < numChunks; i++) 
        {
      _safeMint(msg.sender, maxBatchSize);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // Functions

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setorderMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        orderMerkleRoot = merkleRoot;
    }

        function setseedlingMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        seedlingMerkleRoot = merkleRoot;
    }

    function setmintperAddressLimit(uint256 _limit) public onlyOwner {
        mintPerAddressLimit = _limit;
    }

    function setmintperAddressLimitPresale(uint256 _limit) public onlyOwner {
        mintPerAddressLimitPreSale = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whiteListCost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }


    // Modes

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    function orderPresale(bool _state) public onlyOwner {
        orderpresaleActive = _state;
    }
    function seedlingPresale(bool _state) public onlyOwner {
        seedlingpresaleActive = _state;
    }

    // Payment
    
    function withdraw(uint256 amount) public payable onlyOwner nonReentrant {    
    (bool hs, ) = payable(0xcfb713326fBB55603CEC86971EE967FD83198945).call{value: amount * 50 / 100}("");
    require(hs);
    (bool os, ) = payable(0xb41bE272630123D01B1C2fa62852BFA85328936b).call{value: amount * 40 / 100}("");
    require(os);
    (bool success, ) = payable(0xb41bE272630123D01B1C2fa62852BFA85328936b).call{value: amount * 10 / 100}("");
    require(success, "Transfer Failed");
    }

    function withdrawtoProject(uint256 amount) public payable onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed.");
   }

}