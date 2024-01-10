// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Strings.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

import "./ERC721BURIBase.sol";
import "./ERC721BURIContract.sol";

error NoBaseURI();
error SaleStarted();
error InvalidProof();
error SaleNotStarted();
error AlreadyRedeemed();
error InvalidRecipient();
error WhitelistNotStarted();

contract GratitudeGang is
  Ownable,
  ReentrancyGuard,
  ERC721BURIBase,
  ERC721BURIContract
{
  using Strings for uint256;
  using SafeMath for uint256;

  // ============ Constants ============

  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  
  //max amount that can be minted in this collection
  uint16 public constant MAX_SUPPLY = 2222;
  //maximum amount that can be purchased per wallet
  uint8 public constant MAX_PURCHASE = 5;
  //the whitelist price per token
  uint256 public constant WHITELIST_PRICE = 0.05 ether;
  //the sale price per token
  uint256 public constant SALE_PRICE = 0.08 ether;

  // ============ Storage ============

  //the offset to be used to determine what token id should get which 
  //CID in some sort of random fashion. This is kind of immutable as 
  //it's only set in `widthdraw()`
  uint16 public indexOffset;

  //mapping of address to amount minted
  mapping(address => uint256) public minted;
  //mapping of token id to custom uri
  mapping(uint256 => string) public customURI;
  //mapping of ambassador address to whether if they redeemed already
  mapping(address => bool) public ambassadors;

  //the preview uri json
  string public previewURI;
  //flag for if the whitelist sale has started
  bool public whitelistStarted;
  //flag for if the sales has started
  bool public saleStarted;

  // ============ Deploy ============

  /**
   * @dev Initializes ERC721B
   */
  constructor(
    string memory uri,
    string memory preview
  ) ERC721B("Gratitude Gang", "GRATITUDE") {
    _setContractURI(uri);
    previewURI = preview;
    _safeMint(owner(), 1);

  }

  // ============ Read Methods ============

  /** 
   * @dev ERC165 bytes to add to interface array - set in parent contract
   *  implementing this standard
   * 
   *  bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
   *  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
   *  _registerInterface(_INTERFACE_ID_ERC2981);
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    if (!_exists(_tokenId)) revert NonExistentToken();
    return (
      payable(owner()), 
      _salePrice.mul(1000).div(10000)
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns(bool)
  {
    //support ERC2981
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Combines the base token URI and the token CID to form a full 
   * token URI
   */
  function tokenURI(uint256 tokenId) 
    public view virtual override returns(string memory) 
  {
    if (!_exists(tokenId)) revert NonExistentToken();

    //if there is a custom URI
    if (bytes(customURI[tokenId]).length > 0) {
      //return that
      return customURI[tokenId];
    }

    //if no offset
    if (indexOffset == 0) {
      //use the placeholder
      return previewURI;
    }

    //for example, given offset is 2 and size is 8:
    // - token 5 = ((5 + 2) % 8) + 1 = 8
    // - token 6 = ((6 + 2) % 8) + 1 = 1
    // - token 7 = ((7 + 2) % 8) + 1 = 2
    // - token 8 = ((8 + 2) % 8) + 1 = 3
    uint256 index = tokenId.add(indexOffset).mod(MAX_SUPPLY).add(1);
    //ex. https://ipfs.io/Qm123abc/ + 1000 + .json
    return string(
      abi.encodePacked(baseTokenURI(), index.toString(), ".json")
    );
  }
  
  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view returns (uint256) {
    return lastTokenId();
  }

  // ============ Write Methods ===========

  /**
   * @dev Allows anyone to get a token that was approved by the owner
   */
  function authorize(uint256 quantity, bytes memory proof) 
    external payable 
  {
    address recipient = _msgSender();
    //make sure recipient is a valid address
    if (recipient == address(0)) revert InvalidRecipient();
    //has the whitelist sale started?
    if (!whitelistStarted) revert WhitelistNotStarted();
    //has the sale started?
    if (saleStarted) revert SaleStarted();

    //make sure the minter signed this off
    if (ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked("authorized", recipient))
      ),
      proof
    ) != owner()) revert InvalidProof();
  
    if (quantity == 0 
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || quantity.add(minted[recipient]) > MAX_PURCHASE
      //the value sent should be the price times quantity
      || quantity.mul(WHITELIST_PRICE) > msg.value
      //the quantity being minted should not exceed the max supply
      || (lastTokenId() + quantity) > MAX_SUPPLY
    ) revert InvalidAmount();

    minted[recipient] += uint8(quantity);
    _safeMint(recipient, quantity);
  }

  /**
   * @dev Creates a new token for the `recipient`. Its token ID will be 
   * automatically assigned (and available on the emitted 
   * {IERC721-Transfer} event)
   */
  function mint(uint256 quantity) external payable {
    address recipient = _msgSender();
    //make sure recipient is a valid address
    if (recipient == address(0)) revert InvalidRecipient();
    //has the sale started?
    if(!saleStarted) revert SaleNotStarted();
  
    if (quantity == 0 
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || quantity.add(minted[recipient]) > MAX_PURCHASE
      //the value sent should be the price times quantity
      || quantity.mul(SALE_PRICE) > msg.value
      //the quantity being minted should not exceed the max supply
      || (lastTokenId() + quantity) > MAX_SUPPLY
    ) revert InvalidAmount();

    minted[recipient] += uint8(quantity);
    _safeMint(recipient, quantity);
  }

  /**
   * @dev Allows an ambassador to redeem their tokens
   */
  function redeem(
    address recipient,
    string memory uri, 
    bool ambassador, 
    bytes memory proof
  ) external virtual {
    //check to see if they redeemed already
    if(ambassadors[recipient] != false) revert AlreadyRedeemed();

    //make sure the owner signed this off
    if (ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(
          "redeemable", 
          uri, 
          recipient, 
          ambassador
        ))
      ),
      proof
    ) != owner()) revert InvalidProof();

    uint256 nextTokenId = lastTokenId() + 1;

    //if ambassador
    if (ambassador) {
      //mint token
      _safeMint(recipient, 1);
    } else { //they are apart of the founding team
      _safeMint(recipient, 4);
    }

    //add custom uri, so we know what token to customize
    customURI[nextTokenId] = uri;
    //flag that an ambassador/founder has redeemed
    ambassadors[recipient] = true;
  }

  // ============ Owner Methods ===========

  /**
   * @dev Sets the base URI for the active collection
   */
  function setBaseURI(string memory uri) public virtual onlyOwner {
    _setBaseURI(uri);
  }

  /**
   * @dev Sets the base URI for the active collection
   */
  function startSale(bool start) public virtual onlyOwner {
    saleStarted = start;
  }

  /**
   * @dev Sets the base URI for the active collection
   */
  function startWhitelist(bool start) public virtual onlyOwner {
    whitelistStarted = start;
  }

  /**
   * @dev Allows the proceeds to be withdrawn. This also releases the  
   * collection at the same time to discourage rug pulls 
   */
  function withdraw() external virtual onlyOwner nonReentrant {
    //cannot withdraw without setting a base URI first
    if (bytes(_baseURI()).length == 0) revert NoBaseURI();

    //set the offset
    if (indexOffset == 0) {
      indexOffset = uint16(block.number - 1) % MAX_SUPPLY;
      if (indexOffset == 0) {
        indexOffset = 1;
      }
    }

    payable(_msgSender()).transfer(address(this).balance);
  }

  // ============ Internal Methods ===========

  /**
   * @dev Describes linear override for `_baseURI` used in 
   * both `ERC721B` and `ERC721BURIBase`
   */
  function _baseURI() 
    internal 
    view 
    virtual 
    override(ERC721B, ERC721BURIBase) 
    returns (string memory) 
  {
    return super._baseURI();
  }
}