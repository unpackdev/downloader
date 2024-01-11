// SPDX-License-Identifier: MIT

  // Amended by HashLips
  /**
      !Disclaimer!
      These contracts have been used to create tutorials,
      and was created for the purpose to teach people
      how to create smart contracts on the blockchain.
      please review this code on your own before using any of
      the following code for production.
      HashLips will not be liable in any way if for the use 
      of the code. That being said, the code has been tested 
      to the best of the developers' knowledge to work as intended.
      
  */
  pragma solidity >=0.7.0 <0.9.0;

  import "./ERC721Enumerable.sol";
  import "./Ownable.sol";

  contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.13 ether;
    uint256 public maxSupply = 500;
    uint256 public maxMintCount = 11;
    mapping (address => uint256) addressToNumberOfTokensMinted;
    bool public paused = false;


    constructor(
      string memory _name,
      string memory _symbol,
      string memory _initBaseURI
    ) ERC721(_name, _symbol) {
      setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
      uint256 supply = totalSupply();
      addressToNumberOfTokensMinted[msg.sender] += _mintAmount;
      require(addressToNumberOfTokensMinted[msg.sender] < maxMintCount, "No mints left for this wallet!");
      require(!paused);
      require(_mintAmount > 0);
      require(supply + _mintAmount <= maxSupply);

      if (msg.sender != owner()) {
        require(msg.value >= cost * _mintAmount);
      }

      for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(msg.sender, supply + i);
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
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
          : "";
    }  
    function setCost(uint256 _newCost) public onlyOwner {
      cost = _newCost;
    }

    function setMaxMintCount(uint256 _maxMintCount) public onlyOwner {
      maxMintCount = _maxMintCount;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
      baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
      paused = _state;
    }

  
    function withdraw() public payable onlyOwner { 
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }
  }