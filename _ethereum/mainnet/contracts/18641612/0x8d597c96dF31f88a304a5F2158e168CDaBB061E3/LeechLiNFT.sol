// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./Math.sol";
import "./BitMaps.sol";
import "./AggregatorV3Interface.sol";

import "./Claimable.sol";

contract LeechLiNFT is 
  ERC721A,
  ERC2981,
  AccessControl,
  Ownable,
  Pausable,
  ReentrancyGuard,
  Claimable
{
  using BitMaps for BitMaps.BitMap;
  using Math for uint256;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  uint256 public maxSupply;

  string private baseUri;

  string private contractUri;

  address private paymentAddress;

  uint256 public stage;

  uint256 private slippage;

  BitMaps.BitMap private tokenTiers;

  mapping(uint256 => uint256) private tierPrice;

  mapping(uint256 => uint256) private tierSupply;

  mapping(uint256 => uint256) private tierMints;

  address internal priceFeedAddress;

  constructor(
    string memory _contractUri,
    string memory _baseUri,
    address _paymentAddress,
    uint96 _feeNumerator,
    address _priceFeedAddress
  )
    ERC721A("Leech Li NFT", "ROBBED") 
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setDefaultRoyalty(_paymentAddress, _feeNumerator);

    contractUri = _contractUri;
    baseUri = _baseUri;
    paymentAddress = _paymentAddress;
    priceFeedAddress = _priceFeedAddress;
    
    maxSupply = 2000;
    slippage = 100;
    tierPrice[0] = 5000000000;
    tierPrice[1] = 15000000000;
    tierSupply[0] = 1250;
    tierSupply[1] = 750;
  }

  /* ------------ User Operations ------------ */
  function mintTo(
    address _to,
    uint256 _tier,
    uint256 _quantity
  )
    public
    payable
    whenNotPaused
    nonReentrant
  {
    requireSaleOpen();
    requireValidTier(_tier);
    requireAvailableTokenSupply(_quantity);
    requireAvailableTierSupply(_tier, _quantity);

    uint256 price = _getMintFeeInETH(_tier, _quantity);
    uint256 payment = msg.value;

    if(payment < price) {
      revert InsufficientFee();
    }

    bool paid;
    address to = paymentAddress;
    assembly {
      paid := call(gas(), to, payment, 0, 0, 0, 0)
    }

    if(!paid) {
      revert UnableCollectFee();
    }

    _mint(_to, _tier, _quantity);
  }

  /* ------------ Public Operations ------------ */

  function tierOf(
    uint256 _tokenId
  )
    public
    view
    returns(uint256)
  {
    return tokenTiers.get(_tokenId) ? 1 : 0;
  }

  function getMintFee(
    uint256 _tier,
    uint256 _quantity
  ) 
    public
    view
    returns (uint256 usd, uint256 native)
  {
    usd = tierPrice[_tier];
    native = _getMintFeeInETH(_tier, _quantity).mulDiv(10000 + slippage, 10000);
  }

  function contractURI()
    public
    view
    returns (string memory)
  {
    return contractUri;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(AccessControl, ERC721A, ERC2981)
    returns (bool) 
  {
    return
      AccessControl.supportsInterface(interfaceId)
        || ERC2981.supportsInterface(interfaceId)
        || ERC721A.supportsInterface(interfaceId);
  }

  /* ------------ Management Operations ------------ */

  function setPaused(
    bool _paused
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setPaymentAddress(
    address _paymentAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    paymentAddress = _paymentAddress;
  }

  /**
  * @dev Withdraws the erc20 tokens or native coins from this contract.
  */
  function claimValues(address _token, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimValues(_token, _to);
  }

  /**
    * @dev Withdraw ERC721 or ERC1155 deposited for this contract
    * @param _token address of the claimed ERC721 token.
    * @param _to address of the tokens receiver.
    */
  function claimNFTs(address _token, uint256 _tokenId, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimNFTs(_token, _tokenId, _to);
  }

  function setContractUri(
    string calldata _contractUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    contractUri = _contractUri;
  }

  function setBaseUri(
    string calldata _baseUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _baseUri;
  }

  function setDefaultRoyalty(
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setStage(
    uint256 _stage
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    stage = _stage;
  }

  function setTierPrice(
    uint256 _tier,
    uint256 _price
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    requireValidTier(_tier);
    if(_price == 0) {
      revert InvalidPrice();
    }
    tierPrice[_tier] = _price;
  }

  function setSlippage(
    uint256 _slippage
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    slippage = _slippage;
  }

  function setMaxSupply(
    uint256 _supply
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_supply < _totalMinted()) {
      revert InvalidSupply();
    }
    maxSupply = _supply;
  }

  function setTierSupply(
    uint256 _tier,
    uint256 _supply
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    requireValidTier(_tier);
    if(_supply < tierMints[_tier]) {
      revert InvalidSupply();
    }
    if((maxSupply - tierSupply[_tier] + _supply) > maxSupply) {
      revert InvalidSupply();
    }
    tierSupply[_tier] = _supply;
  }

  function setPriceFeedAddress(
    address _priceFeedAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceFeedAddress = _priceFeedAddress;
  }

  function airdrop(
    address[] calldata _to,
    uint256 _tier,
    uint256 _quantity
  )
    external
    whenNotPaused
    onlyRole(MANAGER_ROLE)
  {
    requireValidTier(_tier);
    requireAvailableTokenSupply(_quantity * _to.length);
    requireAvailableTierSupply(_tier, _quantity * _to.length);
    
    for(uint256 i = 0; i < _to.length; i++) {
      _mint(_to[i], _tier, _quantity);
    }
  }

  /* ------------ Internal Operations/Modifiers ------------ */
  function _getMintFeeInETH(
    uint256 _tier,
    uint256 _quantity
  ) 
    internal
    view
    virtual
    returns (uint256)
  {
    return _getLatestPrice() * tierPrice[_tier] * _quantity;
  }

  function _getLatestPrice() 
    internal
    view
    virtual
    returns (uint256)
  {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return (10 ** 18 / uint256(price));
  }

  function _mint(
    address _to,
    uint256 _tier,
    uint256 _quantity
  )
    internal
  {
    uint256 startTokenId = _nextTokenId();

    _safeMint(_to, _quantity);

    if(_tier > 0) {
      for(uint256 tokenId = startTokenId; tokenId < _nextTokenId(); tokenId++) {
        tokenTiers.set(tokenId);
      }
    }
    tierMints[_tier] += _quantity;
  }

  function requireSaleOpen()
    view
    internal
  {
    if(stage == 0) {
      revert SaleIsClosed();
    }
  }

  function requireValidTier(
    uint256 _tier
  )
    pure
    internal
  {
    if(_tier > 1) {
      revert InvalidTier();
    }
  }

  function requireAvailableTokenSupply(
    uint256 _quantity
  )
    view
    internal
  {
    if(_totalMinted() + _quantity > maxSupply) {
      revert MaxSupplyExceeded();
    }
  }

  function requireAvailableTierSupply(
    uint256 _tier,
    uint256 _quantity
  )
    view
    internal
  {
    if(tierSupply[_tier] < tierMints[_tier] + _quantity) {
      revert MaxSupplyExceeded();
    }
  }

  function _startTokenId()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }

  function _baseURI()
    internal 
    view 
    override 
    returns (string memory)
  {
    return baseUri;
  }
  
  /* ----------- Errors ------------- */
  error InsufficientFee();
  error UnableCollectFee();
  error SaleIsClosed();
  error MaxSupplyExceeded();
  error InvalidTier();
  error InvalidSupply();
  error InvalidPrice();
}