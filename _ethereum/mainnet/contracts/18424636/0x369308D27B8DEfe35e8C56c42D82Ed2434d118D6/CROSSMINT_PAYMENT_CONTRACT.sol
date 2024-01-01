// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";

import "./IMINT_CONTRACT.sol";

/**
 * - Support Royalty(https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Royalty)
 * - AccessControl
 * - Burnable
 *
 * NOTE: Inintialized by https://wizard.openzeppelin.com/#erc721
 */
contract CROSSMINT_PAYMENT_CONTRACT is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  ERC721RoyaltyUpgradeable,
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable,
  IMINT_CONTRACT,
  ERC2771ContextUpgradeable,
  ReentrancyGuardUpgradeable
{
  bytes32 private constant CONTRACT_TYPE = bytes32('CROSSMINT_PAYMENT_CONTRACT');

  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant ROYALTY_ROLE = keccak256('ROYALTY_ROLE');
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 public constant TRUSTED_FORWARDER_ROLE = keccak256('TRUSTED_FORWARDER_ROLE');

  struct Sale {
      uint8 saleType; // constant 1: private sale 1, 2: private sale 2, 3: public sale
      uint256 price;
      uint256 maxQuantity;
      uint256 startAt;
      uint256 endAt;
      mapping(address => bool) allowList;
      mapping(address => uint256) quantityList;
      bool exists;
  }
  mapping(uint8 => Sale) private sales;
  uint8 public constant SALE_TYPE_PRIVATE1 = 1;
  uint8 public constant SALE_TYPE_PRIVATE2 = 2;
  uint8 public constant SALE_TYPE_PUBLIC = 3;

  uint256 private maxSupply;

  string private baseURI_;

  event SoldItems(
    uint8 indexed saleType,
    address indexed wallet,
    uint256 indexed quantity
  );

   /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() ERC2771ContextUpgradeable(address(0)) {
    _disableInitializers();
  }

  function initialize(string memory _name, string memory _symbol) external initializer {
    require(bytes(_name).length > 0);
    require(bytes(_symbol).length > 0);

    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init();
    __ERC721Burnable_init();
    __ERC721Royalty_init();

    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControlEnumerable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER_ROLE, _msgSender());
    _grantRole(PAUSER_ROLE, _msgSender());
    _grantRole(ROYALTY_ROLE, _msgSender());
    _grantRole(OPERATOR_ROLE, _msgSender());

    baseURI_ = "";
  }

  /**
   * @dev Returns the type of the contract
   */
  function contractType() external pure override returns (bytes32) {
    return CONTRACT_TYPE;
  }

  ////////////////////
  // Mint

  /**
   * @dev Miting NFT
   *
   * Requirements:
   *
   * - Message sender must have `MINTER_ROLE`
   */
    function mint(address[] calldata addresses) public onlyRole(MINTER_ROLE) whenNotPaused
    {
        require(totalSupply() + addresses.length <= maxSupply, "Mint would exceed max supply of NFTs");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], totalSupply() + 1);
        }
    }

    function buyPresale1(address recipient, uint256 quantity) public payable whenNotPaused
    {
        require(quantity > 0, "Must mint at least one NFT");
        require(sales[SALE_TYPE_PRIVATE1].quantityList[recipient] + quantity <= sales[SALE_TYPE_PRIVATE1].maxQuantity, "Cannot mint more than maxQuantity NFTs");
        require(totalSupply() + quantity <= maxSupply, "Purchase would exceed max supply of NFTs");
        require(msg.value == sales[SALE_TYPE_PRIVATE1].price * quantity, "Ether value sent is not correct");
        require(sales[SALE_TYPE_PRIVATE1].allowList[recipient] == true, "Not in private sale list");
        require(_isSaleOngoing(SALE_TYPE_PRIVATE1) == true, "The sale is not ongoing");
        
        sales[SALE_TYPE_PRIVATE1].quantityList[recipient] = sales[SALE_TYPE_PRIVATE1].quantityList[recipient] + uint8(quantity);

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, totalSupply() + 1);
        }

        emit SoldItems(SALE_TYPE_PRIVATE1, recipient, quantity);
    }

    function buyPresale2(address recipient, uint256 quantity) public payable whenNotPaused
    {
        require(quantity > 0, "Must mint at least one NFT");
        require(sales[SALE_TYPE_PRIVATE2].quantityList[recipient] + quantity <= sales[SALE_TYPE_PRIVATE2].maxQuantity, "Cannot mint more than maxQuantity NFTs");
        require(totalSupply() + quantity <= maxSupply, "Purchase would exceed max supply of NFTs");
        require(msg.value == sales[SALE_TYPE_PRIVATE2].price * quantity, "Ether value sent is not correct");
        require(sales[SALE_TYPE_PRIVATE2].allowList[recipient] == true, "Not in private sale list");
        require(_isSaleOngoing(SALE_TYPE_PRIVATE2) == true, "The sale is not ongoing");
        

        sales[SALE_TYPE_PRIVATE2].quantityList[recipient] = sales[SALE_TYPE_PRIVATE2].quantityList[recipient] + uint8(quantity);

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, totalSupply() + 1);
        }

        emit SoldItems(SALE_TYPE_PRIVATE2, recipient, quantity);
    }

    /**
     * Users can buy NFTs as many as they want.
     * But it has limit of the quantity per one purchase.
     * @param quantity The number of NFTs to mint
     */
    function buyPublicPrice(address recipient, uint256 quantity) public payable whenNotPaused
    {
        require(quantity > 0, "Must mint at least one NFT");
        require(quantity <= sales[SALE_TYPE_PUBLIC].maxQuantity, "Cannot mint more than maxQuantity NFTs at once");
        require(totalSupply() + quantity <= maxSupply, "Purchase would exceed max supply of NFTs");
        require(msg.value == sales[SALE_TYPE_PUBLIC].price * quantity, "Ether value sent is not correct");
        require(_isSaleOngoing(SALE_TYPE_PUBLIC) == true, "The sale is not ongoing");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipient, totalSupply() + 1);
        }

        emit SoldItems(SALE_TYPE_PUBLIC, recipient, quantity);
    }

    function setupSale(
        uint8 _saleType, // constant 1: private sale 1, 2: private sale 2, 3: public sale
        uint256 _price,
        uint256 _maxQuantity,
        uint256 _startAt,
        uint256 _endAt
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2 || _saleType == SALE_TYPE_PUBLIC, "Invalid sale type");
        Sale storage sale = sales[_saleType];
        sale.saleType = uint8(_saleType);
        sale.price = _price;
        sale.maxQuantity = _maxQuantity;
        sale.startAt = _startAt;
        sale.endAt = _endAt;
        sale.exists = true;
    }

    function getSale(uint8 _saleType) external view returns (
        uint256 price,
        uint256 maxQuantity,
        uint256 startAt,
        uint256 endAt
    ) {
        require(sales[_saleType].exists == true, "Sale does not exist");
        return (sales[_saleType].price, sales[_saleType].maxQuantity, sales[_saleType].startAt, sales[_saleType].endAt);
    }

    function updateSalePrice(uint8 _saleType, uint256 _price) external onlyRole(OPERATOR_ROLE) whenNotPaused
    {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2 || _saleType == SALE_TYPE_PUBLIC, "Invalid sale type");
        require(sales[_saleType].exists == true, "Sale does not exist");
        sales[_saleType].price = _price;
    }

    function updateMaxQuantity(uint8 _saleType, uint256 _maxQuantity) external onlyRole(OPERATOR_ROLE) whenNotPaused
    {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2, "Invalid sale type");
        require(sales[_saleType].exists == true, "Sale does not exist");
        sales[_saleType].maxQuantity = _maxQuantity;
    }

    function setupMaxSupply(uint256 _maxSupply) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Add to allow list
     */
    function addToAllowList(uint8 _saleType, address[] calldata _addresses)  external onlyRole(OPERATOR_ROLE)
    {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2, "Invalid sale type");
        require(sales[_saleType].exists == true, "Sale does not exist");
        for (uint i = 0; i < _addresses.length; i++) {
            sales[_saleType].allowList[_addresses[i]] = true;
        }
    }

    function removeFromAllowList(uint8 _saleType, address[] calldata addresses) external onlyRole(OPERATOR_ROLE)
    {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2, "Invalid sale type");
        require(sales[_saleType].exists == true, "Sale does not exist");
        for (uint i = 0; i < addresses.length; i++) {
            sales[_saleType].allowList[addresses[i]] = false;
        }
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    //This is an internal function that create Auction with given auction info.
    function _isSaleOngoing(uint8 _saleType) internal view returns (bool) {
        require(_saleType == SALE_TYPE_PRIVATE1 || _saleType == SALE_TYPE_PRIVATE2 || _saleType == SALE_TYPE_PUBLIC, "Invalid sale type");
        require(sales[_saleType].exists == true, "Sale does not exist");
        if (block.timestamp < sales[_saleType].endAt && block.timestamp >= sales[_saleType].startAt) {
            return true;
        }
        return false;
    }


  ////////////////////
  // Pausable

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Triggers un-stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  ////////////////////
  // Royality

  /**
   * @dev Sets default royalty information.
   */
  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  /**
   * @dev Removes default royalty information.
   */
  function deleteDefaultRoyalty() external onlyRole(ROYALTY_ROLE) {
    _deleteDefaultRoyalty();
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   */
  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE) {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   */
  function resetTokenRoyalty(uint256 tokenId) public onlyRole(ROYALTY_ROLE) {
    _resetTokenRoyalty(tokenId);
  }

  ////////////////////
  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
    super._burn(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable, ERC721RoyaltyUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721Upgradeable, IERC721Upgradeable) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override(ERC721Upgradeable, IERC721Upgradeable) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) whenNotPaused {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function bulkTransfer(
    uint256[] calldata tokenIds,
    address from,
    address[] calldata toAddresses
  ) public virtual whenNotPaused {
    uint256 length = tokenIds.length;
    require(length <= 255, "Amount should be 255 or less");
    require(length == toAddresses.length, 'TokenIds Length and toAddresses length are not matched');
    for (uint8 i; i < length;) {
      super.safeTransferFrom(from, toAddresses[i], tokenIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function bulkBurn(uint256[] calldata tokenIds) public {
    uint256 length = tokenIds.length;
    require(length <= 255, "Amount should be 255 or less");
    for (uint8 i; i < length;) {
      burn(tokenIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function renounceRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
    require(role != DEFAULT_ADMIN_ROLE || getRoleMemberCount(role) > 1, "This is last member of DEFAULT_ADMIN_ROLE!");
    super.renounceRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual override(AccessControlUpgradeable, IAccessControlUpgradeable) {
    require(role != DEFAULT_ADMIN_ROLE || getRoleMemberCount(role) > 1, "This is last member of DEFAULT_ADMIN_ROLE!");
    super.revokeRole(role, account);
  }

  // Meta Transaction
  function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
    return ERC2771ContextUpgradeable._msgData();
  }

  function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
    return hasRole(TRUSTED_FORWARDER_ROLE, forwarder);
  }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    // function setBaseURI
    function setBaseURI(string calldata _base) public onlyRole(OPERATOR_ROLE)
    {
        baseURI_ = _base;
    }

}
