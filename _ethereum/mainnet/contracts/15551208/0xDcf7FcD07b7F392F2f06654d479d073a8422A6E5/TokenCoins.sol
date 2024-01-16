// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * NFT tokens contract, with:
 * - Defined max total supply
 * - All created tokens will have the same owner (until transfered).
 * - Tokens are minted via populeTokens() method (executed only once)
 * - No token mint/burn after population is possible
 */
contract TokenCoins is ERC721, Ownable {

  bool private _COINS_MINTED = false;
  uint256 private constant _MAX_SUPPLY = 2500;
  uint256 private _LAST_INDEX = 0;
  string internal _BASE_URI;
  address public Owner;

  modifier _ownerOnly {
    require(msg.sender == Owner, "Ownable: caller is not the owner");
    _;
  }

  /**
    * Sets name, symbol and baseUri
    */
  constructor() ERC721("Token-Coins", "TC") {
    _BASE_URI = "https://ipfs.io/ipfs/bafybeihyslzcjrjvqark7vhbxn6dwh4kge2xilmqqyfbomsnaaolcq4diy/";
    Owner = msg.sender;
  }

  /**
    * Used to generate the tokenURI dynamically (baseUri + tokenId), so not gas spended
    */
  function _baseURI() internal view override returns (string memory) {
    return _BASE_URI;
  }

  /**
    * Overrided function, in order to return the .json extension (since I upload a dir)
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

    string memory base = _baseURI();
    string memory tokenIdString = Strings.toString(tokenId);
    string memory extension = ".json";

    return string(abi.encodePacked(base, tokenIdString, extension));
  }

  /**
    * Since I'm using a HTTP provider for the ipfs content, I can replace it here in case it's down (for whatever reasons)
    */
  function setBaseURI(string memory newBaseURI) public _ownerOnly {
    _BASE_URI = newBaseURI;
  }

  /**
    * Mint all the tokens, using the contract owner as the NFT owner, minting process is divided, to avoid transaction being interrupted
    */
  function populateTokensSlice(uint256 slice) public _ownerOnly {
    require(_COINS_MINTED == false, "Coins were already minted, can't mint more");

    uint256 tempLimit = _LAST_INDEX + slice;
    if (tempLimit >= _MAX_SUPPLY) {
      tempLimit = _MAX_SUPPLY;
    }

    for (_LAST_INDEX; _LAST_INDEX < tempLimit; _LAST_INDEX++) {
      _safeMint(msg.sender, _LAST_INDEX);
    }

    if (tempLimit == _MAX_SUPPLY) {
      _COINS_MINTED = true;
    }
  }
}
