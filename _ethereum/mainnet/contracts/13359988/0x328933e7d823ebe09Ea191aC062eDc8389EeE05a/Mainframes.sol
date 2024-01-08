//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Colors.sol";
import "./SVGFace.sol";

contract Mainframes is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 public cost = 0.02048 ether;
    uint256 public maxSupply = 2048;

    Counters.Counter private _tokenIdCounter;

    string public constant DESCRIPTION =
        "Mainframes are a collection of 2048 randomly generated mainframes stored entirely on-chain. Each Mainframe will fit into your wallet and stay operational forever, constantly giving you retro vibes from the past.";

    constructor() ERC721("Mainframes", "MFS") {
        _tokenIdCounter.increment();
    }

    function _mint(address _to) private {
        uint256 amount = _tokenIdCounter.current();
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "SOLD_OUT");

        _safeMint(_to, amount);
        _tokenIdCounter.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory seed = string(
            abi.encodePacked(
                Strings.toString(tokenId),
                block.difficulty,
                block.timestamp
            )
        );
        Colors.MainframeColors memory colors = Colors.generateComputerColors(
            seed
        );
        uint256 face = Colors.generatePseudoRandomValue(seed, 0, 200);

        string memory attributes = generateAttributes(face);

        string memory image = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" fill="none">',
                generatePaths(face),
                generateDefs(colors),
                "</svg>"
            )
        );

        string memory output = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Mainframe #',
                        Strings.toString(tokenId),
                        '", "attributes":',
                        attributes,
                        ',"description":"',
                        DESCRIPTION,
                        '","image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(image)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", output)
        );

        return output;
    }

    function generatePaths(uint256 face) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<path fill="url(#a)" d="M0 0h1024v1024H0z"/><path fill="#fff" fill-rule="evenodd" d="M232.808 240.339c0-11.311 9.169-20.48 20.48-20.48h453.205a114.895 114.895 0 0 1 114.898 114.898v9.437l51.846 44.251c14.234 12.196 23.688 28.902 23.688 47.842v111.14c0 22.997-13.635 41.537-31.031 53.441-6.429 4.4-13.605 8.093-21.326 11.005A105.455 105.455 0 0 1 808.2 807.106a20.43 20.43 0 0 1-7.289 1.336H83.336c-10.793 0-19.636-8.35-20.423-18.942a20.476 20.476 0 0 1-18.94-20.422v-37.767a20.48 20.48 0 0 1 14.003-19.429l174.832-58.277V618.01c0-3.316.804-6.548 2.304-9.437a20.396 20.396 0 0 1-2.304-9.447V240.339z" clip-rule="evenodd"/><path fill="url(#b)" d="M253.287 240.339h453.205v358.787H253.287V240.339zM253.287 618.01h453.205v169.952H253.287V618.01z"/><path fill="url(#c)" d="M773.256 267.993a94.418 94.418 0 0 0-66.764-27.654v358.787h94.418V334.757a94.42 94.42 0 0 0-27.654-66.764zM706.492 618.01h84.976a84.976 84.976 0 0 1 0 169.952h-84.976V618.01z"/><path fill="url(#d)" d="m668.724 655.777-226.603 75.534v37.767h358.787v-75.534l-132.184 49.569v-87.336z"/><path fill="url(#e)" d="M64.451 731.311h377.671v37.767H64.452v-37.767zM536.539 750.194H649.84v18.884H536.539v-18.884z"/><g fill="url(#f)"><path d="M291.054 655.777 64.451 731.312h377.671l226.603-75.535H291.054zM687.607 693.544l-151.068 56.651H649.84l151.069-56.651H687.607z"/></g><g fill="url(#g)"><path d="M668.726 278.105H291.055v283.254h377.671V278.105zM272.17 599.126h509.856v18.884H272.17v-18.884zM83.123 769.205h718.005v18.673H83.123v-18.673zM859.913 403.996l-59.001-50.356v245.465c41.733 0 75.534-23.143 75.534-51.678v-111.14c0-11.75-5.833-23.122-16.533-32.291z"/></g>',
                    SVGFace.pickSVGFacePath(face)
                )
            );
    }

    function generateDefs(Colors.MainframeColors memory colors)
        internal
        pure
        returns (string memory)
    {
        string memory parts = string(
            abi.encodePacked(
                '<defs><linearGradient id="a" x1="512" x2="512" y1="0" y2="1024" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.bg.start,
                '"/><stop offset="1" stop-color="',
                colors.bg.end,
                '"/></linearGradient><linearGradient id="b" x1="479.89" x2="479.89" y1="240.339" y2="787.962" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.light.start,
                '"/><stop offset="1" stop-color="',
                colors.light.end,
                '"/></linearGradient><linearGradient id="c" x1="791.468" x2="791.468" y1="240.339" y2="787.962" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.medium.start,
                '"/><stop offset="1" stop-color="',
                colors.medium.end,
                '"/></linearGradient><linearGradient id="d" x1="710" x2="665.834" y1="633" y2="782.198" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.light.start
            )
        );

        parts = string(
            abi.encodePacked(
                parts,
                '"/><stop offset="1" stop-color="',
                colors.light.end,
                '"/></linearGradient><linearGradient id="e" x1="357.146" x2="357.146" y1="720" y2="769.078" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.light.start,
                '"/><stop offset="1" stop-color="',
                colors.light.end,
                '"/></linearGradient><linearGradient id="f" x1="432.68" x2="432.68" y1="655.777" y2="750.195" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.light.start,
                '"/><stop offset="1" stop-color="',
                colors.light.end,
                '"/></linearGradient><linearGradient id="g" x1="479.785" x2="479.785" y1="278.105" y2="787.878" gradientUnits="userSpaceOnUse"><stop stop-color="',
                colors.dark.start,
                '"/><stop offset="1" stop-color="',
                colors.dark.end,
                '"/></linearGradient></defs>'
            )
        );

        return parts;
    }

    function generateAttributes(uint256 face)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{ "trait_type": "Face",',
                    '"value": "',
                    SVGFace.pickSVGFaceName(face),
                    '"}',
                    "]"
                )
            );
    }

    function mint(address destination) public onlyOwner {
        _mint(destination);
    }

    function mintMainframe() public payable virtual {
        require(msg.value >= cost, "PRICE_NOT_MET");
        _mint(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
