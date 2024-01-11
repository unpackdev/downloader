 // SPDX-License-Identifier: MIT
    import "./ERC721.sol";
    import "./Ownable.sol";
    import "./SafeMath.sol";
    import "./ERC721Enumerable.sol";
    
    pragma solidity ^0.8.4;
    pragma abicoder v2;

//                           __,='`````'=/__
//                          '//  (o) \(o) \ `'         _,-,
//                          //|     ,_)   (`\      ,-'`_,-\
//                       ,-~~~\  `'==='  /-,      \==```` \__
//                       /        `----'     `\     \       \/
//                    ,-`                  ,   \  ,.-\       \
//                   /      ,               \,-`\`_,-`\_,..--'\
//                  ,`    ,/,              ,>,   )     \--`````\
//                  (      `\`---'`  `-,-'`_,<   \      \_,.--'`
//                   `.      `--. _,-'`_,-`  |    \
//                    [`-.___   <`_,-'`------(    /
//                   (`` _,-\   \ --`````````|--`
//                     >-`_,-`\,-` ,          |
//                   <`_,'     ,  /\          /
//                    `  \/\,-/ `/  \/`\_/V\_/
//                       (  ._. )    ( .__. )
//                       |      |    |      |
//                        \,---_|    |_---./
//                        ooOO(_)    (_)OOoo
    
    
    
    
    
    
    
    
    contract Ogre is ERC721, Ownable, ERC721Enumerable {
      using SafeMath for uint256;
      using Strings for uint256;
    
      uint256 public constant tokenPrice = 8000000000000000; // 0.008 ETH 
      uint256 public constant maxTokenPurchase = 10;
      uint256 public constant MAX_TOKENS = 4000;
      uint256 public constant FREE_MINTS = 1000;
    
      string public baseURI = "";
      string public hiddenURI = ""; 
    
      bool public isSaleActive = false;
      bool public isRevealed = false;
      uint256 public devReserve = 3;
    
      event OgreMinted(uint256 tokenId, address owner);
    
      constructor() ERC721("Ogre", "TT") {}
    
      function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }
      function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenURI;
      }
    
      function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
      }
      function setHiddenURI(string memory _newHiddenURI) public onlyOwner {
        hiddenURI = _newHiddenURI;
      }
    
      function Withdraw() public payable onlyOwner {
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
          "Dev reserve depleted"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
          uint256 id = totalSupply().add(1);
          _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
      }
    
      function activateSale() external onlyOwner {
        isSaleActive = !isSaleActive;
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
    
      function mintOgre(uint256 numberOfTokens) external payable {
        require(isSaleActive, "Sale must be active to mint.");
        require(
          numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
          "Can't mint zero."
        );
        require(
          totalSupply().add(numberOfTokens) <= MAX_TOKENS,
          "Exceeds max mint per purchase"
        );
    
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 id = totalSupply().add(1);
          if(totalSupply() <= FREE_MINTS){
             _safeMint(msg.sender, id);
            emit OgreMinted(id, msg.sender);
          }else{
          require(
          msg.value >= tokenPrice.mul(numberOfTokens),
          "Invalid ETH sent."
        );
          if (totalSupply() < MAX_TOKENS) {
            _safeMint(msg.sender, id);
            emit OgreMinted(id, msg.sender);
          }
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
        string memory currentHiddenURI = _hiddenURI();
    
        if (isRevealed == false) {
          return
            currentHiddenURI;
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
    }

