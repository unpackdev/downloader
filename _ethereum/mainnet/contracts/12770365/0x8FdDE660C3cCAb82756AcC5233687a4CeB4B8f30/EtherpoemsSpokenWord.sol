// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EtherpoemsSpokenWord is ERC721, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(string => uint256) public myTokenURI;
  mapping(string => Poem) public poemIDNFIDMap; // poem hash id to token id map
  mapping(uint256 => Poem) public poems;
  mapping(uint256 => uint256) public EtherpomsNFTClaimed;

  uint256 public constant MAX_NFT_SUPPLY = 732;
  uint256 public currentPrice = 420000000000000000; // .42 ETH
  address internal paymentSplitter;

  bool private reentrancyLock = false;

  struct Poem {
    uint256 tokenID;
    string name;
    string text;
    string author;
    string id;
    string tokenURI;
    bool minted;
  }

  event TokenBought(
    string id,
    uint256 mintedTokenID,
    string poemName,
    string poemText,
    string author,
    string tokenURI
  );

  modifier reentrancyGuard {
    if (reentrancyLock) {
      revert();
    }
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

  constructor(address _paymentSplitter)
    public
    ERC721("EtherpoemsSpokenWord", "ETHPSW")
  {
    paymentSplitter = _paymentSplitter;
  }

  function mint(
    string memory _poemID,
    string memory _myTokenURI,
    string memory _poemName,
    string memory _poemText,
    string memory _poemAuthor
  ) external payable reentrancyGuard {
    // Validate token to be minted
    _validateTokenToBeMinted(_myTokenURI, _poemID);
    require(getNFTPrice() == msg.value, "Ether value sent is not correct");
    // Split payment with Authors
    (bool sent, ) = paymentSplitter.call{ value: msg.value }("");
    require(sent, "Failed to send Ether to payment splitter.");
    // Mint the token
    _mint(_poemID, _myTokenURI, _poemName, _poemText, _poemAuthor);
  }

  function _mint(
    string memory _poemID,
    string memory _myTokenURI,
    string memory _poemName,
    string memory _poemText,
    string memory _poemAuthor
  ) internal {
    // mark token URI as minted
    myTokenURI[_myTokenURI] = 1;
    // new token id
    uint256 newItemId = _tokenIds.current();
    // save poem hash id to token id mapping
    // save poem on chain
    poems[newItemId].tokenID = newItemId;
    poems[newItemId].text = _poemText;
    poems[newItemId].name = _poemName;
    poems[newItemId].author = _poemAuthor;
    poems[newItemId].id = _poemID;
    poems[newItemId].tokenURI = _myTokenURI;
    poems[newItemId].minted = true;
    // map poem id to NF struct
    poemIDNFIDMap[_poemID] = poems[newItemId];
    // mint token && assign ownership of token to msg.sender
    _safeMint(msg.sender, newItemId);
    // emit TokenBought event
    emit TokenBought(
      _poemID,
      newItemId,
      _poemName,
      _poemText,
      _poemAuthor,
      _myTokenURI
    );
    // increment token counter for sold token
    _tokenIds.increment();
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

    return poems[tokenId].tokenURI;
  }

  // The owner can mint without paying
  function ownerMint(
    string memory _poemID,
    string memory _myTokenURI,
    string memory _poemName,
    string memory _poemText,
    string memory _poemAuthor
  ) external reentrancyGuard onlyOwner {
    _validateTokenToBeMinted(_myTokenURI, _poemID);
    _mint(_poemID, _myTokenURI, _poemName, _poemText, _poemAuthor);
  }

  function _validateTokenToBeMinted(
    string memory _myTokenURI,
    string memory _poemID
  ) internal view {
    require(_tokenIds.current() < MAX_NFT_SUPPLY, "Sale has already ended.");
    require(myTokenURI[_myTokenURI] != 1, "Token URI is already minted.");
    require(poemIDNFIDMap[_poemID].minted != true, "Poem is already minted.");
  }

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function getPoem(uint256 _tokenID) public view returns (string memory) {
    require(_tokenID <= _tokenIds.current());
    return (poems[_tokenID].text);
  }

  function getName(uint256 _tokenID) public view returns (string memory) {
    require(_tokenID <= _tokenIds.current());
    return (poems[_tokenID].name);
  }

  function getAuthor(uint256 _tokenID) public view returns (string memory) {
    require(_tokenID <= _tokenIds.current());
    return (poems[_tokenID].author);
  }

  function getPoemIDNFID(string memory _poemID) public view returns (uint256) {
    require(
      poemIDNFIDMap[_poemID].minted,
      "Given Etherpoem id is not yet minted."
    );
    return poemIDNFIDMap[_poemID].tokenID;
  }

  function getNFTPrice() public view returns (uint256) {
    return currentPrice;
  }

  function setNFTPrice(uint256 _currentPrice) external onlyOwner {
    currentPrice = _currentPrice;
  }

  receive() external payable {}
}
