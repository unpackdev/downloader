// SPDX-License-Identifier: MIT
    import "./ERC721.sol";
    import "./Ownable.sol";
    import "./SafeMath.sol";
    import "./ERC721Enumerable.sol";
    
    pragma solidity ^0.8.4;
    pragma abicoder v2;
    
    contract PlanetOfTheGorillas is ERC721, Ownable, ERC721Enumerable {
      using SafeMath for uint256;
      using Strings for uint256;
    
      // Blockchain Developer = Kadir CELIK

      uint256 public constant tokenPrice = 120000000000000000; // 0.12 ETH 
      uint256 public constant maxTokenPurchase = 5;
      uint256 public constant MAX_TOKENS = 8888;
      address public constant TEAM_ADDRESS = 0x15bd1e900D9900191f26235A1ac25cB454c53F97;
      uint public TEAM_FEE = 60;
      uint constant SHARE_SUM = 100;
      string internal baseURI = ""; // IPFS URI WILL BE SET AFTER ALL TOKENS SOLD OUT
      string internal externalURI = "";

      bool public saleIsActive = false;
      bool public presaleIsActive = false;
      bool public isRevealed = false;
      bool public isUrlRevealed = false;
    
      mapping(address => bool) private _presaleList;
      mapping(address => uint256) private _presaleListClaimed;
    
      uint256 public presaleMaxMint = 3;
    
      event Minted(uint256 tokenId, address owner);
    
      constructor() ERC721("PlanetOfTheGorillas", "POG") {}
    
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }

      function _externalURI() internal view virtual  returns (string memory) {
        return externalURI;
      }
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
      }

      function setRevealedBaseURI(string memory _newBaseURI) public onlyOwner {
        externalURI = _newBaseURI;
      }
    
      function withdrawAll() public payable onlyOwner {

        uint256 balance = address(this).balance;
        uint toTeam = (balance * TEAM_FEE) / SHARE_SUM;
        payable(TEAM_ADDRESS).transfer(toTeam);
        uint toOwner = balance - (toTeam);
        payable(msg.sender).transfer(toOwner);

     
      }
    
      function reveal() public onlyOwner {
        isRevealed = true;
      }

      function urlReveal() public onlyOwner {
        isUrlRevealed = true;
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
    
      function mint(uint256 numberOfTokens) external payable {
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
            emit Minted(id, msg.sender);
          }
        }
      }
    
      function presaleGorillas(uint256 numberOfTokens) external payable {
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
            emit Minted(id, msg.sender);
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
          string memory newBaseURI = _externalURI();
          string memory currentBaseURI = _baseURI();
        
        if (isRevealed == false) {
          return
            "ipfs://QmWLyvxdHPqmKUxAj8GeCYCg4u9uNQbBAsbvkf9mWvthRL/hidden.json";
        }
        else if (isUrlRevealed == false) {
          return
          bytes(newBaseURI).length > 0
            ? string(abi.encodePacked(newBaseURI, tokenId.toString(), ".json"))
            : "";
        }
        else{
          return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
        }
            
      }
    
      function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
      ) internal override(ERC721, ERC721Enumerable) {
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