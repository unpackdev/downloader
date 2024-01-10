// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//   ____           _   _ _             _      
//  / ___|_ __ __ _| |_(_) |_ _   _  __| | ___ 
// | |  _| '__/ _` | __| | __| | | |/ _` |/ _ \
// | |_| | | | (_| | |_| | |_| |_| | (_| |  __/
//  \____|_|  \__,_|\__|_|\__|\__,_|\__,_|\___|
//
// A collection of 2,222 unique Non-Fungible Power SUNFLOWERS living in 
// the metaverse. Becoming a GRATITUDE GANG NFT owner introduces you to 
// a FAMILY of heart-centered, purpose-driven, service-oriented human 
// beings.
//
// https://www.gratitudegang.io/
//

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SafeMath.sol";
import "./ECDSA.sol";

import "./ERC721BBaseTokenURI.sol";
import "./ERC721BContractURIStorage.sol";

contract GratitudeGang is
  Ownable,
  ReentrancyGuard,
  ERC721BBaseTokenURI,
  ERC721BContractURIStorage
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
  uint16 public randomizer;
  //mapping of address to amount minted
  mapping(address => uint256) public minted;
  //mapping of token id to custom uri
  mapping(uint256 => string) public ambassadorURI;
  //mapping of ambassador address to whether if they redeemed already
  mapping(address => bool) public ambassadors;

  //the preview uri json
  string public previewURI;
  //flag for if the whitelist sale has started
  bool public whitelistStarted;
  //flag for if the sales has started
  bool public saleStarted;
  //a flag that allows NFTs to be listed on marketplaces
  //this helps to prevent people from listing at a lower
  //price during the whitelist
  bool approvable = false;

  // ============ Modifier ============

  modifier canApprove {
    if (!approvable) revert InvalidCall();
    _;
  }

  // ============ Deploy ============

  /**
   * @dev Sets contract URI, preview URI, mints 30 to the owner for giveaways
   */
  constructor(string memory uri, string memory preview) {
    _setContractURI(uri);
    previewURI = preview;
    _safeMint(owner(), 30);
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() external pure returns(string memory) {
    return "Gratitude Gang";
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() external pure returns(string memory) {
    return "GRATITUDE";
  }

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
    public view override returns(bool)
  {
    //support ERC721
    return interfaceId == type(IERC721Metadata).interfaceId
      //support ERC2981
      || interfaceId == _INTERFACE_ID_ERC2981
      //support other things
      || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Combines the base token URI and the token CID to form a full 
   * token URI
   */
  function tokenURI(uint256 tokenId) 
    public view override returns(string memory) 
  {
    if (!_exists(tokenId)) revert NonExistentToken();

    //if there is a custom URI
    if (bytes(ambassadorURI[tokenId]).length > 0) {
      //return that
      return ambassadorURI[tokenId];
    }

    //if no offset
    if (randomizer == 0) {
      //use the placeholder
      return previewURI;
    }

    //for example, given offset is 2 and size is 8:
    // - token 5 = ((5 + 2) % 8) + 1 = 8
    // - token 6 = ((6 + 2) % 8) + 1 = 1
    // - token 7 = ((7 + 2) % 8) + 1 = 2
    // - token 8 = ((8 + 2) % 8) + 1 = 3
    uint256 index = tokenId.add(randomizer).mod(MAX_SUPPLY).add(1);
    //ex. https://ipfs.io/Qm123abc/ + 1000 + .json
    return string(
      abi.encodePacked(baseTokenURI(), index.toString(), ".json")
    );
  }

  // ============ Write Methods ===========

  /**
   * @dev Allows anyone to get a token that was approved by the owner
   */
  function authorize(bytes memory proof) 
    external payable 
  {
    address recipient = _msgSender();
    //make sure recipient is a valid address
    if (recipient == address(0)) revert InvalidCall();
    //has the whitelist sale started?
    if (!whitelistStarted) revert InvalidCall();
    //has the sale started?
    if (saleStarted) revert InvalidCall();

    //make sure the minter signed this off
    if (ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked("authorized", recipient))
      ),
      proof
    ) != owner()) revert InvalidCall();
  
    //can only mint 1 during the whitelist
    if (minted[recipient] > 0
      //the value sent should be equal or more than the whitelist price
      || WHITELIST_PRICE > msg.value
      //the quantity being minted should not exceed the max supply
      || (totalSupply() + 1) > MAX_SUPPLY
    ) revert InvalidCall();

    minted[recipient] = 1;
    _safeMint(recipient, 1);
  }

  /**
   * @dev Creates a new token for the `recipient`. Its token ID will be 
   * automatically assigned (and available on the emitted 
   * {IERC721-Transfer} event)
   */
  function mint(uint256 quantity) external payable {
    address recipient = _msgSender();
    //make sure recipient is a valid address
    if (recipient == address(0)) revert InvalidCall();
    //has the sale started?
    if(!saleStarted) revert InvalidCall();
  
    if (quantity == 0 
      //the quantity here plus the current amount already minted 
      //should be less than the max purchase amount
      || quantity.add(minted[recipient]) > MAX_PURCHASE
      //the value sent should be the price times quantity
      || quantity.mul(SALE_PRICE) > msg.value
      //the quantity being minted should not exceed the max supply
      || (totalSupply() + quantity) > MAX_SUPPLY
    ) revert InvalidCall();

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
    if(ambassadors[recipient] != false) revert InvalidCall();

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
    ) != owner()) revert InvalidCall();

    uint256 nextTokenId = totalSupply() + 1;

    //if ambassador
    if (ambassador) {
      //mint token
      _safeMint(recipient, 1);
    } else { //they are apart of the founding team
      _safeMint(recipient, 4);
    }

    //add custom uri, so we know what token to customize
    ambassadorURI[nextTokenId] = uri;
    //flag that an ambassador/founder has redeemed
    ambassadors[recipient] = true;
  }

  // ============ Approval Methods ===========

  /**
   * @dev Check if can approve before approving
   */
  function approve(address to, uint256 tokenId) 
    public virtual override canApprove 
  {
    super.approve(to, tokenId);
  }

  /**
   * @dev Check if can approve before approving
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override canApprove
  {
    super.setApprovalForAll(operator, approved);
  }

  // ============ Owner Methods ===========

  /**
   * @dev Sets the base URI for the active collection
   */
  function setBaseURI(string memory uri) external onlyOwner {
    _setBaseURI(uri);
  }

  /**
   * @dev Sets the base URI for the active collection
   */
  function startSale(bool start) external onlyOwner {
    saleStarted = start;
  }

  /**
   * @dev Sets the base URI for the active collection
   */
  function startWhitelist(bool start) external onlyOwner {
    whitelistStarted = start;
  }

  /**
   * @dev Allows the proceeds to be withdrawn. This also releases the  
   * collection at the same time to discourage rug pulls. You can now
   * list these NFTs for sale on marketplaces.
   */
  function withdraw() external onlyOwner nonReentrant {
    //cannot withdraw without setting a base URI first
    if (bytes(baseTokenURI()).length == 0) revert InvalidCall();

    //set the randomizer, it's only here we will 
    //set this so it's kind of immutable (a one time deal)
    if (randomizer == 0) {
      randomizer = uint16(block.number - 1) % MAX_SUPPLY;
      if (randomizer == 0) {
        randomizer = 1;
      }
    }

    //now make approvable, it's only here we will 
    //set this so it's kind of immutable (a one time deal)
    if (!approvable) {
      approvable = true;
    }

    payable(_msgSender()).transfer(address(this).balance);
  }
}