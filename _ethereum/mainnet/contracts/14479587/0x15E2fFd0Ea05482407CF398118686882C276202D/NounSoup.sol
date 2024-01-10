// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Utils.sol";
import "./INounSoupRenderer.sol";
import "./Ownable.sol";

error MintingNotLive();
error WalletsNotConfigured();
error NothingToWithdraw();
error InvalidNumberOfTokens();
error InvalidPayment();
error NotEnoughTokensAvailable();
error InvalidAddress();
error NotANounOwner();
error InvalidToken();

//           _____                   _______                   _____                    _____
//          /\    \                 /::\    \                 /\    \                  /\    \
//         /::\____\               /::::\    \               /::\____\                /::\____\
//        /::::|   |              /::::::\    \             /:::/    /               /::::|   |
//       /:::::|   |             /::::::::\    \           /:::/    /               /:::::|   |
//      /::::::|   |            /:::/~~\:::\    \         /:::/    /               /::::::|   |
//     /:::/|::|   |           /:::/    \:::\    \       /:::/    /               /:::/|::|   |
//    /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /               /:::/ |::|   |
//   /:::/  |::|   | _____   /:::/____/   \:::\____\   /:::/    /      _____    /:::/  |::|   | _____
//  /:::/   |::|   |/\    \ |:::|    |     |:::|    | /:::/____/      /\    \  /:::/   |::|   |/\    \
// /:: /    |::|   /::\____\|:::|____|     |:::|    ||:::|    /      /::\____\/:: /    |::|   /::\____\
// \::/    /|::|  /:::/    / \:::\    \   /:::/    / |:::|____\     /:::/    /\::/    /|::|  /:::/    /
//  \/____/ |::| /:::/    /   \:::\    \ /:::/    /   \:::\    \   /:::/    /  \/____/ |::| /:::/    /
//          |::|/:::/    /     \:::\    /:::/    /     \:::\    \ /:::/    /           |::|/:::/    /
//          |::::::/    /       \:::\__/:::/    /       \:::\    /:::/    /            |::::::/    /
//          |:::::/    /         \::::::::/    /         \:::\__/:::/    /             |:::::/    /
//          |::::/    /           \::::::/    /           \::::::::/    /              |::::/    /
//          /:::/    /             \::::/    /             \::::::/    /               /:::/    /
//         /:::/    /               \::/____/               \::::/    /               /:::/    /
//         \::/    /                 ~~                      \::/____/                \::/    /
//          \/____/                                           ~~                       \/____/
//           _____                   _______                   _____                    _____
//          /\    \                 /::\    \                 /\    \                  /\    \
//         /::\    \               /::::\    \               /::\____\                /::\    \
//        /::::\    \             /::::::\    \             /:::/    /               /::::\    \
//       /::::::\    \           /::::::::\    \           /:::/    /               /::::::\    \
//      /:::/\:::\    \         /:::/~~\:::\    \         /:::/    /               /:::/\:::\    \
//     /:::/__\:::\    \       /:::/    \:::\    \       /:::/    /               /:::/__\:::\    \
//     \:::\   \:::\    \     /:::/    / \:::\    \     /:::/    /               /::::\   \:::\    \
//   ___\:::\   \:::\    \   /:::/____/   \:::\____\   /:::/    /      _____    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \ |:::|    |     |:::|    | /:::/____/      /\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\|:::|____|     |:::|    ||:::|    /      /::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    / \:::\    \   /:::/    / |:::|____\     /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/   \:::\    \ /:::/    /   \:::\    \   /:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \        \:::\    /:::/    /     \:::\    \ /:::/    /            \::::::/    /
//    \:::\   \:::\____\        \:::\__/:::/    /       \:::\    /:::/    /              \::::/    /
//     \:::\  /:::/    /         \::::::::/    /         \:::\__/:::/    /                \::/____/
//      \:::\/:::/    /           \::::::/    /           \::::::::/    /                  ~~
//       \::::::/    /             \::::/    /             \::::::/    /
//        \::::/    /               \::/____/               \::::/    /
//         \::/    /                 ~~                      \::/____/
//          \/____/                                           ~~

contract NounSoup is ERC721A, Ownable {
    constructor() ERC721A("Noun Soup", "NOUNSOUP") {}

    string public tokenName = "Noun Soup";
    string public tokenDescription =
        "Noun Soups are 100% on-chain pop-art paying homage to Andy Warhol's iconic soup cans. They are a derivative of Nouns, a CC0 project. We're CC0 too. Our soup is your soup.";
    string public tokenExternalUrl = "https://nounsoup.wtf";

    /// @notice The maximum number of tokens that can be minted
    uint256 public constant MAX_TOKENS = 6669;

    /// @notice The maximum number of mints allowed in a single mint transactions
    uint256 public constant MAX_MINTS_PER_TXN = 100;

    /// @notice The price of a NOUN SOUP
    uint256 public constant PRICE = 0.01 ether;

    /// @notice Indicates whether or not the sale is open for minting
    bool public mintingLive = false;

    /// @notice the address to withdraw funds to (this mint is to fund raise for: https://ukrainedao.love)
    address public ukraineDAOAddress =
        0x633b7218644b83D57d90e7299039ebAb19698e9C;

    /// @notice the contract address to render our soup
    address public rendererAddress;

    /// @notice set the contract to render our soup
    function setRendererAddress(address address_) external onlyOwner {
        rendererAddress = address_;
    }

    /// override ERC721A to have token start at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice mint some Noun Soup
    function mint(uint256 quantity) external payable {
        if (msg.value != PRICE * quantity) revert InvalidPayment();
        if (!mintingLive && owner() != msg.sender) revert MintingNotLive();
        if (quantity > MAX_MINTS_PER_TXN) revert InvalidNumberOfTokens();
        if (totalSupply() + quantity > MAX_TOKENS)
            revert NotEnoughTokensAvailable();
        _safeMint(msg.sender, quantity);
    }

    /// @notice toggle minting on/off
    function toggleMintingLive() public onlyOwner {
        mintingLive = !mintingLive;
    }

    /// @notice distribute funds to ukraineDAO wallet
    function withdraw() public onlyOwner {
        if (address(this).balance == 0) revert NothingToWithdraw();
        payable(ukraineDAOAddress).transfer(address(this).balance);
    }

    /// @notice properties for each token
    function svgForToken(uint256 tokenId_)
        public
        view
        returns (string memory)
    {
        if (ownerOf(tokenId_) == address(0x0)) revert InvalidToken();

        if (!Address.isContract(rendererAddress)) {
            return "";
        }

        INounSoupRenderer renderer = INounSoupRenderer(rendererAddress);

        (string memory svgData,) = renderer.generateData(
            tokenId_
        );
        return svgData;
    }

    /// @notice properties for each token
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId_) == address(0x0)) revert InvalidToken();

        if (!Address.isContract(rendererAddress)) {
            return "";
        }

        INounSoupRenderer renderer = INounSoupRenderer(rendererAddress);

        (string memory svgData, string memory attrData) = renderer.generateData(
            tokenId_
        );

        // properties
        bytes memory _header = abi.encodePacked(
            'data:application/json;utf8,{"name": "',
            tokenName,
            " #",
            Strings.toString(tokenId_),
            '", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgData)),
            '", "external_url": "',
            tokenExternalUrl,
            '", "description": "',
            tokenDescription,
            '"'
        );

        // footer
        bytes memory _footer = "}";

        // now put it all together
        string memory _metadata = string(
            abi.encodePacked(_header, attrData, _footer)
        );
        return _metadata;
    }
}
