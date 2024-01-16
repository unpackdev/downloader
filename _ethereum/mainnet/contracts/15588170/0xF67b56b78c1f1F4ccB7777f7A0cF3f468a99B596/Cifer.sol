// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

/// @title Cifer
/// @author yyyk
contract Cifer is ERC2981, ERC721, Pausable, Ownable {
    using Strings for uint256;

    bytes16 private constant HEX_TABLE = "0123456789abcdef";
    uint96 private constant ROYALTY_OVER_10000 = 1000; // 10%
    uint8 private constant MAX_BALANCE_PER_WALLET = 1;
    uint8 public constant maxSupply = 16; // ID: 0~15

    mapping(address => bool) private walletMinted;
    uint8 private currentIndex = 0;

    event Minted(address indexed to, uint256 indexed tokenId);

    constructor() ERC721("Cifer", "CIFER") {
        ERC2981._setDefaultRoyalty(msg.sender, ROYALTY_OVER_10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice On mint or transfer, balance is checked to keep only one token owned per wallet
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            ERC721.balanceOf(to) < MAX_BALANCE_PER_WALLET,
            "Max balance per wallet exceeded."
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice base64 encoded json with base64 encoded svg for the image
    /// @param tokenId token id
    /// @return string base64 encoded json string
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            ERC721._exists(tokenId),
            "ERC721: URI query for nonexistent token"
        );
        return generateTokenURI(ERC721.ownerOf(tokenId), tokenId);
    }

    /// @notice Free to mint but only once per wallet.
    function mint() external whenNotPaused returns (uint256) {
        require(currentIndex < maxSupply, "No more tokens left to mint.");
        require(!walletMinted[msg.sender], "Wallet used to mint before.");

        walletMinted[msg.sender] = true;
        uint256 tokenId = currentIndex;
        currentIndex++;
        ERC721._safeMint(msg.sender, tokenId);

        emit Minted(msg.sender, tokenId);

        return tokenId;
    }

    function generateTokenURI(address owner, uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        bytes memory title = abi.encodePacked("Cifer #0x", HEX_TABLE[tokenId]);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            title,
                            '","description":"Cifer is a collection of 16 fully on-chain artworks, each generated from 0x{owner\'s wallet address} and 0x{token ID}. License: CC0","image":"',
                            abi.encodePacked(
                                "data:image/svg+xml;base64,",
                                Base64.encode(
                                    abi.encodePacked(
                                        '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="616" height="712" viewBox="0 0 770 890"><title>',
                                        title,
                                        '</title><metadata xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cc="http://creativecommons.org/ns#"><rdf:RDF><cc:Work rdf:about=""><cc:license rdf:resource="https://creativecommons.org/publicdomain/zero/1.0/" /></cc:Work></rdf:RDF></metadata><rect class="background" width="770" height="890" x="0" y="0" fill="#000000" stroke="none" /><g transform="translate(25 25)">',
                                        generatePaths(owner, tokenId),
                                        "</g></svg>"
                                    )
                                )
                            ),
                            '"}'
                        )
                    )
                )
            );
    }

    function generatePaths(address owner, uint256 tokenId)
        internal
        pure
        returns (bytes memory)
    {
        uint160 ownerUint = uint160(owner);
        bytes memory result = "";
        for (uint256 y = 0; y < 7; ++y) {
            for (uint256 x = 0; x < 6; ++x) {
                uint256 index = y * 6 + x + 1;
                if (index == 41) {
                    continue;
                }
                uint256 d = index <= 40
                    ? (ownerUint >> (4 * (40 - index))) & 0xf
                    : tokenId;
                uint256 halfD = d / 2;
                bytes memory angle = halfD == 7
                    ? abi.encodePacked("0")
                    : abi.encodePacked("-", (45 * (halfD + 1)).toString());
                bytes memory transform = abi.encodePacked(
                    "translate(",
                    (x * 120).toString(),
                    " ",
                    (y * 120).toString(),
                    ") rotate(",
                    angle,
                    " 60 60)",
                    d % 2 == 0 ? " translate(120 0) scale(-1 1)" : ""
                );
                result = abi.encodePacked(
                    result,
                    '<path id="',
                    index == 42 ? "id" : index.toString(),
                    '" d="M40 25L80 25L80 35L50 35 L50 55L80 55 L80 65 L50 65 L50 95L40 95Z" fill="#ffffff" stroke="none" transform="',
                    transform,
                    '" />'
                );
            }
        }
        return result;
    }
}
