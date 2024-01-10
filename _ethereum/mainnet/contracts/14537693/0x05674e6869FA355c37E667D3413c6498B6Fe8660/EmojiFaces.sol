    // SPDX-License-Identifier: MIT
    import "./ERC721.sol";
    import "./Pausable.sol";
    import "./Ownable.sol";
    import "./SafeMath.sol";
    import "./ERC721Enumerable.sol";
    
    pragma solidity ^0.8.4;
    pragma abicoder v2;
    
    contract MetaRockets is ERC721, Pausable, Ownable, ERC721Enumerable {
      using SafeMath for uint256;
      using Strings for uint256;
    

      uint256 public constant tokenPrice = 190000000000000000; // 0.0019 ETH 
      uint256 public constant maxTokenPurchase = 3;
      uint256 public constant MAX_TOKENS = 10000;
    
      string public baseURI = ""; // IPFS URI WILL BE SET AFTER ALL TOKENS SOLD OUT
    
      bool public saleIsActive = true;
      bool public presaleIsActive = false;
      bool public isRevealed = false;
    
      mapping(address => bool) private _presaleList;
      mapping(address => uint256) private _presaleListClaimed;
    
      uint256 public presaleMaxMint = 2;
      uint256 public devReserve = 64;
    
      event EmojiMinted(uint256 tokenId, address owner);
    
      constructor() ERC721("MetaRockets", "MTR") {
        _presaleList[0xE9C1c3Fa8eBF3cA50F2668CFbe4C3ec5D7899451] = true;
        _presaleList[0x721D8598b9Ec2E3f8791249edf5dA2aF62D5A548] = true;
        _presaleList[0xd4e728c08e86f6BBeBC52a49E8f04932b937f5a6] = true;
      }
      
      
      function pause() public onlyOwner {
          _pause();
      }

      function unpause() public onlyOwner {
          _unpause();
      }
        
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }
      
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
      }

   
    
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os);
      }
    
      function reveal() public onlyOwner {
        isRevealed = true;
      }
    
      function reserveTokens(address _to, uint256 _reserveAmount)
        external
        onlyOwner
      {
        require(
          _reserveAmount > 0 && _reserveAmount <= devReserve,
          "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
          uint256 id = totalSupply();
          _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
      }
    
      function toggleSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
      }
    
      function togglePresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
      }
    
      function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
      {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
          // Return an empty array
          return new uint256[](0);
        } else {
          uint256[] memory result = new uint256[](tokenCount);
          uint256 index;
          for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
          }
          return result;
        }
      }


      function teamMint(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
          uint256 id = totalSupply().add(1);
          if (totalSupply() < MAX_TOKENS) {
            _safeMint(addresses[i], id);
              emit EmojiMinted(id, addresses[i]);
          }
        }
      }
    
      function mintEmoji(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Token");
        require(
          numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
          "Can only mint one or more tokens at a time"
        );
        require(
          totalSupply().add(numberOfTokens) <= MAX_TOKENS,
          "Purchase would exceed max supply of tokens"
        );
        require(
          msg.value >= tokenPrice.mul(numberOfTokens),
          "Ether value sent is not correct"
        );
    
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 id = totalSupply().add(1);
          if (totalSupply() < MAX_TOKENS) {
            _safeMint(msg.sender, id);
            emit EmojiMinted(id, msg.sender);
          }
        }
      }
    
      function presaleEmoji(uint256 numberOfTokens) external payable {
        require(presaleIsActive, "Presale is not active");
        require(_presaleList[msg.sender], "You are not on the Presale List");
        require(
          totalSupply().add(numberOfTokens) <= MAX_TOKENS,
          "Purchase would exceed max supply of token"
        );
        require(
          numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
          "Cannot purchase this many tokens"
        );
        require(
          _presaleListClaimed[msg.sender].add(numberOfTokens) <= presaleMaxMint,
          "Purchase exceeds max allowed"
        );
        require(
          msg.value >= tokenPrice.mul(numberOfTokens),
          "Ether value sent is not correct"
        );
    
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 id = totalSupply().add(1);
          if (totalSupply() < MAX_TOKENS) {
            _presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, id);
            emit EmojiMinted(id, msg.sender);
          }
        }
      }
    
      function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
    
          _presaleList[addresses[i]] = true;
        }
      }
    
      function removeFromPresaleList(address[] calldata addresses)
        external
        onlyOwner
      {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
    
          _presaleList[addresses[i]] = false;
        }
      }
    
      function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMint = maxMint;
      }
    
      function onPreSaleList(address addr) external view returns (bool) {
        return _presaleList[addr];
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
    
        if (isRevealed == false) {
          return
            "ipfs://QmePkVnQq8S2AzuYriPbBzytMHEYJrBSK7aRkFLJyEvrMH/hidden.json";
        }
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
            
      }

      
    
      function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal 
        whenNotPaused 
        override(ERC721, ERC721Enumerable) 
      {
        super._beforeTokenTransfer(from, to, tokenId);

      }
    
      function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
      {
        return super.supportsInterface(interfaceId);
      }







    }
