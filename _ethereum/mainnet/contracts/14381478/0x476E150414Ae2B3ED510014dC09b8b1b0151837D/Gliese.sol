    // SPDX-License-Identifier: MIT
    import "./ERC721.sol";
    import "./Ownable.sol";
    import "./SafeMath.sol";
    import "./ERC721Enumerable.sol";
    
    pragma solidity ^0.8.4;
    pragma abicoder v2;
    
    contract TheGliese is ERC721, Ownable, ERC721Enumerable {
      using SafeMath for uint256;
      using Strings for uint256;
    
      uint256 public constant tokenPrice = 100000000000000000; // 0.1 ETH 
      uint256 public constant maxTokenPurchase = 5;
      uint256 public constant MAX_TOKENS = 10000;
    
      string public baseURI = ""; // IPFS URI WILL BE SET AFTER ALL TOKENS SOLD OUT
    
      bool public saleIsActive = false;      
      bool public isRevealed = false;
      address private constant ONE = 0x52bee1d34A881E286533FE8B010610ED35C29756;
      address private constant TWO = 0xFa58DEdA93751C075021A03c901c27C123Da0AE6;      
      uint256 public devReserve = 50;    
      event GlieseMinted(uint256 tokenId, address owner);
    
      constructor() ERC721("TheGliese", "GLES") {}
    
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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
    
      function mintGliese(uint256 numberOfTokens) external payable {
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
            emit GlieseMinted(id, msg.sender);
          }
        }
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
            "ipfs://QmerJvb5j5JRbX57SSLjoK9zir8SyjHNhYfPcXs35trPy3?filename=hidden.json";
        }
    
        return
          bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";            
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
      function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(ONE, (balance*85)/100);
        _withdraw(TWO, (balance*15)/100);       
    }
    
     function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

     // contract can recieve Ether
     fallback() external payable { }
     receive() external payable { }
    }
