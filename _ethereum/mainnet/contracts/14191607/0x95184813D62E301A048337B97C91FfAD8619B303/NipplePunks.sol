// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC721.sol";
import "Ownable.sol";

import "CryptoPunksMarket.sol";
import "NipplePunkTickets.sol";

contract NipplePunks is ERC721, Ownable {
    CryptoPunksMarket public punks;
    NipplePunkTickets public tickets;

    bool public lostAndFoundActive = false;
    bool public mintOpen = false;

    uint256 public totalMinted = 0;
    uint256 public totalSupply = 10003;

    uint256 public lostAndFoundMintPrice = 0;

    string public contractURI_ = "https://nipplepunks.io/nipplepunks.json";

    constructor(CryptoPunksMarket punkAddress) ERC721("NipplePunks", "\u2299") {
        punks = punkAddress;
    }

    modifier onlyWhenMintOpen() {
        require(mintOpen, "minting is not open");
        _;
    }

    function _mintImpl(address to, uint256 tokenId) private {
        _safeMint(to, tokenId);
        totalMinted++;
    }

    function ticketMint(uint256 ticketId) external onlyWhenMintOpen {
        require(
            tickets.ownerOf(ticketId) == _msgSender(),
            "you don't own the ticket"
        );

        uint256 tokenId = tickets.ticketToNipplePunkMapping(ticketId);
        require(!_exists(tokenId), "this punk has already been minted");
        _mintImpl(_msgSender(), tokenId);
    }

    function _lostAndFoundMintImpl(uint256 index) private {
        require(lostAndFoundActive, "lost and found phase not active");
        require(
            punks.punkIndexToAddress(index) == _msgSender(),
            "you need to own the corresponding punk to use lost & found"
        );
        require(!_exists(index), "this punk has already been minted");
        _mintImpl(_msgSender(), index);
    }

    function lostAndFoundMint(uint256 index) external payable {
        require(lostAndFoundMintPrice == 0 || msg.value >= lostAndFoundMintPrice, "invalid price");
        _lostAndFoundMintImpl(index);
    }

    function lostAndFoundMintMultiple(uint256[] calldata indexes) external payable {
        require(lostAndFoundMintPrice == 0 || msg.value >= lostAndFoundMintPrice * indexes.length, "invalid price");
        for (uint i = 0; i < indexes.length; i++) {
            this.lostAndFoundMint(indexes[i]);
        }
    }

    function ownerMint(address to, uint256 index) external onlyOwner {
        _mintImpl(to, index);
    }

    function ownerMintMultiple(address to, uint256[] calldata indexes) external onlyOwner {
        for (uint256 i = 0; i < indexes.length; i++) {
            _mintImpl(to, indexes[i]);
        }
    }

    function setLostAndFoundActive(bool newActive) public onlyOwner {
        lostAndFoundActive = newActive;
    }

    function setMintOpen(bool newOpen) external onlyOwner {
        mintOpen = newOpen;
    }

    function setTickets(NipplePunkTickets newTickets) external onlyOwner {
        tickets = newTickets;
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
        return
            string(
                abi.encodePacked(
                    "ipfs://QmbJgzcWmDUsT6Z4qG82k7uF5mQ1YWHpGR3uMkBKcLq1Ss/",
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function contractURI() external view returns (string memory) {
        return contractURI_;
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI_ = _uri;
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function setLostAndFoundMintPrice(uint256 newPrice) external onlyOwner {
        lostAndFoundMintPrice = newPrice;
    }
}
