// SPDX-License-Identifier: MIT

//   ________                            
//  /  _____/___________    ______ ______
// /   \  __\_  __ \__  \  /  ___//  ___/
// \    \_\  \  | \// __ \_\___ \ \___ \ 
//  \______  /__|  (____  /____  >____  >
//         \/           \/     \/     \/ 

pragma solidity >0.6.2;
import "./ERC721Tradable.sol";
import "./Ownable.sol";

contract Grass is ERC721Tradable {
    using SafeMath for uint256;
    
    /**
     * @dev Enforce the existence of only 1,000 mintable grass
     */
    uint256 public constant MAX_GRASS_SUPPLY = 1000;
    uint256 public constant GRASS_PRICE = 30000000000000000; // 0.03 ETH

    bool public isSaleActive = false;
    string public PROVENANCE_HASH = "";

    uint public constant MAX_MINTABLE_GRASS = 20;
    uint public constant MAX_GIVEAWAY_GRASS = 20;

    uint private totalGiveawayCount = 0;

  constructor(address _proxyRegistryAddress) ERC721Tradable("Grass", "GRASS", _proxyRegistryAddress) public {}

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
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

  function mintGrass(uint256 numGrass) public payable {
      require(isSaleActive, "Sale is not yet active");
      require(numGrass > 0 && numGrass <= MAX_MINTABLE_GRASS, "Can only mint minimum 1 grass, maximum 20 grass at once");
      require(totalSupply().add(numGrass) <= MAX_GRASS_SUPPLY, "Number of grass exceeds total grass supply");

      uint256 numMintedTokens = getLastMintedTokenCount(); // last token count      
      uint256 mintingPrice = GRASS_PRICE.mul(numGrass);
      require(msg.value >= mintingPrice, "Ether sent is below minting price");

      for (uint i = 0; i < numGrass; i++) {
          mintToken(msg.sender);
      }
  }

  function mintToken(address _to) private {
      uint256 nextTokenId = _getNextTokenCount();
       _safeMint(_to, nextTokenId);
       _incrementTokenCount();
  }

  function reserveGiveaway(uint256 numGrass, address to) public onlyOwner {
      require(totalSupply().add(numGrass) <= MAX_GRASS_SUPPLY, "Number of grass exceeds total grass supply");
      require(totalGiveawayCount.add(numGrass) <= MAX_GIVEAWAY_GRASS, "Number of grass exceeds giveaway allowance");
      // Tokens reserved for team, people who helped this project and other giveaways
      for (uint i = 0; i < numGrass; i++) {
          mintToken(to);
      }
      totalGiveawayCount += numGrass;
  }
  
  function flipSaleState() public onlyOwner {
      isSaleActive = !isSaleActive;
  }

  function setProvenanceHash (string memory _hash) public onlyOwner {
      PROVENANCE_HASH = _hash;
  }

  function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
  }

  function baseTokenURI() override public pure returns (string memory) {
      return "https://api.grassnfts.com/api/grass/";
  }

  function contractURI() public view returns (string memory) {
      return "https://api.grassnfts.com/api/grassNFT";
  }
}