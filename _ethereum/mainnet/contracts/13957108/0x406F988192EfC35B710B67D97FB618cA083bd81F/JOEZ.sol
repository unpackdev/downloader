// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

/**
 * @title Token contract for JOEZ NFTs
 * @dev This contract allows the distribution of
 * JOEZ NFTs in the form of a presale and main sale.
 *
     ██╗ ██████╗ ███████╗███████╗
     ██║██╔═══██╗██╔════╝╚══███╔╝
     ██║██║   ██║█████╗    ███╔╝ 
██   ██║██║   ██║██╔══╝   ███╔╝  
╚█████╔╝╚██████╔╝███████╗███████╗
 ╚════╝  ╚═════╝ ╚══════╝╚══════╝                                                        
 *
 * Smart contract work done by lenopix.eth
 */
contract JOEZ is
  ERC721Enumerable,
  Ownable,
  ReentrancyGuard
{
  using ECDSA for bytes32;
  using Address for address;

  // Minting constants
  uint256 public maxMintMainSale;
  uint256 public maxMintPreSale;
  uint256 public TOTAL_SUPPLY;
  uint256 public constant LEGENDARY_COUNT = 12;
  uint256 public constant COMPANY_RESERVE = 50;

  // Current price: 0.069
  uint256 public mintPrice = 69000000000000000;

  // Sale toggles
  bool private _isPresaleActive = false;
  bool private _isSaleActive = false;

  // Presale
  mapping(address => bool) public boughtPresale;
  mapping(address => bool) public boughtMainsale;

  address private signVerifier = 0x296f841B9b37aD28F2D40d17b22719BCCd773eC1;

  // Base URI
  string private _uri;

  uint256 private _lastTokenId = 1 + COMPANY_RESERVE + LEGENDARY_COUNT;
  uint256 private _lastReserveTokenId = 1;
  uint256 private reserveMintCount = 0;

  constructor(
    uint256 totalSupply,
    uint256 presaleMaxMint,
    uint256 mainsaleMaxMint
  ) ERC721("JOEZ NFT", "JOEZ") {
    TOTAL_SUPPLY = totalSupply;
    maxMintPreSale = presaleMaxMint;
    maxMintMainSale = mainsaleMaxMint;
  }

  // @dev Returns the enabled/disabled status for presale
  function getPreSaleState() external view returns (bool) {
    return _isPresaleActive;
  }

  // @dev Returns the enabled/disabled status for minting
  function getSaleState() external view returns (bool) {
    return _isSaleActive;
  }

  // @dev Allows to set the baseURI dynamically
  // @param uri The base uri for the metadata store
  function setBaseURI(string memory uri) external onlyOwner {
    _uri = uri;
  }

  // @dev Sets a new signature verifier
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  // @dev Dynamically set the max mints a user can do in the main sale
  function setMaxMintPerMainSale(uint256 maxMint) external onlyOwner {
    maxMintMainSale = maxMint;
  }

  // @dev Dynamically set the max mints a user can do in the pre sale
  function setMaxMintPerPreSale(uint256 maxMint) external onlyOwner {
    maxMintPreSale = maxMint;
  }

  // @dev Dynamically set the price of mint if needed
  function setMintPrice(uint256 cost) external onlyOwner {
    mintPrice = cost;
  }

  // @dev Private mint function to mint legendaries and company reserve
  // NOTE: This function must be called before presale and mainsale
  function mintLegendariesAndReserve(uint256 mintCount) 
  external onlyOwner {
    require((reserveMintCount + mintCount) <= LEGENDARY_COUNT + COMPANY_RESERVE);
    reserveMintCount += mintCount;
    _mintReserveTokens(msg.sender, mintCount);
  }

    // Presale
    // @dev Presale Mint
    // @param tokenCount The tokens a user wants to purchase
    // @param presaleMaxMint The max tokens a user can mint from the presale
    // @param sig Server side signature authorizing user to use the presale
    function mintPresale(
        uint256 tokenCount, 
        bytes memory sig
    ) external nonReentrant payable {
        require(_isPresaleActive, "Presale not active");
        require(!_isSaleActive, "Cannot mint while main sale is active");
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= maxMintPreSale, "Token count exceeds limit");
        require((mintPrice * tokenCount) == msg.value, "ETH sent does not match required payment");
        require(!boughtPresale[msg.sender], "Can only buy in presale once");
        
        // Verify signature
        bytes32 message = getPresaleSigningHash(msg.sender, tokenCount).toEthSignedMessageHash();
        require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");

        boughtPresale[msg.sender] = true;

        // Mint
        _mintTokens(msg.sender, tokenCount);
    }

  // @dev Main sale mint
  // @param tokensCount The tokens a user wants to purchase
  function mint(uint256 tokenCount)
    external
    payable
    nonReentrant
  {
    require(_isSaleActive, "Sale not active");
    require(tokenCount > 0, "Must mint at least 1 token");
    require(tokenCount <= maxMintMainSale, "Token count exceeds limit");
    require(!boughtMainsale[msg.sender], "Can only buy in mainsale once");

    require(
      (mintPrice * tokenCount) == msg.value,
      "ETH sent does not match required payment"
    );

    boughtMainsale[msg.sender] = true;

    _mintTokens(msg.sender, tokenCount);
  }

  // @dev Allows to enable/disable minting of presale
  function flipPresaleState() external onlyOwner {
    _isPresaleActive = !_isPresaleActive;
  }

  // @dev Allows to enable/disable minting of main sale
  function flipSaleState() external onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function getPresaleSigningHash(
    address sender,
    uint256 tokenCount
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(sender, tokenCount)
      );
  }

  function _baseURI() internal view override returns (string memory) {
    return _uri;
  }

  function _mintTokens(
    address recipient,
    uint256 tokenCount
  ) private {
    require((_lastTokenId + tokenCount) <= 1 + TOTAL_SUPPLY, "Cannot purchase more than the available supply");

    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 tokenId = _lastTokenId + i;
      _safeMint(recipient, tokenId);
    }

    _lastTokenId += tokenCount;
  }

    function _mintReserveTokens(
    address recipient,
    uint256 tokenCount
  ) private {
    require((_lastReserveTokenId + tokenCount) <= 1 + LEGENDARY_COUNT + COMPANY_RESERVE, "Cannot purchase more than the available supply");

    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 tokenId = _lastReserveTokenId + i;
      _safeMint(recipient, tokenId);
    }

    _lastReserveTokenId += tokenCount;
  }
}
