// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
import "./ERC721Tradable.sol";
import "./Ownable.sol";

contract Color is ERC721Tradable {
    
    /**
     * @dev Enforce the existence of only 10,000 mintable colors during presale
     */
    uint256 public constant PRESALE_COLOR_SUPPLY = 10000;

    /**
     * @dev Enforce the existence of 16,777,216 total mintable colors
     */
    uint256 public constant REGULAR_SUPPLY = 16777216;

    bool public isPresaleActive = false;
    bool public isRegularSaleActive = false;

    uint public constant NUM_GIVEAWAYS = 20;
    uint public constant MAX_MINTABLE_COLORS = 20;

  constructor(address _proxyRegistryAddress) ERC721Tradable("NiftyPantone", "HEX", _proxyRegistryAddress) public {}

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

  function calculatePrice(uint currentSupply) public view returns (uint256) {
      if (currentSupply > 10000) {
          return 1000000000000000;          // 10000+     0.001 ETH
      } else if (currentSupply >= 9900) {
          return 800000000000000000;        // 9900-10000: 0.8 ETH
      } else if (currentSupply >= 9500) {
          return 400000000000000000;         // 9500-9899:  0.4 ETH
      } else if (currentSupply >= 7500) {
          return 200000000000000000;         // 7500-9499:  0.2 ETH
      } else if (currentSupply >= 3500) {
          return 80000000000000000;         // 3500-7999:  0.08 ETH
      } else if (currentSupply >= 1500) {
          return 40000000000000000;          // 1500-3499:  0.04 ETH 
      } else if (currentSupply >= 500) {
          return 20000000000000000;          // 500-1999:   0.02 ETH 
      } else if (currentSupply >= 200) {
          return 10000000000000000;          // 200 - 499     0.01 ETH
      } else {
          return 5000000000000000;          // 1 - 199     0.005 ETH
      }
  }

  function mintColor(uint256[] memory colorTokens) public payable {
      uint256 numColors = colorTokens.length;
      require(isPresaleActive || isRegularSaleActive, "Sale is not yet active");
      bool validPresale = isPresaleActive && totalSupply() <= PRESALE_COLOR_SUPPLY;
      bool validRegularSale = isRegularSaleActive && totalSupply() <= REGULAR_SUPPLY;

      require(validPresale || validRegularSale, "Sale has reached capacity");
      require(numColors > 0 && numColors <= MAX_MINTABLE_COLORS, "Can only mint minimum 1 color, maximum 20 colors at once");

      bool canMintPresale = isPresaleActive && totalSupply().add(numColors) <= PRESALE_COLOR_SUPPLY;
      bool canMintRegularSale = isRegularSaleActive && totalSupply().add(numColors) <= REGULAR_SUPPLY;

      require(canMintPresale || canMintRegularSale, "Number of colors exceeds supply");
      require(msg.value >= calculatePrice(totalSupply()).mul(numColors), "Ether sent is below minting price");

      for (uint i = 0; i < numColors; i++) {
          mintToken(msg.sender, colorTokens[i]);
      }
  }

  function mintToken(address _to, uint256 colorTokenId) private {
       _safeMint(_to, colorTokenId);
       _incrementTokenId();
  }

  function reserveGiveaway(uint256[] memory colorTokens, address to) public onlyOwner {
      uint256 numColors = colorTokens.length;
      require(totalSupply() <= NUM_GIVEAWAYS, "Exceeded giveaway budge");
      require(totalSupply().add(numColors) <= NUM_GIVEAWAYS, "Exceeded giveaway budget");
      require(isPresaleActive == false && isRegularSaleActive == false, "Sale has already begun");

      // Tokens reserved for team, people who helped this project and other giveaways
      for (uint i = 0; i < numColors; i++) {
          mintToken(to, colorTokens[i]);
      }
  }

  function revealTokenColor(uint256 tokenId, uint256 secret) external view returns (string memory) {
      return string(abi.encodePacked("#", HelperStrings.uint2hexstr(tokenId ^ secret)));
  } 

  function startPresale() public onlyOwner {
      isPresaleActive = true;
  }

  function pausePresale() public onlyOwner {
      isPresaleActive = false;
  }

  function endPresale() public onlyOwner {
      isPresaleActive = false;
      isRegularSaleActive = true;
  }

  function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
  }

  function baseTokenURI() override public pure returns (string memory) {
      return "https://api.niftypantone.com/api/color/";
  }

  function contractURI() public view returns (string memory) {
      return "https://api.niftypantone.com/api/niftypantone";
  }
}