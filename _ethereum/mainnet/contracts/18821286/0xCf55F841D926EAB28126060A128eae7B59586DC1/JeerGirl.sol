// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ReentrancyGuard.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSA.sol";
import "./OwnableUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Alien.sol";

contract JeerGirl is
UUPSUpgradeable,
OwnableUpgradeable,
EIP712Upgradeable,
ReentrancyGuardUpgradeable,
PausableUpgradeable,
ERC721Alien
{
    using Strings for uint256;
    error Purchase_WrongQuantity();
    error Purchase_WrongPrice(uint256 correctPrice);
    error Sale_Inactive();
    error FundsTransfer_Failed();
    error InvalidSign();
    error Purchase_Expired();

    bytes32 private constant PURCHASE_TYPEHASH =
    keccak256("purchase(uint256 quantity,address to,uint256 expire_timestamp)");

    uint256 public publicSaleStart_;
    uint256 public publicSalePrice_;
    address public fundsRecipient_;

    string private constant version = "1";
    uint256 public constant maxSupply_ = 3000;
    string private baseUri_;
    address private validator_;

    function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor() ERC721Alien("", "", 300){
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        string memory baseUri,
        address validator,
        address fundsRecipient,
        uint256 publicSaleStart,
        uint256 publicSalePrice
    ) external initializer {
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        baseUri_ = baseUri;
        validator_ = validator;
        fundsRecipient_ = fundsRecipient;
        publicSaleStart_ = publicSaleStart;
        publicSalePrice_ = publicSalePrice;
        __Context_init();
        __Ownable_init();
        __EIP712_init(_name, version);
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _publicSaleActive() internal view returns (bool) {
        return publicSaleStart_ <= block.timestamp;
    }

    modifier onlyPublicSaleActive() {
        if (!_publicSaleActive()) {
            revert Sale_Inactive();
        }
        _;
    }

    function purchase(
        uint256 quantity,
        address to,
        uint256 expire_timestamp,
        bytes calldata signature
    ) external payable onlyPublicSaleActive nonReentrant whenNotPaused {
        return _handlePurchase(to, quantity, expire_timestamp, signature);
    }

    function _handlePurchase(
        address to,
        uint256 quantity,
        uint256 expire_timestamp,
        bytes calldata signature
    ) internal {
        if (block.timestamp > expire_timestamp) {
            revert Purchase_Expired();
        }
        if (quantity <= 0) {
            revert Purchase_WrongQuantity();
        }
        if (msg.value != publicSalePrice_ * quantity) {
            revert Purchase_WrongPrice(publicSalePrice_ * quantity);
        }
        verifySignature(quantity, to, expire_timestamp, signature);

        __mintTo(to, quantity);
        _payoutFunds(publicSalePrice_ * quantity);
    }

    function _payoutFunds(uint256 price) internal {
        (bool success,) = fundsRecipient_.call{value: price}("");
        if (!success) {
            revert FundsTransfer_Failed();
        }
    }

    function __mintTo(address to, uint256 quantity) internal {
        require(
            maxSupply_ == 0 || totalSupply() + quantity <= maxSupply_,
            "Mint count exceed MAX_SUPPLY!"
        );

        _safeMint(to, quantity);
    }

    /**
     * @dev if maxSupply==0; means unlimited
     */
    function getMaxSupply() public pure returns (uint256) {
        return maxSupply_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri_;
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        baseUri_ = newBaseUri;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setSaleTime(uint256 publicSaleStart) external onlyOwner {
        publicSaleStart_ = publicSaleStart;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        publicSalePrice_ = price;
    }

    function setFundsRecipient(address fundsRecipient) external onlyOwner {
        require(fundsRecipient != address(0), "Cannot set to 0 address");
        fundsRecipient_ = fundsRecipient;
    }

    function setValidator(address validator) external onlyOwner {
        require(validator != address(0), "Cannot set to 0 address");
        validator_ = validator;
    }

    function verifySignature(
        uint256 quantity,
        address to,
        uint256 expire_timestamp,
        bytes calldata signature

    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(PURCHASE_TYPEHASH, quantity, to, expire_timestamp))
        );
        if (ECDSA.recover(digest, signature) != validator_) {
            revert InvalidSign();
        }
        return validator_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Alien) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function _msgSender()
    internal
    view
    virtual
    override(Context, ContextUpgradeable)
    returns (address)
    {
        return msg.sender;
    }

    function _msgData()
    internal
    view
    virtual
    override(Context, ContextUpgradeable)
    returns (bytes calldata)
    {
        return msg.data;
    }
}

