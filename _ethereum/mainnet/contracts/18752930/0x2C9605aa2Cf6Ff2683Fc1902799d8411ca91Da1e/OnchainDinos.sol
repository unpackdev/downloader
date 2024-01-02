// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./ERC721A.sol";
import "./NFTEventsAndErrors.sol";
import "./Utils.sol";
import "./Constants.sol";
import "./LibString.sol";
import "./LibPRNG.sol";
import "./SVG.sol";

/// @title onchain dinos
/// @notice onchain dinos is an onchain generative dino NFT inspired by tiny dinos. rawr.
contract OnchainDinos is ERC721A, NFTEventsAndErrors, Constants {
    using LibString for uint256;
    using LibString for uint8;
    using LibPRNG for LibPRNG.PRNG;

    address private immutable _deployer;
    bytes32[MAX_DINOS + 1] internal _tokenToSeed;

    uint8[39] internal colors = [
        3,
        3,
        3,
        3,
        3,
        3,
        3,
        3,
        5,
        2,
        2,
        2,
        2,
        2,
        1,
        2,
        1,
        2,
        5,
        2,
        2,
        2,
        2,
        2,
        2,
        4,
        4,
        2,
        5,
        2,
        2,
        4,
        2,
        2,
        2,
        4,
        4,
        2,
        2
    ];
    uint8[39] internal x = [
        6,
        10,
        7,
        8,
        6,
        7,
        8,
        9,
        5,
        6,
        7,
        8,
        9,
        6,
        7,
        8,
        9,
        10,
        5,
        6,
        7,
        8,
        9,
        10,
        6,
        7,
        8,
        4,
        5,
        6,
        7,
        8,
        9,
        5,
        6,
        7,
        8,
        6,
        8
    ];
    uint8[39] internal y = [
        3,
        4,
        3,
        3,
        4,
        4,
        4,
        4,
        5,
        5,
        5,
        5,
        5,
        6,
        6,
        6,
        6,
        6,
        7,
        7,
        7,
        7,
        7,
        7,
        8,
        8,
        8,
        9,
        9,
        9,
        9,
        9,
        9,
        10,
        10,
        10,
        10,
        11,
        11
    ];

    constructor() ERC721A("onchain dinos", "DINO") {
        _deployer = msg.sender;
    }

    /// @notice Mint tokens.
    /// @param amount amount of tokens to mint
    function mint(uint8 amount) external payable {
        // Checks
        unchecked {
            if (amount * PRICE != msg.value) {
                // Check payment by sender is correct
                revert IncorrectPayment();
            }

            uint256 nextTokenId = _nextTokenId();

            if (MAX_DINOS + 1 < nextTokenId + amount) {
                // Check max supply not exceeded
                revert MaxSupplyReached();
            }

            // Effects
            for (uint256 i = nextTokenId; i < nextTokenId + amount;) {
                _tokenToSeed[i] = keccak256(abi.encodePacked(block.prevrandao, i));
                ++i;
            }
        }

        _mint(msg.sender, amount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Withdraw all ETH from the contract.
    function withdraw() external {
        (bool success,) = _deployer.call{ value: address(this).balance }("");
        require(success);
    }

    function getColors(uint256 tokenId)
        public
        view
        returns (string memory dinoColor, string memory prevDinoColor, string memory backgroundColor)
    {
        LibPRNG.PRNG memory dinoPrng;
        dinoPrng.seed(_tokenToSeed[tokenId]);
        uint256 dinoHue = dinoPrng.uniform(360);
        dinoColor = Utils.hslaString(dinoHue, 25 + dinoPrng.uniform(70), 65 + dinoPrng.uniform(15));

        if (tokenId > 1) {
            LibPRNG.PRNG memory prevDinoPrng;
            prevDinoPrng.seed(_tokenToSeed[tokenId - 1]);
            prevDinoColor = Utils.hslaString(
                prevDinoPrng.uniform(360), 25 + prevDinoPrng.uniform(70), 65 + prevDinoPrng.uniform(15)
            );
        } else {
            prevDinoColor = "#FFF";
        }

        backgroundColor = Utils.hslaString((dinoHue + 180) % 360, 60, 80);
    }

    function art(uint256 tokenId) public view returns (string memory) {
        (string memory bodyColor, string memory hatColor, string memory backgroundColor) = getColors(tokenId);

        string memory dino = "";
        unchecked {
            for (uint8 i; i < x.length; ++i) {
                string memory color = colors[i] == 1
                    ? "#FFF"
                    : colors[i] == 2
                        ? bodyColor
                        : colors[i] == 3 ? hatColor : colors[i] == 4 ? "#DBDBDB" : colors[i] == 5 ? "#EDEDED" : "";
                dino = string.concat(
                    dino,
                    SVG.rect(
                        string.concat(
                            SVG.prop("fill", color),
                            SVG.prop("x", x[i].toString()),
                            SVG.prop("y", y[i].toString()),
                            i == 0 ? SVG.prop("id", "a") : i == 1 ? SVG.prop("id", "b") : ""
                        )
                    )
                );
            }
        }

        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" shape-rendering="crispEdges" viewBox="0 0 16 16" style="background-color: ',
            backgroundColor,
            '">',
            dino,
            "</svg>"
        );
    }

    /// @notice Get token uri for token.
    /// @param tokenId token id
    /// @return tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        string memory artSvg = art(tokenId);

        return Utils.formatTokenURI(
            tokenId,
            Utils.svgToURI(artSvg),
            string.concat(
                "data:text/html;base64,",
                Utils.encodeBase64(
                    bytes(
                        string.concat(
                            '<html style="overflow:hidden"><body style="margin:0">',
                            artSvg,
                            '<script>document.body.addEventListener("click",()=>{let t,e;"6"===document.getElementById("a").getAttribute("x")?(t="9",e="5"):(t="6",e="10"),document.getElementById("a").setAttribute("x",t),document.getElementById("b").setAttribute("x",e)});</script></body></html>'
                        )
                    )
                )
            ),
            string.concat("[", Utils.getTrait("metadata", "onchain", true), Utils.getTrait("dino", "rawr", false), "]")
        );
    }
}
