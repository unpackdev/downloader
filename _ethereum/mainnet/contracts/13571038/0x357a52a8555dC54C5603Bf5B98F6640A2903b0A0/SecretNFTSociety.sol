// SPDX-License-Identifier: MIT
// https://secretnftsociety.com

// It was all a meme.
//
// Secret NFT Society NFTs are authentic pieces of
// on-chain artwork with unique combinations of color,
// style, and fun collectible "Cool S" cool points.
//
// Stats and other utility are intentionally omitted for others to interpret.
// Cool S points have no inherent utility or value, they're just cool.

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./CoolS.sol";

string constant DESCRIPTION = "The Secret NFT Society has a fixed total supply of 42,069 collectibles associated with varying levels of Cool S points. Stats and other utility are intentionally omitted for others to interpret. Cool S points have no inherent utility or value, they're just cool.";

contract SecretNFTSociety is ERC721Enumerable, Ownable {
  /**
   * Token IDs counter.
   *
   * Provides an auto-incremented ID for each token minted.
   */
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;

  address private _S;
  uint private _generation;
  uint private _freq;
  uint private constant _totalSupply = 42069;

  mapping(uint => uint) private _generations;
  mapping(uint => bool) private _leaders;
  mapping(address => uint) private _claimable;
  string[] private _tags = [
    "Dope",
    "Chill",
    "Noice",
    "Fire",
    "Swag",
    "Yeet",
    "Hype",
    "Lit",
    "Fam",
    "Vibes",
    "Based",
    "Whale",
    "Ape"
  ];

  /**
   * Base fee
   *
   * Defines the base fee for the artwork.
   */
  uint private _baseFee;

  /**
   * Contract URI
   *
   * Defines the contract metadata URI.
   */
  string private _contractURI;

  /**
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory __contractURI,
    uint __freq,
    uint __baseFee
  ) ERC721(_name, _symbol) {
    _contractURI = __contractURI;
    _freq = __freq;
    _baseFee = __baseFee;
  }

  /**
   * Contract metadata URI
   *
   * Provides the URI for the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked('ipfs://', _contractURI));
  }

  /**
   * Get the mint fee.
   *
   * Fee to mint.
   */
  function mintFee() public view returns (uint) {
    return _baseFee;
  }

  /**
   * Get image
   *
   * Returns the image for a tokenID.
   */
  function getImage(uint _tokenID) public view returns (string memory) {
    uint r1 = uint256(keccak256(abi.encode(_tokenID))) % 360;
    uint r2 = (r1 + 180) % 360;
    uint r3 = uint256(keccak256(abi.encode(_tokenID, 2))) % 360;
    uint r4 = (r3 + 180) % 360;

    bytes memory out = abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><style>.',
      _leaders[_tokenID] ? 'g1' : 'f2',
      '{fill:url(#g1)}.g2{fill:url(#g2)}.f1{fill:#000}.f2{fill:#fff}</style><linearGradient id="g1" gradientTransform="rotate(45)"><stop offset="50%" stop-color="hsl(',
      Strings.toString(r1),
      ', 100%, 50%)"/><stop offset="100%" stop-color="hsl(',
      Strings.toString(r2),
      ', 100%, 50%)"/></linearGradient><linearGradient id="g2" gradientTransform="rotate(45)"><stop offset="50%" stop-color="hsl(',
      Strings.toString(r3),
      ', 100%, 50%)"/><stop offset="100%" stop-color="hsl(',
      Strings.toString(r4),
      ', 100%, 50%)"/></linearGradient>');
    out = abi.encodePacked(
      out,
      '<rect width="100" height="100" fill="url(#',
      _leaders[_tokenID] ? 'g1' : 'f2',
      ')"/><polygon clasas="f1" points="31.2,50 50,12.5 68.8,50 "/><path class="',
      _leaders[_tokenID] ? 'g2' : 'f2',
      '" d="M50,48.4l-5.1-5v-6.1l2-2.4l-2-2.4v-6.1l5.1-5l5,5v6.1l-0.2,0.2l-1.7,2.2l1.9,2.4l0,6.1L50,48.4z M46.4,42.9 l3.6,3.6l3.6-3.6l0-5l-4.3-5.3v-5.8h1.4V32l1.5,1.8l1.4-1.8v-5L50,23.5L46.4,27v5l4.3,5.3v5.8h-1.4v-5.3l-1.5-1.8l-1.5,1.8V42.9z"/><polygon class="f1" points="12.5,87.5 31.2,50 50,87.5 "/><path class="',
      _leaders[_tokenID] ? 'g2' : 'f2',
      '" d="M31.3,85.9l-5.1-5v-6.1l2-2.4l-2-2.4v-6.1l5.1-5l5,5v6.1l-0.2,0.2l-1.7,2.2l1.9,2.4l0,6.1L31.3,85.9z M27.6,80.4l3.6,3.6l3.6-3.6l0-5L30.5,70v-5.8H32v5.3l1.5,1.8l1.4-1.8v-5L31.3,61l-3.6,3.6v5l4.3,5.3v5.8h-1.4v-5.3l-1.5-1.8 l-1.5,1.8V80.4z"/><polygon class="f1" points="50,87.5 68.8,50 87.5,87.5 "/><path class="',
      _leaders[_tokenID] ? 'g2' : 'f2',
      '" d="M68.8,85.9l-5.1-5v-6.1l2-2.4l-2-2.4v-6.1l5.1-5l5,5v6.1l-0.2,0.2l-1.7,2.2l1.9,2.4l0,6.1L68.8,85.9z M65.1,80.4l3.6,3.6l3.6-3.6l0-5L68,70v-5.8h1.4v5.3l1.5,1.8l1.4-1.8v-5L68.8,61l-3.6,3.6v5l4.3,5.3v5.8H68v-5.3l-1.5-1.8l-1.5,1.8 V80.4z"/><text x="50%" y="61%" dominant-baseline="middle" text-anchor="middle" style="font-weight:700;font-size:4.5px">MEMBER</text><text x="50%" y="68%" dominant-baseline="middle" text-anchor="middle" style="font-weight:700;font-size:4px">',
      Strings.toString(_tokenID),
      '</text></svg>'
    );
    return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(out))));
  }

  /**
   * Token URI
   * Returns a base-64 encoded SVG.
   */
  function tokenURI(uint256 _tokenID) override public view returns (string memory) {
    require(_tokenID <= _tokenIDs.current(), "Token doesn't exist.");

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name":"Secret NFT Society #',
      Strings.toString(_tokenID),
      '","description":"',
      DESCRIPTION,
      '","image":"',
      getImage(_tokenID),
      '","attributes":[{"trait_type":"Generation","value":"',
      Strings.toString(_generations[_tokenID]),
      '"}',
      _leaders[_tokenID]
        ? string(abi.encodePacked(',{"value":"',_tags[_generations[_tokenID] % _tags.length],'"}'))
        : '',
      ']}'
    ))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /**
   * Mint To
   *
   * Requires payment of _mintFee.
   */
  function mintTo(address _to) public payable returns (uint) {
    require(_tokenIDs.current() < _totalSupply, "Max supply reached.");

    uint fee = mintFee();
    if (fee > 0) {
      require(msg.value >= fee, "Requires minimum fee.");

      payable(owner()).transfer(fee);

      uint change = msg.value - fee;
      if (change > 0) payable(msg.sender).transfer(change);
    }

    if (_leaders[_tokenIDs.current()]) {
      _generation++;
    }

    _tokenIDs.increment();
    uint tokenID = _tokenIDs.current();
    _generations[tokenID] = _generation;
    _mint(_to, tokenID);
    if (tokenID % _freq == 0) _increaseCollectibleGeneration();
    _claimable[ownerOf(_tokenIDs.current())] += 42069 ether * 10 * (_generation+1);

    return tokenID;
  }

  /**
   * Claimable
   *
   * Returns the amount claimable of cool points.
   */
  function claimable(address _claimer) public view returns (uint) {
    return _claimable[_claimer];
  }

  /**
   * Claim
   *
   * Mints S tokens.
   */
  function claim() public {
    uint amt = _claimable[msg.sender];
    if (amt == 0) return;

    CoolSV2 s = CoolSV2(_S);
    s.mint(msg.sender, amt);
    s.mint(owner(), amt);

    _claimable[msg.sender] = 0;
  }

  /**
   * Mint
   *
   * Requires payment of _mintFee.
   */
  function mint() public payable returns (uint) {
    return mintTo(msg.sender);
  }

  /**
   * Increment generation.
   *
   * Increases collectibles generation number.
   */
  function _increaseCollectibleGeneration() private {
    uint256 levelUp = uint256(keccak256(abi.encode(_tokenIDs.current(), block.timestamp, block.difficulty, blockhash(block.number))));
    _leaders[_tokenIDs.current()] = (levelUp % _freq) == 0;
  }

  /**
   * Admin function: Update base fee.
   *
   * Updates the base fee scalar.
   */
  function adminUpdateBaseFee(uint _newBaseFee) public onlyOwner {
    _baseFee = _newBaseFee;
  }

  /**
   * Admin function: Update frequency
   *
   * Updates the generation frequency.
   */
  function adminUpdateFreq(uint _newFreq) public onlyOwner {
    _freq = _newFreq;
  }

  /**
   * Admin function: Update S token address.
   *
   * Sets the Cool S token address a single time only.
   */
  function adminUpdateSAddress(address _newS) public onlyOwner {
    if (_S == address(0)) _S = _newS;
  }
}
