// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC2981.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

error QueryForNonexistentToken();
error MintWouldExceedMaxSupply();
error MintWouldExceedAddressMax();
error FreeMintQuantityExceeded();
error IncorrectETHAmount();
error CallerNotEoA();
error TransferWouldExceedMaxHolding();
error MintNotActive();

contract RetroRiders is Ownable, IERC2981, ERC721A {
    uint256 public constant MAX_SUPPLY = 2500;
    uint256 public constant ADDRESS_MAX = 5;

    uint256 public price = 0.015 ether;
    uint256 public freeAmount = 1500;
    uint256 public freeAmountMinted = 0;
    uint256 public freePerAddress = 1;
    uint256 public royaltiesNumerator = 55;
    uint256 public mintActiveBlock = 9999999999999;
    uint256 public maxHolding = 30;

    string public baseURI =
        "ipfs://QmV54mAQoXBqBCzDeYbrwSsKYiVoYFcSNkZqxGHuiE6NP4/";
    string private _contractURI =
        "ipfs://QmctzaLCzyEjUWm2hi6UXR1h8J2jPDu2UGqHi2vK231Ggv";

    event RoyaltiesChanged(uint256 previousRoyalties, uint256 newRoyalties);
    event MaxHoldingChanged(uint256 previousMaxHolding, uint256 newMaxHolding);
    event FreePerAddressChanged(uint256 previousMaxFreePerAddress, uint256 newMaxFreePerAddress);
    event MintActiveBlockChanged(uint256 previousMintActiveTimestamp, uint256 newMintActiveTimestamp);

    constructor() ERC721A("RetroRiders", "RR") {}

    function saleActive() external view returns (bool) {
        return block.number > mintActiveBlock;
    }

    function freeMintsAvailable(address address_) external view returns (uint256) {
        if(freeAmountMinted < freeAmount) {
            return freePerAddress - _numberMinted(address_);
        }
        return 0;
    }

    function mint(uint256 quantity_) mintAllowed(quantity_) external payable {
        uint256 totalPrice;
        if(freeAmountMinted < freeAmount && _numberMinted(msg.sender) < freePerAddress) {
            uint256 remainingFreeMints = freePerAddress - _numberMinted(msg.sender);
            if(quantity_ > remainingFreeMints) {
                totalPrice = (quantity_ - remainingFreeMints) * price;
                freeAmountMinted += remainingFreeMints;
            } else {
                totalPrice = 0;
                freeAmountMinted += quantity_;
            }
        } else {
            totalPrice = quantity_ * price;
        }
        if(msg.value != totalPrice) revert IncorrectETHAmount();
        _mint(msg.sender, quantity_);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setFreeAmount(uint256 freeAmount_) external onlyOwner {
        freeAmount = freeAmount_;
    }

    function setMaxHolding(uint256 maxHolding_) external onlyOwner {
        uint256 previous = maxHolding;
        maxHolding = maxHolding_;

        emit MaxHoldingChanged(previous, maxHolding_);
    }

    function setFreePerAddress(uint256 freePerAddress_) external onlyOwner {
        uint256 previous = freePerAddress;
        freePerAddress = freePerAddress_;

        emit FreePerAddressChanged(previous, freePerAddress_);
    }

    function setRoyaltiesNumerator(uint256 royaltiesNumerator_)
        external
        onlyOwner
    {
        uint256 previousRoyalties = royaltiesNumerator;
        royaltiesNumerator = royaltiesNumerator_;

        emit RoyaltiesChanged(previousRoyalties, royaltiesNumerator);
    }

    function setMintActiveBlock(uint256 mintActiveBlock_)
        external
        onlyOwner
    {
        uint256 previous = mintActiveBlock;
        mintActiveBlock = mintActiveBlock_;

        emit MintActiveBlockChanged(previous, mintActiveBlock_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory newContractURI_) external onlyOwner {
        _contractURI = newContractURI_;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();
        return (owner(), (salePrice * royaltiesNumerator) / 1000);
    }

    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (balanceOf(to) + quantity > maxHolding)
            revert TransferWouldExceedMaxHolding();
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    modifier mintAllowed(uint256 quantity_) {
        if (tx.origin != msg.sender) revert CallerNotEoA();
        if (block.number < mintActiveBlock) revert MintNotActive();
        if (quantity_ + totalSupply() > MAX_SUPPLY)
            revert MintWouldExceedMaxSupply();
        if (quantity_ + _numberMinted(msg.sender) > ADDRESS_MAX)
            revert MintWouldExceedAddressMax();
        _;
    }
}
