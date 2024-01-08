//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BoozyBadgers is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public constant R = "Built by 0xShock. twitter.com/0xShock";
  uint public constant PROMO_SUPPLY = 99; // reserved for promotions
  uint public constant PRESALE_SUPPLY = 500; // presale before the big day
  uint public constant PUBLIC_SUPPLY = 9400; // availabe for public mint
  uint public constant MAX_SUPPLY = 9999; // Total supply available
  uint public constant PRICE = 0.04 ether;

  string private _baseTokenURI;

  bool public isMintLive = false;
  bool public isPresaleLive = false;

  uint private _numberPromoSent = 0; // promotions sent out / pre-minted
  uint private _numberPresaleMinted = 0; // number of tokens from the presale.
  uint private _numberMinted = 0;

  constructor() ERC721("Boozy Badgers", "BOOZE") {}

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    // NOTE ensure baseURI has a trailing / at the end because it'll have the tokenId appended.
      _baseTokenURI = baseURI;
  }

  function baseTokenURI() public view returns (string memory) {
      return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    // Before the baseURI has been changed, we'll use this default teaser metadata.
    if( bytes(baseURI).length == 0 ){
        return "https://gateway.pinata.cloud/ipfs/QmPhQ1yrC5UxYRFRNL13FexPaLku4YzhE8QCCG5DZ6G26X";
    }
    // At reveal time, update baseURI to the actual IPFS url that has the tokenId at the end and that'll
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function beginMint() public onlyOwner {
      isMintLive = true;
  }

  function endMint() public onlyOwner {
      isMintLive = false;
  }

  function beginPresale() public onlyOwner {
      isPresaleLive = true;
  }

  function endPresale() public onlyOwner {
      isPresaleLive = false;
  }

  function mint(uint256 numTokens) public payable {
    // 1. Validate we haven't exceeded supply, obviously.
    require((totalSupply() + numTokens) <= (PUBLIC_SUPPLY + PRESALE_SUPPLY) , "Exceeds maximum token supply.");
    // Have to mint at least one but not more than 20.
    require(numTokens > 0 && numTokens <= 20, "Cannot exceed 20. Don't be greedy.");
    // Make sure the correct amount was paid.
    require(msg.value >= (PRICE * numTokens), "Amount of Ether sent is not correct.");
    // Uhh...let's make sure the mint has started.
    require(isMintLive == true, "Mint is not live. Be patient.");

    // Mint it!
    for (uint i = 0; i < numTokens; i++) {
      uint mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
      _numberMinted += 1;
    }
  }

  function mintPresale(uint256 numTokens) public payable {
    // 1. Validate we haven't exceeded supply, obviously.
    require((_numberPresaleMinted + numTokens) <= PRESALE_SUPPLY , "Exceeds maximum token supply.");
    // Have to mint at least one but not more than 20.
    require(numTokens > 0 && numTokens <= 20, "Cannot exceed 20. Don't be greedy.");
    // Make sure the correct amount was paid.
    require(msg.value >= (PRICE * numTokens), "Amount of Ether sent is not correct.");
    // Uhh...let's make sure the mint has started.
    require(isPresaleLive == true, "Mint is not live. Be patient.");

    // Mint it!
    for (uint i = 0; i < numTokens; i++) {
      uint mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
      _numberPresaleMinted += 1;
    }
  }

  // Let's do some minting for promotional supply.
  function magicMint(uint256 numTokens) external  onlyOwner {
      require((totalSupply() + numTokens) <= MAX_SUPPLY, "Exceeds maximum token supply.");
      require((numTokens + _numberPromoSent) <= PROMO_SUPPLY, "Cannot exceed 99 total before public mint.");

      for (uint i = 0; i < numTokens; i++) {
          uint mintIndex = totalSupply();
          _safeMint(msg.sender, mintIndex);
          _numberPromoSent += 1;
      }
  }

  // Airdrop to allow for sending direct to some addresses
  function airdrop( address [] memory recipients ) public onlyOwner {
    require((totalSupply() + recipients.length) <= MAX_SUPPLY, "Exceeds maximum token supply.");
    require((recipients.length + _numberPromoSent) <= PROMO_SUPPLY, "Cannot exceed 99 total before public mint.");

    for(uint i ; i < recipients.length; i++ ){
        uint mintIndex = totalSupply();
        _safeMint(recipients[i], mintIndex);
        _numberPromoSent += 1;
    }
  }

  function numberPromoSent() public view returns( uint ){
    return _numberPromoSent;
  }
}