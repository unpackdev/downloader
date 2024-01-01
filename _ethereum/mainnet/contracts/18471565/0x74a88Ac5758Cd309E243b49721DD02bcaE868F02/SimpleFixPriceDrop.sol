// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./DefaultOperatorFilterer.sol";

contract SimpleFixPriceDrop is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    Ownable,
    DefaultOperatorFilterer,
    PaymentSplitter,
    ReentrancyGuard
{
    using Strings for uint256;

    error InvalidPrice(address emitter);
    error SaleNotStarted(address emitter);
    error SoldOut(address emitter);
    error EtherTransferFail(address emitter);
    error SaleNotActive(address emitter);

    event Sold(address indexed to, uint256 price, uint256 tokenId);
    event PermanentURI(string _value, uint256 indexed _id);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    uint256 private constant STARTING_INDEX = 0;

    bool metadataFrozen = false;
    bool saleActive = true;
    uint256 private currentMintTokenId = STARTING_INDEX;

    string public baseUri;
    string public suffix;
    uint256 public saleStartTime;
    uint256 public maxSupply;
    uint256 private price;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _suffix,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _saleStartTime,
        address _royalReceiver,
        uint96 _royalFeeNumerator,
        address[] memory payees,
        uint256[] memory shares_
    ) payable ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        require(_maxSupply > 0, "Invalid max supply");
        require(_saleStartTime > 1672527600, "Minimum sale start is 2023-01-01");
        require(_saleStartTime < 4133890800, "Maximum sale start is 2100-12-31");
        require(_price > 0, "Price needs to be > 0");

        baseUri = _baseUri;
        suffix = _suffix;
        saleStartTime = _saleStartTime;
        maxSupply = _maxSupply;
        price = _price;

        if (_royalReceiver != address(0)) {
            _setDefaultRoyalty(_royalReceiver, _royalFeeNumerator);
        }
    }

    function preMint(address to) public onlyOwner {
        if (totalSupply() >= maxSupply) revert SoldOut(address(this));
        if(!saleActive) revert SaleNotActive(address(this));
        mintInternal(to);
    }

    function mint() public payable nonReentrant {
        if (totalSupply() >= maxSupply) revert SoldOut(address(this));
        if (block.timestamp < saleStartTime) {
            revert SaleNotStarted(address(this));
        }

        if (msg.value != price) revert InvalidPrice(address(this));
        if(!saleActive) revert SaleNotActive(address(this));

        emit Sold(msg.sender, price, currentMintTokenId);
        mintInternal(msg.sender);
    }

    function mintInternal(address to) private {
        _safeMint(to, currentMintTokenId);
        ++currentMintTokenId;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
        maxSupply = totalSupply();
    }

    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseUri(string memory _baseUri, string memory _suffix) public onlyOwner {
        require(metadataFrozen == false, "Metadata frozen");
        baseUri = _baseUri;
        suffix = _suffix;

        emit BatchMetadataUpdate(STARTING_INDEX,  totalSupply() + STARTING_INDEX);
    }

    function freezeMetadata() public onlyOwner {
        require(metadataFrozen == false, "Metadata already frozen");
        metadataFrozen = true;
        for (
            uint256 i = STARTING_INDEX;
            i < totalSupply() + STARTING_INDEX;
            ++i
        ) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    function currentPrice() public view returns (uint256) {
        return price;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(baseUri, tokenId.toString(), suffix));
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Royalty, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
