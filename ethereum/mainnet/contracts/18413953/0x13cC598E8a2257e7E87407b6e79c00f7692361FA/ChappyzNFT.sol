// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IAccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./AggregatorV3Interface.sol";

import "./DefaultOperatorFilterer721.sol";
import "./ContextMixin.sol";
import "./Claimable.sol";

contract ChappyzNFT is 
  ERC721A,
  ERC2981,
  AccessControl,
  DefaultOperatorFilterer721,
  ContextMixin,
  Ownable,
  Pausable,
  Claimable,
  ReentrancyGuard
{
  using Math for uint256;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  string private baseUri;

  address private stableCoinAddress;

  address private priceFeedAddress;

  address private proxyRegistryAddress;

  string private contractUri;

  address private feeAddress;

  uint256 private slippage;

  uint256 private mintFee;

  uint256 public maxSupply;

  uint256 public stage;

  constructor(
    string memory _contractUri,
    string memory _baseUri,
    address _feeAddress,
    uint96 _feeNumerator
  )
    ERC721A("Chappyz NFT", "CHAPPYZNFT") 
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MANAGER_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setDefaultRoyalty(_feeAddress, _feeNumerator);

    contractUri = _contractUri;
    baseUri = _baseUri;
    feeAddress = _feeAddress;
    slippage = 300;
    maxSupply = 125000;
    mintFee = 8880000;

    stableCoinAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    priceFeedAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  }

  /* ------------ User Operations ------------ */
  function mintWithUSDC(
    address _to,
    uint256 _quantity
  )
    public
    whenNotPaused
    nonReentrant
  {
    requireSaleOpen();
    requireAvailableTokenSupply(_quantity);

    uint256 fee = getMintFeeInUSDC(_quantity);
    IERC20 usdc = IERC20(stableCoinAddress);

    bool paid = usdc.transferFrom(
      _msgSender(),
      feeAddress,
      fee
    );

    if(!paid) {
      revert UnableCollectFee();
    }

    _safeMint(_to, _quantity);
  }

  function mintWithETH(
    address _to,
    uint256 _quantity
  )
    public
    payable
    whenNotPaused
    nonReentrant
  {
    requireSaleOpen();
    requireAvailableTokenSupply(_quantity);

    uint256 fee = _getMintFeeInETH(_quantity);
    uint256 value = msg.value;

    if(value < fee) {
      revert InsufficientFee();
    }

    bool paid;
    address to = feeAddress;
    assembly {
      paid := call(gas(), to, value, 0, 0, 0, 0)
    }

    if(!paid) {
      revert UnableCollectFee();
    }

    _safeMint(_to, _quantity);
  }

  /* ------------ Public Operations ------------ */

  function contractURI()
    public
    view
    returns (string memory)
  {
    return contractUri;
  }

  function _baseURI() 
    internal 
    view 
    override 
    returns (string memory)
  {
    return baseUri;
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

  function setFeeAddress(
    address _feeAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feeAddress = _feeAddress;
  }

  function setContractURI(
    string calldata _contractUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    contractUri = _contractUri;
  }

  function setBaseURI(
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

  function deleteDefaultRoyalty()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  function resetTokenRoyalty(
    uint256 tokenId
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _resetTokenRoyalty(tokenId);
  }

  function setStage(
    uint256 _stage
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    stage = _stage;
  }

  function setMintFee(
    uint256 _mintFee
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    mintFee = _mintFee;
  }

  function setStableCoinAddress(
    address _stableCoinAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    stableCoinAddress = _stableCoinAddress;
  }

  function setPriceFeedAddress(
    address _priceFeedAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceFeedAddress = _priceFeedAddress;
  }

  function setProxyRegistryAddress(
    address _proxyRegistryAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function setSlippage(
    uint256 _slippage
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    slippage = _slippage;
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

  function airdrop(
    address[] calldata _to,
    uint256 _quantity
  )
    external
    whenNotPaused
    nonReentrant
    onlyRole(MINTER_ROLE)
  {
    requireAvailableTokenSupply(_quantity * _to.length);
    
    for(uint256 i = 0; i < _to.length; i++) {
      _safeMint(_to[i], _quantity);
    }
  }

  /* ------------ Internal Operations/Modifiers ------------ */
  function _msgSender()
    internal
    override
    view
    returns (address sender)
  {
    return ContextMixin.msgSender();
  }

  function requireSaleOpen()
    view
    internal
  {
    if(stage == 0) {
      revert SaleIsClosed();
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

  function _startTokenId()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }

  /* ------------ OpenSea Overrides --------------*/
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    payable
    override 
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) 
    public
    payable
    override 
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    payable
    override
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function isApprovedForAll(
    address _owner, 
    address _operator
  )
    override
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    if (proxyRegistryAddress == _operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
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

  function getMintFeeInUSDC(
    uint256 _quantity
  ) 
    public
    view
    returns (uint256)
  {
    return mintFee * _quantity;
  }

  function _getMintFeeInETH(
    uint256 _quantity
  ) 
    internal
    view
    virtual
    returns (uint256)
  {
    return _getLatestPrice() * mintFee * (10 ** 2) * _quantity;
  }

  function getMintFeeInETH(
    uint256 _quantity
  ) 
    public
    view
    returns (uint256)
  {
    return _getMintFeeInETH(_quantity).mulDiv(10000 + slippage, 10000);
  }

  /* ----------- Errors ------------- */
  error InsufficientFee();
  error UnableCollectFee();
  error SaleIsClosed();
  error MaxSupplyExceeded();
}