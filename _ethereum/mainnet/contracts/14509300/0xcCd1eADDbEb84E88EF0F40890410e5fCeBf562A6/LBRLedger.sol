// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enum.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ILBRLedger.sol";

/**
 * @title LBR Ledger minting contract
 * @author Maxwell J. Rux
 */
contract LBRLedger is
  ERC721Enum,
  Ownable,
  ReentrancyGuard,
  PaymentSplitter,
  ILBRLedger
{
  using Counters for Counters.Counter;
  using Strings for uint256;

  string private _uri;
  string private _contractURI;
  uint256 private _price = 0.08 ether;
  uint256 private constant MAX_SUPPLY = 5000;
  uint256 private constant MAX_MULTIMINT = 25;
  uint256 private constant MAX_RESERVED_SUPPLY = 250;

  // number of NFTs in reserve that have already been minted
  Counters.Counter private _reserved;

  bool _status = false;

  constructor(
    string memory __uri,
    address[] memory payees,
    uint256[] memory shares,
    string memory _name,
    string memory _symbol
  ) ERC721M(_name, _symbol) PaymentSplitter(payees, shares) {
    _uri = __uri;
  }

  /**
   * @dev Mint an LBR Ledger NFT
   * @param numMints Number of mints
   */
  function mint(uint256 numMints) external payable override nonReentrant {
    require(_status, 'LBRLedger: Sale is paused');
    require(
      msg.value >= price() * numMints,
      'LBRLedger: Not enough ether sent'
    );
    require(
      totalSupply() + numMints <= MAX_SUPPLY,
      'LBRLedger: New mint exceeds maximum supply'
    );
    require(
      totalSupply() + numMints <=
        MAX_SUPPLY - MAX_RESERVED_SUPPLY + _reserved.current(),
      'LBRLedger: New mint exceeds maximum available supply'
    );
    require(
      numMints <= MAX_MULTIMINT,
      'LBRLedger: Exceeds max mints per transaction'
    );

    uint256 tokenIndex = totalSupply();
    for (uint256 i = 0; i < numMints; ++i) {
      _safeMint(msg.sender, tokenIndex + i);
    }
    delete tokenIndex;
  }

  /**
   * @dev Mints reserved NFTs to an address other than the sender. Sender must be owner
   * @param numMints Number of mints
   * @param recipient Recipient of new mints
   */
  function mintReservedToAddress(uint256 numMints, address recipient)
    external
    onlyOwner
  {
    require(
      totalSupply() + numMints <= MAX_SUPPLY,
      'LBRLedger: New mint exceeds maximum supply'
    );
    require(
      _reserved.current() + numMints <= MAX_RESERVED_SUPPLY,
      'LBRLedger: New mint exceeds reserve supply'
    );
    uint256 tokenIndex = totalSupply();
    for (uint256 i = 0; i < numMints; ++i) {
      _reserved.increment();
      _safeMint(recipient, tokenIndex + i);
    }
    delete tokenIndex;
  }

  /**
   * @dev Mints reserved NFTs to the sender. Sender must be owner
   * @param numMints Number of mints
   */
  function mintReserved(uint256 numMints) external onlyOwner {
    require(
      totalSupply() + numMints <= MAX_SUPPLY,
      'LBRLedger: New mint exceeds maximum supply'
    );
    require(
      _reserved.current() + numMints <= MAX_RESERVED_SUPPLY,
      'LBRLedger: New mint exceeds reserve supply'
    );
    uint256 tokenIndex = totalSupply();
    for (uint256 i = 0; i < numMints; ++i) {
      _reserved.increment();
      _safeMint(msg.sender, tokenIndex + i);
    }
    delete tokenIndex;
  }

  /**
   * @dev Sets base uri used for tokenURI. Sender must be owner
   * @param __uri The new uri to set base uri to
   */
  function setBaseURI(string memory __uri) external onlyOwner {
    _uri = __uri;
  }

  /**
   * @dev Sets price per mint. Sender must be owner
   * @param __price New price
   */
  function setPrice(uint256 __price) external onlyOwner {
    _price = __price;
  }

  /**
   * @dev Changes sale state to opposite of what it was previously. Sender must be owner
   */
  function flipSaleState() external onlyOwner {
    _status = !_status;
  }

  function setContractURI(string memory __contractURI) external onlyOwner {
    _contractURI = __contractURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function price() public view override returns (uint256) {
    return _price;
  }

  function reserved() public view override returns (uint256) {
    return _reserved.current();
  }

  function baseURI() public view override returns (string memory) {
    return _uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _uri;
  }
}
