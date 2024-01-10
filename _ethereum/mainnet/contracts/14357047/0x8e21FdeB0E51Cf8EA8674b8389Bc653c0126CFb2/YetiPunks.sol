// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract YetiPunks is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxPerAddressDuringPublicSale = 6;
    uint256 public immutable amountForGiveaway;
    bool private revealed = false;
    bool private publicSaleOn = false;
    string public notRevealedUri;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForGiveaway_,
        string memory _initBaseUri,
        string memory _initNotRevealedUri
    ) ERC721A("YETIPUNKS", "YP", maxBatchSize_, collectionSize_) {
        amountForGiveaway = amountForGiveaway_;

        setBaseURI(_initBaseUri);
        setNotRevealedURI(_initNotRevealedUri);

        address[] memory devAddresses = new address[](3);
        devAddresses[0] = 0xbe16A803431fB1694656187334c50792031CD6Ac;
        devAddresses[1] = 0xAE534782fE40DA31a4D890d3bADAeF0352FEead7;
        devAddresses[2] = 0x7638aC632C177BB6eB88826065eb62b878F93754;
        devMint(devAddresses, 7);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        uint256 publicPrice = 0.02 ether;
        require(publicSaleOn, "Mint is not live");
        require(quantity <= maxBatchSize, "Max batch minting quantity exceeded");
        require(
            totalSupply() + quantity <= collectionSize - amountForGiveaway,
            "Public sale finished"
        );
        require(
            numberMinted(msg.sender) + quantity <=
                maxPerAddressDuringPublicSale,
            "Wallet limit exceeded"
        );
        require(msg.value >= publicPrice, "Need to send more ETH");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // For marketing etc.
    function devMint(address[] memory receiverAddresses, uint256 mintAmount)
        public
        onlyOwner
    {
        require(
            totalSupply() + mintAmount <= collectionSize,
            "Exceeded max supply"
        );

        for (uint256 i = 0; i < receiverAddresses.length; i++) {
            _safeMint(receiverAddresses[i], mintAmount);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();

        if (revealed == true) {
            return
                bytes(baseURI).length > 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                    : "";
        } else {
            return notRevealedUri;
        }
    }

    function revealCollection() public onlyOwner {
        revealed = true;
    }

    function setPublicSale(bool state) public onlyOwner {
        publicSaleOn = state;
    }

    function withdrawBalance() public onlyOwner {
        uint256 oneThird = (address(this).balance * 33) / 100;
        (bool unorthadoxantSuccess, ) = payable(
            0xbe16A803431fB1694656187334c50792031CD6Ac
        ).call{value: oneThird}("");
        require(unorthadoxantSuccess);
        (bool somkidSuccess, ) = payable(
            0xAE534782fE40DA31a4D890d3bADAeF0352FEead7
        ).call{value: oneThird}("");
        require(somkidSuccess);
        (bool andreasSuccess, ) = payable(
            0x7638aC632C177BB6eB88826065eb62b878F93754
        ).call{value: address(this).balance}("");
        require(andreasSuccess);
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
