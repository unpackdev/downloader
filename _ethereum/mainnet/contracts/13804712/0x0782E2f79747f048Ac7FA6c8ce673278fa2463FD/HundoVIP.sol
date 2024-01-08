// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";

library SVGHelper {
    function generateSVG(string memory _backerName)
        public
        pure
        returns (string memory finalSvg)
    {
        finalSvg = string(
            abi.encodePacked(
                "<svg id='hundoVIP' data-name='hundo VIP NFT' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='595' height='841'><defs><style>.cls-1{fill:#eae331}.cls-2,.cls-3{fill:#111110}.cls-3{font-size:18px;font-family:Impact;font-weight:700;letter-spacing:.03em}</style></defs><rect class='cls-1' width='100%' height='100%'/><path class='cls-2' d='M132.7 112.7h-9.9V150h-18.5V63.2h18.5v35.6h9.9V63.2h18.7V150h-18.7ZM201.8 63.2v65.1c0 14-6.6 22.8-21.8 22.8-15.9 0-23.5-8.7-23.5-22.8v-65H175V130c0 3.7 1.1 6.5 5 6.5s5-2.8 5-6.5V63.2ZM222.4 101.5v48.4H207V63.2h18l11.4 43v-43H252V150h-16.2ZM282.1 63.2c16.4 0 22 9.6 22 24.3v38.1c0 14.6-5.6 24.3-22 24.3H257V63.2Zm-6.6 72.7h4c4.4 0 6-2.5 6-6.7V83.7c0-4-1.6-6.4-6-6.4h-4ZM309.3 127V86.1c0-14.4 7.7-24.1 23.6-24.1 16.1 0 24 9.7 24 24.1V127c0 14.3-7.9 24.2-24 24.2-15.8 0-23.6-9.9-23.6-24.2Zm28.8 2.7V83.4c0-4-1.1-6.9-5.2-6.9-3.8 0-5.1 3-5.1 7v46.2c0 4 1.3 7 5.1 7 4.1 0 5.3-3 5.3-7ZM389.6 63.2V150H371V87.6h-.1l-9.6 9.4h-.3V78.5l13.7-15.3ZM396 126.8V86.4c0-14.2 7.2-24.3 22.9-24.3s23 10 23 24.3v40.4c0 14-7.3 24.3-23 24.3S396 140.8 396 126.8Zm27.5 3.4V83c0-3.8-1.2-6.4-4.6-6.4s-4.5 2.6-4.5 6.4v47.3c0 3.9 1 6.4 4.5 6.4s4.5-2.5 4.5-6.4ZM446.8 126.8V86.4c0-14.2 7.2-24.3 23-24.3s23 10 23 24.3v40.4c0 14-7.4 24.3-23 24.3s-23-10.3-23-24.3Zm27.5 3.4V83c0-3.8-1.1-6.4-4.6-6.4s-4.5 2.6-4.5 6.4v47.3c0 3.9 1 6.4 4.5 6.4s4.6-2.5 4.6-6.4ZM124.8 417.6 144 316.1h24.3l19 101.5h-22.2l-2.4-16.3h-15l-2.4 16.3Zm25.2-32.3h10.3l-5.1-34.9h-.1ZM187.7 390.7V343c0-17 9-28.3 27.7-28.3 19.3 0 25.8 11 25.8 27.5v10.8h-19.8v-13.5c0-4.8-1.3-8-6-8-4.5 0-6 3.5-6 8.2V394c0 4.6 1.4 8 6 8 4.7 0 6-3.2 6-7.9v-18.9h19.8v16.5c0 16.2-6.8 27.2-25.8 27.2-18.8 0-27.7-11.5-27.7-28.2ZM246.8 390.7V343c0-17 9-28.3 27.7-28.3 19.3 0 25.9 11 25.9 27.5v10.8h-20v-13.5c0-4.8-1.1-8-6-8-4.4 0-6 3.5-6 8.2V394c0 4.6 1.6 8 6 8 4.9 0 6-3.2 6-7.9v-18.9h20v16.5c0 16.2-7 27.2-26 27.2-18.6 0-27.6-11.5-27.6-28.2ZM305.9 316.1h42.8v16.5h-21.1v25.1h14.8V374h-14.8v27.1h21.1v16.5h-42.8ZM353.2 395v-12.6H373V396c0 4 1.6 6.7 5.8 6.7s5.7-2.8 5.7-6.7V392c0-5-2-8.5-6.4-12.6l-10.5-10.1c-10-10-14.5-16.2-14.5-28.5v-2.5c0-12.9 7.2-23.5 25.9-23.5 18.8 0 25.6 9.1 25.6 24.2v7.5H385V338c0-4.3-1.7-6.9-5.7-6.9s-5.9 2.4-5.9 6.6v1.6c0 5 2.9 7.8 7 11.7l11.5 11c9.4 9.6 14 16.7 14 27.8v4.2c0 14.8-8.2 25-27.2 25-18.9 0-25.6-10.2-25.6-24ZM409.5 395v-12.6h19.9V396c0 4 1.6 6.7 5.8 6.7s5.7-2.8 5.7-6.7V392c0-5-2.1-8.5-6.4-12.6L424 369.3c-10-10-14.5-16.2-14.5-28.5v-2.5c0-12.9 7.2-23.5 25.9-23.5S461 323.9 461 339v7.5h-19.6V338c0-4.3-1.7-6.9-5.7-6.9s-5.9 2.4-5.9 6.6v1.6c0 5 2.9 7.8 7 11.7l11.4 11c9.4 9.7 14 16.7 14 27.8v4.2c0 14.8-8.2 25-27.2 25-18.8 0-25.5-10.2-25.5-24ZM218.4 532.7l19.2-101.5h24.2L281 532.8h-22.3l-2.4-16.3h-15l-2.4 16.3Zm25.2-32.3h10.3l-5-34.9h-.2ZM284.3 431.3H306v85h18.3v16.4h-40ZM329 431.3h21.7v85H369v16.4h-40ZM150.4 647.8l19.2-101.4h24.2L213 647.8h-22.3l-2.4-16.3h-15l-2.4 16.3Zm25.1-32.3H186l-5.1-34.9h-.2ZM238 602v45.8h-21.8V546.4H244c19 0 25.5 9.1 25.5 24v12.3c0 9.8-2.7 15.9-9.9 18.9l12.4 46.2h-22.6Zm0-39.2v28.5h3.3c4.5 0 6.3-2.3 6.3-6.6v-15.4c0-4.4-1.8-6.5-6.3-6.5ZM275 546.4h42.7v16.4h-21V588h14.7v16.3h-14.8v27.1h21.1v16.5H275ZM320.4 647.8l19.2-101.4h24.2L383 647.8h-22.3l-2.4-16.3h-15l-2.4 16.3Zm25.2-32.3h10.3l-5.1-34.9h-.1ZM383.9 625.2v-12.5h19.9V626c0 4 1.6 6.8 5.8 6.8 4 0 5.7-2.9 5.7-6.8v-3.9c0-5-2.1-8.5-6.4-12.5l-10.5-10.2c-10-9.9-14.5-16.2-14.5-28.4v-2.6c0-12.8 7.2-23.5 25.9-23.5 18.8 0 25.5 9.2 25.5 24.3v7.5h-19.6v-8.6c0-4.3-1.6-6.9-5.6-6.9-4 0-5.9 2.4-5.9 6.6v1.7c0 5 2.9 7.8 7 11.6l11.4 11.1c9.4 9.6 14 16.6 14 27.7v4.2c0 14.8-8.2 25-27.2 25-18.8 0-25.5-10.2-25.5-24ZM205.4 725.4h188.8v51.8H205.4z'/><path class='cls-1' d='M241.3 755.8h-5.8l-.8 3.6h-3.3l4-16.8h6l4 16.8h-3.3Zm-5-3h4.3l-2-8.6h-.4ZM247.4 742.6h6.1a6.4 6.4 0 0 1 4.7 1.5 6 6 0 0 1 1.5 4.5v4.9a6 6 0 0 1-1.5 4.5 6.4 6.4 0 0 1-4.7 1.4h-6v-3h1.5v-10.8h-1.6Zm6.1 13.8a3 3 0 0 0 2.4-.8 3.7 3.7 0 0 0 .6-2.4v-4.6a3.2 3.2 0 0 0-.6-2.2 3 3 0 0 0-2.4-.8h-1.3v10.8ZM262.2 742.6h5.5l1 12.6v2.5h.6v-2.5l1-12.6h5.6v16.8h-3v-11.2l.4-3.8h-.6l-1.2 15h-4.8l-1.3-15h-.6l.3 3.8v11.2h-2.9ZM278.6 742.6H290v3h-4v10.8h4v3h-11.3v-3h4v-10.8h-4ZM293.5 742.6h12.1v3h-4.5v13.8H298v-13.8h-4.5ZM324 749.1a7.2 7.2 0 0 1 1.6-5 6.6 6.6 0 0 1 9 0 7.2 7.2 0 0 1 1.7 5v3.8a7.2 7.2 0 0 1-1.6 5.1 6.8 6.8 0 0 1-9.1 0 7.2 7.2 0 0 1-1.7-5.1Zm6.1 7.8a3.4 3.4 0 0 0 1.5-.3 2.5 2.5 0 0 0 .9-.8 3 3 0 0 0 .5-1.2 7.4 7.4 0 0 0 .1-1.5V749a6.5 6.5 0 0 0-.1-1.5 3.3 3.3 0 0 0-.6-1.2 2.6 2.6 0 0 0-.9-.8 3.4 3.4 0 0 0-2.8 0 2.6 2.6 0 0 0-.9.8 3.3 3.3 0 0 0-.5 1.2 6.5 6.5 0 0 0-.2 1.5v4.1a7.4 7.4 0 0 0 .1 1.6 3 3 0 0 0 .5 1.2 2.5 2.5 0 0 0 1 .8 3.4 3.4 0 0 0 1.4.2ZM347.7 757.8h.4v-15.2h3.2v16.8H345l-2-15.2h-.4v15.2h-3.2v-16.8h6.2ZM355.3 742.6H366v3h-7.4v3.9h7.2v3h-7.2v3.9h7.7v3h-10.9Z'/><text class='cls-3' dy='-30'><textPath xlink:href='#line' startOffset='50%' y='-40' text-anchor='middle'>THIS PASS GRANTS</textPath></text><text class='cls-3'><textPath id='name' xlink:href='#line' startOffset='50%' text-anchor='middle'>",
                _backerName,
                "</textPath></text><path id='line' style='fill:none;stroke:#111110;stroke-miterlimit:10;stroke-width:0px' d='M56.8 254.8h481.6'/></svg>"
            )
        );
    }

    function svgToImageURI(string memory _svg)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(_svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory _imageURI)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:application/json;base64,";
        string memory metadataBase64Encoded = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name": "hundoVIP", ',
                    '"description": "A special NFT to recognise backers of the hundo100 NFT collection", ',
                    '"attributes": [{"trait_type": "Collection", "value": "Genesis"}, {"trait_type": "CareerCon", "value": "2022"}, {"trait_type": "Admission", "value": "VIP"}], ',
                    '"animation_url": "https://ipfs.io/ipfs/bafybeibs4bhu6fl6xv7etd7ze4km5x6vvlve446jzweiskomh2rfbra4ae", ',
                    '"image_data":"',
                    _imageURI,
                    '"}'
                )
            )
        );
        return string(abi.encodePacked(baseURL, metadataBase64Encoded));
    }
}

/// @custom:security-contact giodisiena@gmail.com
contract HundoVIP is
    ERC721,
    ERC721URIStorage,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    uint256 public _tokenIds;
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable PRICE;
    address public hundoMultiSig;
    mapping(address => uint256) public donations;

    /* events */
    event DonationReceived(address _sender, uint256 _value);
    event FundsWithdrawn(uint256 _proceeds);
    event MultiSigUpdated(address _hundoMultiSig);
    event Reserved(address _account, uint256 _tokenId, string svg);

    constructor(
        uint256 _maxSupply,
        uint256 _price,
        string memory _name,
        string memory _symbol,
        string[] memory _reservedSeedInvestors,
        address _hundoMultiSig
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        PRICE = _price;
        _tokenIds = 0;
        hundoMultiSig = _hundoMultiSig;
        // Some of our seed investors don't yet have a wallet set up, so hundo multi-sig will custody
        for (uint8 i = 0; i < _reservedSeedInvestors.length; i++) {
            _mintReceipt(_hundoMultiSig, _reservedSeedInvestors[i]);
        }
    }

    receive() external payable {
        donations[msg.sender] += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    fallback() external payable {}

    function reserve(string calldata _backerName)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_tokenIds < MAX_SUPPLY, "Sale ended");
        require(msg.value >= PRICE, "Insufficient payment");
        _mintReceipt(msg.sender, _backerName);
    }

    /* owner */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateHundoMultiSigAddress(address _hundoMultiSig)
        external
        onlyOwner
    {
        require(_hundoMultiSig != address(0), "Invalid address");
        hundoMultiSig = _hundoMultiSig;
        emit MultiSigUpdated(_hundoMultiSig);
    }

    function withdrawProceeds() external onlyOwner {
        uint256 proceeds = address(this).balance;
        require(proceeds > 0, "No balance");
        (bool sent, ) = hundoMultiSig.call{value: proceeds}("");
        require(sent, "Failed to withdraw funds");
        emit FundsWithdrawn(proceeds);
    }

    /* public view */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* internal */
    function _mintReceipt(address _account, string memory _backerName)
        internal
    {
        _tokenIds += 1;
        uint256 tokenId = _tokenIds;
        _safeMint(_account, tokenId);

        string memory svg = SVGHelper.generateSVG(_backerName);
        string memory imageURI = SVGHelper.svgToImageURI(svg);
        _setTokenURI(tokenId, SVGHelper.formatTokenURI(imageURI));
        emit Reserved(_account, tokenId, svg);
    }

    /* internal overrides */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI)
        internal
        override
    {
        super._setTokenURI(_tokenId, _tokenURI);
    }
}
