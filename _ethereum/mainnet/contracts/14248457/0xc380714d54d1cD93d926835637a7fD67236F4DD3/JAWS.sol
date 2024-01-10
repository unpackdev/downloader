// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

JAWS NFT

https://jawsbtc.com/
https://twitter.com/JAWS_NFT
https://discord.gg/E6DAwFqfnx

High Level Overview:

'saleState()' indicates where we are in the mint process.  Check this variable and
the 'State' enum to find current status.

During the WhitelistSale, use 'mintWhitelist()' to mint tokens. This function 
requires a 'MintData' object (as parameter array in JavaScript), and a valid
MerkleProof array for the wallet of the msg.sender.

During the PublicSale, use 'mint()' to mint tokens. This function only requires
a 'MintData' object.

MintData example: mint([STYLE_JAWS,GENDER_FEMALE,1], overrides) 

The UI can use 'adminlist()' to enable or disable admin-specific
visual elements. The contract enforces access restrictions regardless of UI.

'getPrice()' 'MintData', and returns the unit price for that style.

*/

/// ----------------------------------------------------------------------------
/// Imports
/// ----------------------------------------------------------------------------
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Strings.sol";
import "./IERC20.sol";

import "./Adminlist.sol";

/// ----------------------------------------------------------------------------
/// Enums and Structs
/// ----------------------------------------------------------------------------

enum State {
  Uninitialized, 
  NotStarted,
  WhitelistSale,
  PublicSale,
  MintPaused,
  MintEnded
}

struct TokenStyleStruct {
  string className;
  uint16 start;    // class starting serial
  uint16 end;      // class end serial
  uint16 sold;     // sold
  uint256 price;   // price
  }

struct MintData {
  uint8 tokenStyle;
  uint8 gender;
  uint16 amount;
}

/// ----------------------------------------------------------------------------
/// Errors
/// ----------------------------------------------------------------------------
error InvalidToken();
error InvalidSaleState();  
error InvalidAmount();
error InvalidStyle();
error InvalidAddress();

error NotOnWhitelist();

error SupplyLimit();
error MintLimit();

error NotEnoughEther();

error TransferFailed();

contract JAWS is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard, Adminlist {

  using Strings for uint256;

  /// ------------------------------------------------------------------------
  /// Events
  /// ------------------------------------------------------------------------

  event SaleStateUpdated(State);
  event BaseURIUpdated(string);
  event WhitelistRootUpdated(bytes32);

  event JAWSMintEvent(address indexed minter, uint256 indexed tokenId, uint8 indexed style, uint8 gender);

  event OpenSeaProxyActiveUpdated(bool);


  /// ------------------------------------------------------------------------
  /// Variables
  /// ------------------------------------------------------------------------

  State public saleState = State.NotStarted;

  uint8 public constant WHITELIST_MINT_MAX = 5;
  uint16 public constant DISCOUNT_MINT_MAX = 777;
  uint256 public constant DISCOUNT = 0.05 ether;

  string private baseURI;
  mapping(uint8 => TokenStyleStruct) private mintStyle;

  bytes32 public whitelistRoot;
  mapping(address => uint16) public whitelistMinterBalance;

  uint8 public constant STYLE_FC = 1;
  uint8 public constant STYLE_HR = 2;
  uint8 public constant STYLE_JAWS = 3;

  uint8 public constant GENDER_FEMALE = 1;
  uint8 public constant GENDER_MALE = 2;

  address public immutable openSeaProxyRegistryAddress;
  bool public isOpenSeaProxyActive = true; 

  /// ------------------------------------------------------------------------
  /// Modifiers
  /// ------------------------------------------------------------------------

  modifier isWhitelistSaleActive() {
    if( saleState != State.WhitelistSale ) revert InvalidSaleState();
    _;
  }

  modifier isPublicSaleActive() {
    if( saleState != State.PublicSale ) revert InvalidSaleState();
    _;
  }

  modifier isValidAddress(address _addr) {
    if(_addr == address(0)) revert InvalidAddress();
    _;
  }

  modifier isValidToken(uint256 _id) {
    if(ownerOf(_id) == address(0)) revert InvalidToken();
    _;
  }
  modifier isValidStyle(uint8 _tokenStyle) {
    if( ( _tokenStyle != STYLE_FC ) &&( _tokenStyle != STYLE_HR ) && ( _tokenStyle != STYLE_JAWS ) ) revert InvalidStyle();
      _;
  }

  modifier isValidData(MintData  memory _data) {
    if( ( _data.tokenStyle != STYLE_HR ) && ( _data.tokenStyle != STYLE_JAWS ) ) revert InvalidStyle();
    if( _data.amount > ( getStyleTotal(_data.tokenStyle) - getStyleSold(_data.tokenStyle) ) ) revert SupplyLimit();
    _;
  }

  modifier isValidDataAdmin(MintData memory _data) {
    if( ( _data.tokenStyle != STYLE_FC ) &&( _data.tokenStyle != STYLE_HR ) && ( _data.tokenStyle != STYLE_JAWS ) ) revert InvalidStyle();
    if( _data.amount > ( getStyleTotal(_data.tokenStyle) - getStyleSold(_data.tokenStyle) ) ) revert SupplyLimit();
      _;
  }

  modifier isValidMerkleProof(bytes32[] calldata _proof, bytes32 _root) {
    if( !
        MerkleProof.verify(
          _proof,
          _root,
          keccak256(abi.encodePacked(msg.sender))
        )
      )
    revert NotOnWhitelist();
    _;
  }

  modifier SentEnoughEther( MintData memory _data ) {
    if( msg.value < ( getPrice(_data) * _data.amount ) ) revert NotEnoughEther();
    _;
  }

  /// ------------------------------------------------------------------------
  /// Functions
  /// ------------------------------------------------------------------------

  //  constructor() ERC721("JAWS", unicode"🦈") {
  constructor(address[] memory _adminlist, address _openSeaProxyRegistryAddress) ERC721("JAWS NFT", "JAWS") {

    // Deployer has Admin Rights
    _setupAdmin(msg.sender);

    // Add the other Admins
    uint16 length = uint16(_adminlist.length);
    for(uint16 i=0; i < length; i = uncheckedInc(i))
    {
        addAddressToAdminlist(_adminlist[i]);
    }

    // Set up OS Proxy for IsApprovedForAll
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;

    // Set up Token Ranges Ranges
    //                                        className       start end sold  price
    mintStyle[STYLE_FC] =   TokenStyleStruct("Founders Club", 1,    100,   0, 0 ether);
    mintStyle[STYLE_HR] =   TokenStyleStruct("High Rollers",  101,  2322,  0, 4 ether);
    mintStyle[STYLE_JAWS] = TokenStyleStruct("JAWS",          2323, 10099, 0, 0.15 ether);
  }

  function setSaleState(State _saleState)
    external
    onlyAdmin
  {
    saleState = _saleState;
    emit SaleStateUpdated(saleState);
  }

  function _setbaseURI(string memory _inputURI) 
    external
    onlyAdmin
  {
    baseURI = _inputURI;
    emit BaseURIUpdated(baseURI);
  }

  function _baseURI() 
    internal 
    view 
    override 
    returns (string memory) 
  {
    return baseURI;
  }

  function tokenURI(uint256 _id)
    public
    view
    override
    isValidToken(_id)
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
  }

  function contractURI()
    public
    view
    returns (string memory) 
  {
    return string(abi.encodePacked(baseURI, "contract.json"));
  }

  function setWhitelistRoot(bytes32 _whitelistRoot) 
    external
    onlyAdmin
  {
    whitelistRoot = _whitelistRoot;
    emit WhitelistRootUpdated(whitelistRoot);
  }

  // removed isValidData(_data) modifier since this function is also called from SentEnoughEther modifier
  // _data is checked in parent functions!  not checked here!
  function getPrice(
    MintData memory _data
  )
    public
    view
    returns (uint256)
  {
    uint256 price = 0;
    uint8 _tokenStyle = _data.tokenStyle;

    // there is a discount to the first DISCOUNT_MINT_MAX STYLE_JAWS mints during WhitelistSale
    //   this check intentionally allows a single overbuy at the end of discounted sale. Without this,
    //   we would require a permint mint quantity to proceed with undiscounted minted. This could
    //   be solved with additional complexity, but a couple extra discounted tokens to enable
    //   a smooth minting experience is a worthwhile tradeoff
    if( 
        ( saleState == State.WhitelistSale ) &&  
        ( _tokenStyle == STYLE_JAWS ) &&
        ( mintStyle[_tokenStyle].sold < DISCOUNT_MINT_MAX ) // allow a single overbuy at end of discounted sale
      )
    {
      price = mintStyle[_tokenStyle].price - DISCOUNT;
    }
    else
    {
      price = mintStyle[_tokenStyle].price;
    }
    return price;
  }

  function getStyleTotal(
    uint8 _tokenStyle
  )
    public
    view
    isValidStyle(_tokenStyle)
    returns (uint16)
  {
    return (mintStyle[_tokenStyle].end - mintStyle[_tokenStyle].start + 1);
  }

  function getStyleSold(
    uint8 _tokenStyle
  )
    public
    view
    isValidStyle(_tokenStyle)
    returns (uint16)
  {
    return mintStyle[_tokenStyle].sold;
  }

  function mint(
    MintData calldata _data
  ) 
    external
    payable
    isPublicSaleActive
    isValidData(_data)
    SentEnoughEther(_data)
  {
    _mintInternal(_data, msg.sender);
  }

  function mintWhitelist(
    MintData calldata  _data,
    bytes32[] calldata _proof
  ) 
    external
    payable
    isValidMerkleProof(_proof, whitelistRoot)
    isWhitelistSaleActive
    isValidData(_data)
    SentEnoughEther(_data)
  {
    _mintInternal(_data, msg.sender);
  }

  function mintAdmin(
    MintData calldata _data
  ) 
    external
    onlyAdmin
    isValidDataAdmin(_data)
  {
    _mintInternal(_data, msg.sender);
  }

	function mintAdminToTarget(
    MintData calldata _data,
    address _target
  ) 
    external
    onlyAdmin
    isValidDataAdmin(_data)
  {
    _mintInternal(_data, _target);
  }

  function _mintInternal(
    MintData memory _data,
    address _target
  )
    internal
    nonReentrant
  {
    uint16 currentMint = (mintStyle[_data.tokenStyle].start + mintStyle[_data.tokenStyle].sold);
    uint16 mintUntil = currentMint + _data.amount;

    mintStyle[_data.tokenStyle].sold += _data.amount;

    for(; currentMint < mintUntil; currentMint = uncheckedInc(currentMint) )
    {
      _safeMint(_target, currentMint);
      emit JAWSMintEvent(_target, currentMint, _data.tokenStyle, _data.gender);
    }
  }

  function withdraw()
    public
    onlyAdmin
  {
    // low level call to enable multisig access
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    if(!sent) revert TransferFailed();
  }

  function withdrawTokens(
    IERC20 token
  )
    public
    onlyAdmin 
  {
    bool sent = token.transfer(msg.sender, token.balanceOf(address(this)));
    if(!sent) revert TransferFailed();
  }

  /// ------------------------------------------------------------------------
  /// OpenSea ProxyRegistry
  /// ------------------------------------------------------------------------

  // function to disable gasless listings for security in case
  // opensea ever shuts down or is compromised
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
  {
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
    emit OpenSeaProxyActiveUpdated(isOpenSeaProxyActive);
  }

  /**
    * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool)
  {
    // Get a reference to OpenSea's proxy registry contract by instantiating
    // the contract using the already existing address.
    ProxyRegistry proxyRegistry = ProxyRegistry(
      openSeaProxyRegistryAddress
    );
    if(
      isOpenSeaProxyActive &&
      address(proxyRegistry.proxies(_owner)) == _operator
    ) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  /// ------------------------------------------------------------------------
  /// ERC2981
  /// ------------------------------------------------------------------------
  function royaltyInfo(uint256 _id, uint256 _salePrice)
    external
    view
    override
    isValidToken(_id)
    returns (address, uint256)
  {
    return ( address(this), ( (_salePrice * 25) / 1000) );
  }

  receive() external payable {}

  /// ------------------------------------------------------------------------
  /// ERC165
  /// ------------------------------------------------------------------------
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// ------------------------------------------------------------------------
  /// Utility
  /// ------------------------------------------------------------------------

  // https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc#the-increment-in-for-loop-post-condition-can-be-made-unchecked
  function uncheckedInc(uint16 _i)
    private
    pure 
  returns (uint16) {
    unchecked {
      return _i + 1;
    }
  }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

