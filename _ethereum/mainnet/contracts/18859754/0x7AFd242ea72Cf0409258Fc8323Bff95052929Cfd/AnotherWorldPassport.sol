// SPDX-License-Identifier: MIT
//
// AnotherWorldPassport.sol
//

pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";

contract AnotherWorldPassport is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant maxAmount = 100;

    constructor() ERC721A("AnotherWorldPassport", "AWP") {}

    function _mintbatch(address account, uint256 quantity) internal {
        _mint(account, quantity);
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        require(maxAmount >= quantity, "exceeded max airdrop amount");
        _mintbatch(to, quantity);
    }

    function getTier(uint256 tokenId) internal view returns (uint256) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, block.prevrandao))
        ) % 20;
        return
            rand > 9
                ? (rand > 13 ? (rand > 16 ? (rand > 18 ? 5 : 4) : 3) : 2)
                : 1;
    }

    function getTierLabel(uint256 tier) internal pure returns (string memory) {
        return
            tier != 1
                ? (
                    tier != 2
                        ? (
                            tier != 3
                                ? (
                                    tier != 4
                                        ? (tier != 5 ? "" : "Family")
                                        : "Council"
                                )
                                : "Officer"
                        )
                        : "Guardian"
                )
                : "Citizen";
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(tokenId < totalSupply(), "invalid tokenId");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"#',
                                tokenId.toString(),
                                " ",
                                getTierLabel(getTier(tokenId)),
                                '", ',
                                '"attributes": [',
                                traits(tokenId),
                                "],",
                                '"external": "https://anotherworld.gg",',
                                '"description":"',
                                "Another World Passport grants you a special status in Another World.",
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(
                                    bytes(
                                        svgOutput(
                                            tokenId,
                                            getTierLabel(getTier(tokenId))
                                        )
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getLogoTrait(
        uint256 tokenId
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "dripping"))
        );
        if (rand % 100 > 90) {
            return "Dripping";
        } else {
            return "OG";
        }
    }

    function getSpecial1(
        uint256 tokenId
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "Special1"))
        );
        if (rand % 201 < 2) {
            return "Green Lasers";
        } else if (rand % 201 < 4) {
            return "Red Lasers";
        } else if (rand % 201 < 8) {
            return "Green Laser";
        } else if (rand % 201 < 13) {
            return "Red Laser";
        } else {
            return "";
        }
    }

    function getSpecial1SVG(
        uint256 tokenId
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "Special1"))
        );
        string
            memory seg0 = '<g transform="translate(-155 -29)"><line x1="0" y1="0" x2="300" y2="300" stroke-width="1.5" stroke-opacity="1.0" stroke="';
        string
            memory seg1 = '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 300 300" to="360 300 300" dur="1';
        string memory seg2 = 's" repeatCount="indefinite"/></line></g>';
        if (rand % 201 < 2) {
            return
                string(
                    abi.encodePacked(
                        seg0,
                        "green",
                        seg1,
                        "9",
                        seg2,
                        seg0,
                        "green",
                        string(abi.encodePacked(seg1, "7", seg2))
                    )
                );
        } else if (rand % 201 < 4) {
            return
                string(
                    abi.encodePacked(
                        seg0,
                        "red",
                        seg1,
                        "9",
                        seg2,
                        seg0,
                        "green",
                        string(abi.encodePacked(seg1, "7", seg2))
                    )
                );
        } else if (rand % 201 < 8) {
            return string(abi.encodePacked(seg0, "green", seg1, "9", seg2));
        } else if (rand % 201 < 13) {
            return string(abi.encodePacked(seg0, "red", seg1, "9", seg2));
        } else {
            return "";
        }
    }

    function getSpecial2(
        uint256 tokenId
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "Special2"))
        );
        if (rand % 101 < 3) {
            return "Shooting Stars!";
        } else if (rand % 101 < 7) {
            return "Shooting Stars";
        }
        if (rand % 101 < 12) {
            return "Shooting Star";
        } else {
            return "";
        }
    }

    function getSpecial2SVG(
        uint256 tokenId
    ) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "Special2"))
        );
        string
            memory seg0 = '<path stroke="#fff" d="M145 0v3"><animateTransform attributeName="transform" attributeType="XML" type="translate" from="';
        string memory seg1 = ' 0" to="';
        string memory seg2 = ' 1600" dur="';
        string memory seg3 = 's" repeatCount="indefinite"/></path>';
        if (rand % 101 < 3) {
            return
                string(
                    abi.encodePacked(
                        string(
                            abi.encodePacked(
                                seg0,
                                "50",
                                seg1,
                                "-750",
                                seg2,
                                "3.5",
                                seg3
                            )
                        ),
                        string(
                            abi.encodePacked(
                                seg0,
                                "100",
                                seg1,
                                "-700",
                                seg2,
                                "4",
                                seg3
                            )
                        ),
                        string(
                            abi.encodePacked(
                                seg0,
                                "150",
                                seg1,
                                "-650",
                                seg2,
                                "4.5",
                                seg3
                            )
                        )
                    )
                );
        } else if (rand % 101 < 7) {
            return
                string(
                    abi.encodePacked(
                        string(
                            abi.encodePacked(
                                seg0,
                                "50",
                                seg1,
                                "-750",
                                seg2,
                                "3.5",
                                seg3
                            )
                        ),
                        string(
                            abi.encodePacked(
                                seg0,
                                "150",
                                seg1,
                                "-650",
                                seg2,
                                "4.5",
                                seg3
                            )
                        )
                    )
                );
        } else if (rand % 101 < 12) {
            return
                string(
                    abi.encodePacked(
                        seg0,
                        "50",
                        seg1,
                        "-750",
                        seg2,
                        "3.5",
                        seg3
                    )
                );
        } else {
            return "";
        }
    }

    function traits(uint256 tokenId) internal view returns (string memory) {
        string memory traitTypeJson = '{"trait_type": "';
        string memory attrSpecial1 = "";
        string memory attrSpecial2 = "";
        string memory attrLogoTrait = string(
            abi.encodePacked(
                traitTypeJson,
                'LOGO", "value": "',
                getLogoTrait(tokenId),
                '"}, '
            )
        );

        string memory s1 = getSpecial1(tokenId);
        if (bytes(s1).length > 0) {
            attrSpecial1 = string(
                abi.encodePacked(
                    traitTypeJson,
                    'SPECIAL1", "value": "',
                    s1,
                    '"}, '
                )
            );
        }

        string memory s2 = getSpecial2(tokenId);
        if (bytes(s2).length > 0) {
            attrSpecial2 = string(
                abi.encodePacked(
                    traitTypeJson,
                    'SPECIAL2", "value": "',
                    s2,
                    '"},'
                )
            );
        }

        string memory attrType0 = string(
            abi.encodePacked(
                traitTypeJson,
                'TIER", "value": "T',
                getTier(tokenId).toString(),
                " ",
                getTierLabel(getTier(tokenId)),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    attrLogoTrait,
                    attrSpecial1,
                    attrSpecial2,
                    attrType0
                )
            );
    }

    function svgOutput(
        uint256 tokenId,
        string memory tokenName
    ) internal pure returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(tokenId, "another")));
        string[11] memory svgParts;
        svgParts[0] = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="290" height="500" viewBox="0 0 290 500"><defs><linearGradient id="backgroundGradient" x1="100%" y1="100%"><stop offset="95%" stop-opacity="95%"><animate attributeName="stop-color" values="'
            )
        );
        svgParts[1] = string(
            abi.encodePacked(
                "white;",
                (rand % 10 < 2) ? "green;yellow" : (rand % 10 > 6)
                    ? "green"
                    : "yellow",
                ";white;",
                (rand % 10 < 2) ? "green;yellow" : (rand % 10 > 8)
                    ? "pink"
                    : "yellow",
                ";white"
            )
        );
        svgParts[
            2
        ] = '" dur="60s" repeatCount="indefinite"/></stop></linearGradient><linearGradient id="patternGradient" x1="100%" y1="100%"><stop offset="0%" stop-opacity=".3"><animate attributeName="stop-color" values="';
        svgParts[3] = string(
            abi.encodePacked(
                "gray;",
                (rand % 10 > 5)
                    ? "green;yellow;white;green;blue;purple;red"
                    : (rand % 10 < 3)
                    ? "yellow;white;green"
                    : "white;pink;yellow;",
                ";black;gray"
            )
        );
        svgParts[4] = string(
            abi.encodePacked(
                '" dur="60s" repeatCount="indefinite"/></stop></linearGradient><pattern id="Pattern" x="0" y="0" width=".',
                (rand % 23 > 12) ? "09" : "1",
                '" height=".',
                (rand % 21 < 12) ? "09" : "1",
                '"><rect width="100%" height="100%" fill="hsla(0,0%,0%,1)"/><path d="M0,28 L20,28 L20,16 L16,16 L16,24 L4,24 L4,4 L32,4 L32,32 L28,32 L28,8 L8,8 L8,20 L12,20 L12,12 L24,12 L24,32 L0,32 L0,28 Z M12,36 L32,36 L32,40 L16,40 L16,64 L0,64 L0,60 L12,60 L12,36 Z M28,48 L24,48 L24,60 L32,60 L32,64 L20,64 L20,44 L32,44 L32,56 L28,56 L28,48 Z M0,36 L8,36 L8,56 L0,56 L0,52 L4,52 L4,40 L0,40 L0,36 Z" stroke-linecap="square" stroke="url(#patternGradient)" fill="none"/></pattern></defs><defs><linearGradient id="a"><stop offset=".7" stop-color="#fff"/><stop offset=".95" stop-color="#fff" stop-opacity="0"/></linearGradient><clipPath id="b"><rect width="290" height="500" rx="42" ry="42"/></clipPath><path id="e" d="M40 12h210a28 28 0 0 1 28 28v420a28 28 0 0 1-28 28H40a28 28 0 0 1-28-28V40a28 28 0 0 1 28-28z"/></defs><g fill="url(#Pattern)" clip-path="url(#b)"><path fill="0" d="M0 0h290v500H0z"/>'
            )
        );
        svgParts[5] = (rand % 100 == 0)
            ? '<path stroke="#fff" d="M145 0v3"><animateTransform attributeName="transform" attributeType="XML" type="translate" from="0 250" to="0 -600" dur="14s" repeatCount="indefinite"/></path>'
            : "";
        svgParts[6] = getSpecial2SVG(tokenId);
        svgParts[7] = logoSVG(tokenId);
        svgParts[8] = getSpecial1SVG(tokenId);
        svgParts[
            9
        ] = '</g><text font-family="Arial, Helvetica, sans-serif" y="59" x="35" fill="#fff" font-size="35">Another World</text><text font-family="monospace" y="100" x="35" font-weight="200" font-size="25" fill="rgba(200,200,200,0.75)">';
        svgParts[10] = string(
            abi.encodePacked(
                '#',
                tokenId.toString(),
                ' ',
                tokenName,
                '</text><text font-family="monospace" y="490" x="42" font-weight="200" font-size="25" fill="rgba(200,200,200,0.35)">P A S S P O R T</text></svg>'
            )
        );
        return
            string(
                abi.encodePacked(
                    svgParts[0],
                    svgParts[1],
                    svgParts[2],
                    svgParts[3],
                    svgParts[4],
                    svgParts[5],
                    svgParts[6],
                    svgParts[7],
                    string(
                        abi.encodePacked(svgParts[8], svgParts[9], svgParts[10])
                    )
                )
            );
    }

    function logoSVG(uint256 tokenId) internal pure returns (string memory) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(tokenId, "dripping"))
        );
        return
            string(
                abi.encodePacked(
                    '<g stroke="black" transform="translate(0 -5)"><path opacity=".959" fill="#FEFFFE" enable-background="new" d="M192.125 301.344c.403 1.86 2.563 6.219-.6 7.106-2.775.175-5.124.218-6.573.223-2.798.01-5.565.105-8.358.208-1.813.067-4.15.075-5.489-1.38-.76-2.818-1.193-5.715-1.504-8.613-.702-6.549-1.159-13.113-1.911-19.66-1.535-13.369-3.15-26.755-4.318-40.162-.25-2.861-.432-5.753-1.171-8.541-1.449-.611-3.748-.622-5.274-.402-5.696.817-11.313 1.111-17.082.948-2.669-.076-11.718-1.146-12.571-.443-1.156.953-1.555 3.908-1.695 5.327a688.385 688.385 0 0 1-1.254 11.64c-.93 7.992-1.897 15.973-2.752 23.972a9917.45 9917.45 0 0 0-2.084 19.661c-.296 2.817-.605 5.619-.711 8.451-.09 2.388.094 6.005-1.546 7.969-1.202 1.44-3.391 1.108-5.035 1.032-2.962-.138-5.955.004-8.92-.012-1.934-.011-4.464.364-6.348-.287-2.361-.816-.902-4.615-.553-6.216 2.852-13.086 6.016-26.112 8.993-39.171a5121.55 5121.55 0 0 0 4.307-19.012c.712-3.179 3.993-15.648 2.436-16.625-4.616-2.895-11.059-2.148-15.477-5.338-1.55-1.119-1.473-2.299-1.195-4.027.209-1.303.613-2.479 1.125-3.679.872-2.042.896-1.917 2.208-3.896.694-.887.771-.667 1.333-.5.376.111 8.134 2.354 8.988 2.771.938.25 2.351.875 7.645 2.052 6.832 1.521 13.841 2.366 20.827 2.714 13.005.649 26.448-.359 38.967-4.091 2.749-.82 10.747-4.338 12.061-2.714 1.941 2.401 4.663 7.102 3.61 9.772-2.457 6.232-13.078 2.704-16.554 8.511-.013.021 2.353 11.912 1.606 8.558"/><path opacity=".949" fill="#FEFFFE" enable-background="new" d="M160.475 243.575c.927 1.539 3.221 9.174-.207 8.84-2.449-.239-5.518-3.484-7.742-.965 1.82.702 3.772 1.475 5.152 2.911.879.914 2.722 5.031.247 5.264-2.126-1.758-4.716-3.749-7.274-1.5-1.907 3.83 4.422 4.5 6.734 5.388 4.117 1.579 6.508 4.02 7.366 8.363.78 3.951.694 8.017.81 12.023.145 5.078-2.397 1.615-4.76-.112-.942-.688-6.546-3.88-5.583-.77 1.02 3.295 2.243 6.571 2.714 10.006 1.117 8.145-5.655 15.234-14.106 13.477-1.07-1.221 3.505-3.699 4.325-4.739.69-.875 3.413-5.791 1.675-6.586-4.13 2.988-6.854 8.2-12.333 8.972-2.544.359-5.253.04-7.549-1.155-.946-.493-5.41-4.156-2.094-3.956 2.136.129 4.537.52 6.566-.378 3.194-1.411 1.099-2.618-1.206-2.932-4.431-.603-12.479-5.577-9.86-11.051 1.596-1.074 3.956-.273 5.679-.028.864.123 7.003-.602 4.785-2.482-1.808-1.534-4.259-1.517-6.054-3.292-2.188-2.164-3.396-4.914-3.423-7.96-.014-1.594.27-6.873 2.769-4.47 1.467 1.41 6.479 4.998 5.43.359-1.339-5.918-1.449-11.619.267-17.458 1.065-3.625 2.655-9.186 6.305-11.076 2.231-1.155 1.905.472 1.746 2.108-.397 2.318-.681 4.276-.531 6.705.047.77.57 5.293 1.806 4.968 1.824-.48 3.323-3.276 4.382-4.664 2.937-3.851 9.708-6.619 13.964-3.81 1.365 2.267-.223-.147 0 0z"/>',
                    rand % 100 > 90
                        ? '<path fill="url(#backgroundGradient)" stroke-width="1" d="M188.42 224.947c-1.251 1.361-2.538 2.811-3.235 4.55-1.4 3.498 1.369 7.788 2.171 11.189.364 1.543.852 3.673.042 5.151-.908 1.655-2.63.92-3.266-.543-1.017-2.34.097-7.723-3.978-7.552-1.633.069-2.444 1.982-2.595 3.367-.239 2.183.74 4.416 1.359 6.466 1.024 3.397 2.826 7.99 1.733 11.57-.829 2.713-4.957 3.128-6.318.548-1.859-3.522-.968-7.666-1.133-11.463-.151-3.48-1.436-6.5-4.481-8.37-4.033-2.48-3.896 6.658-3.9 8.755-.004 2.119.248 4.258.693 6.329.475 2.207 1.426 4.296 1.555 6.574.08 1.401-.115 2.986-1.68 3.424-1.137.318-3.108.12-3.784-.975-.63-1.019-.506-2.352-.498-3.496.015-2.312.16-4.636-.137-6.937-.188-1.452-1.811-9.7-4.608-6.933-2.606 2.578.859 7.314 1.024 10.3.19 3.43-4.417 4.714-6.205 1.853-2.342-3.746 1.062-7.498.569-11.348-.405-3.16-.936-7.858-4.38-9.128-2.894-1.068-6.32-.414-9.346-.61-2.07-.135-4.143-.213-6.214-.038-1.288.109-2.9.275-3.862 1.245-2.465 2.488 1.889 6.76-.794 9.1-.905.79-2.364 1.187-3.478.613-1.544-.796-1.387-2.877-1.18-4.322.434-3.006 2.515-8.765-.376-11.068-4.144-3.3-5.71 3.47-5.51 6.35.237 3.416 3.316 12.849-2.405 13.615-.722.097-1.551.193-2.036-.393-.54-.652-.973-1.398-1.177-2.225-.457-1.85.325-3.611.99-5.298.713-1.805 1.375-3.73 1.324-5.697-.041-1.615-.875-3.306-1.4-4.833-.358-1.043-.905-2.477-2.083-2.82-1.632-.477-2.935 1.363-3.682 2.521a20.115 20.115 0 0 0-2.462 5.411c-.534 1.886-.337 3.931-.289 5.867.034 1.342.088 2.843-.5 4.087-.53 1.123-2.52 1.923-3.553.955-1.081-1.013-.938-3.545-.829-4.893.164-2.006 1.129-3.828 1.64-5.75.944-3.539.431-7.72-1.146-10.977-.51-1.052-3.76-7.725-1.278-7.785 2.047-.05 4.204 1.01 6.083 1.714 3.714 1.394 7.834 2.131 11.72 2.872 18.407 3.51 37.248 2.487 55.65-.486 4.168-.673 8.288-1.545 12.43-2.356 1.762-.345 3.596-.649 5.261-1.34.73-.302 1.187-1.088 1.983-.998 1.056.12-1.835 3.56-2.43 4.208z"/>'
                        : "",
                    "</g>"
                )
            );
    }
}
