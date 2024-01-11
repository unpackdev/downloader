// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./IPublicSharedMetadata.sol";
import "./IMetadataRenderer.sol";
import "./IOwnable.sol";
import "./ERC721Delegated.sol";
import "./ERC721Base.sol";

/// @notice Custom on-chain renderer for Ken Knowlton
/// @author (artist) Ken Knowlton kenknowlton.com
/// @author (preservation) Jim Boulton digital-archaeology.org
/// @author (smart contract) Iain Nash iain.in
/// @author (coordinator) Rhizome rhizome.org
contract KenKnowltonJulieMartinRenderer is ERC721Delegated {
    /// @notice Textual representation of artwork
    bytes private constant portrait =
        "7f7f7f6e6e5c3b5e6f7f7f6e6f6d6e7f7f7f"
        "f7f7f7e6e5c3a3d5d5d5e6e6e7e5c5c7f7f7"
        "7f7f7d5d5c3b3d4d6e6d5d6e6e7e4c4c7f7f"
        "f7f7e4d5d4b3d6f7f7f7e5e6e6e6e5c4e7f7"
        "7f7f7c4d5c3c7f7f7f7f7e6e6e6e5e5c5f7f"
        "f7f7e5e6d4c7f7f7f7f7f7f6e6d5c5d3c7f7"
        "7d6d6e5d3b6f7f7f7f7f7f7f6e6d4c5c3d7f"
        "f6d4d4c3b5f7f7f7f7f7f7f7f6d6c3b4b3f7"
        "7e5d4c3a5f7f7f7f7f7f7f7f7e6d5c2b3b6f"
        "f6e5c3a3f7f7f7f7f7f7f7f7f7e5e592a3d7"
        "5d4b2a2d7f7f7f7f7f7f7f7f7f7e6d292a3f"
        "c2a2a3b5e7f7f7f7f7f7f7f7f7f7e5b1a297"
        "2a4c3c4d6f7f7f7f7f7f7f7f7f7e7d49191e"
        "b3b3c4c5e6f6d5c5e7f7f7f5b4c5e5b291a7"
        "291b4c4d6d5d5b2a3e7f7e4a1a3c4d3a292f"
        "81a2c4c5a3c4b291a4e7e4a3a1a3a192a1a7"
        "191b4b4a4d5d6d5c2b6f6b2d5d3b4b393a1c"
        "81a3b2b3d5c3a2c5c2c7c1c6c3b3b3c293a3"
        "2a2a291e6d3a193b4c1b2a4c291a3c4c1b2a"
        "d2a291a7e5b5e6e5d495a3c5d5d3b4d591b3"
        "59198b2f6d6f7f6e7b3f4a4d6f7f6c4d192c"
        "d291a496e7f7e6e7f1e7e1d6d6e7d6e49195"
        "6b193d3c7f7f7f7f4b7f7b3f7f7f7f7b2a1d"
        "f291b4c2f7f7f7f5a5f7f5a5f7f7f6e1a285"
        "7b193a4b3e6f6e4a4e7f7e3a3d6e5e3a2a1e"
        "f291a1c4b3c4c4d4f6e7f6d292a2a3b3a2a7"
        "7b19194c5e7f7f4c4b2b4b2a2e6e4a3b1a2f"
        "f4a292c5d6f7e4b6b292a2a3c3e5c3a392c7"
        "7e3b1a4d5d5d4a4f7d3a2a3c5a3c3a2b1a6f"
        "f7d492c4c4b292e7f7e4b3c5c292a2a392f7"
        "7f6d3a4b3b391a4d5e6d3b3b291a2a2b2b7f"
        "f7f5c3b3b3c39181b3c4c3b181b3a2a3a4f7"
        "7f7e5d4b3b4c3c5c6f7f7d492b6d3a2a2d7f"
        "f7f7d5d3b4c5d7f7c4d5e494c4e5c3a2c7f7"
        "7f7f7c3d3c5d5e6f7f4b3c5d4c5c5b4c7f7f"
        "f7f7f7f7c3d4d6d5e6e6e6d3b3c3c4f7f7f7"
        "7f7f7f7f5b4c4d5c3b3b3b2a3b3b3e7f7f7f"
        "f7f7f7f7d3b4c5e4b2a2a292c3a4b7f7f7f7"
        "7f7f7f7f5b4c3c5e5c4b3a2c3b2b5f7f7f7f"
        "f7f7f7f7e3b4a2c6e6e6d4c4a1a2e7f7f7f7"
        "7f7f7f7f6a3b292c5d5d4c4a192a7f7f7f7f"
        "f7f7f7f7e2b3b281a3b4b2a191a2f7f7f7f7"
        "7f7f7f7f6b3b4b28191919191a2a7f7f7f7f"
        "f7f7f7f7e2a3c3b1819191919192f7f7f7f7";

    /// @notice License for the artwork within
    function license() public pure returns (string memory) {
        return
            unicode"Any buyer(s) of this NFT acknowledges and agrees that the rendered output image, non-generic input symbols and algorithm are the intellectual property of Ken Knowlton. The buyer shall have a non-exclusive, royalty-free, worldwide license to publicly display the rendered output image and on-chain data of this NFT. Any buyer(s) of the NFT further acknowledges and agrees that Ken Knowlton owns certain Intellectual Property rights related to the Knowlton & Harmon Computer Nude (the image, non-generic symbols, and algorithm) and that Ken Knowlton is not transferring any such rights to the buyer(s) of the NFT.";
    }

    string private constant contractName =
        "Studies in Perception IV: Julie Martin";

    /// @dev Rendering utility
    IPublicSharedMetadata private immutable sharedMetadata;

    /// @notice constructor that saves the metadata renderer reference
    /// @dev Deploy with the bound as the deployer of the final metadata contract
    constructor(
        address _rootImpl,
        IPublicSharedMetadata _sharedMetadata,
        address _owner
    )
        ERC721Delegated(
            _rootImpl,
            "Studies in Perception IV",
            "SP4JM",
            _owner,
            ConfigSettings({
                royaltyBps: 2000,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {
        sharedMetadata = _sharedMetadata;
    }

    function mint() external onlyOwner {
        _mint(_owner(), 1);
    }

    /// @notice Get template for image as text rendering proper style tags for SVG
    /// @return string memory text spans
    function getTemplate() private pure returns (bytes memory) {
        bytes memory parts;
        for (uint256 i = 0; i < portrait.length / 36; ++i) {
            bytes memory chars;
            for (uint256 k = 0; k < 36; ++k) {
                chars = abi.encodePacked(chars, portrait[i * 36 + k]);
            }
            parts = abi.encodePacked(
                parts,
                '<tspan x="0" dy="10px">',
                chars,
                "</tspan>"
            );
        }
        return parts;
    }

    /// @notice Getter for the final SVG image result
    /// @return string memory image as svg raw text
    function getImage() private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<svg viewBox="0 0 360 440" width="100%" height="100%" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg"><style>@font-face {font-family: A; src: url(\'',
                "data:font/woff;base64,d09GRgABAAAAAAWkAAoAAAAAEbwAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAABPUy8yAAAA9AAAADwAAABgWNNqH2NtYXAAAAEwAAAAPQAAALQAqwJEZ2x5ZgAAAXAAAAK4AAANZIHzWjFoZWFkAAAEKAAAACsAAAA2YWAwEGhoZWEAAARUAAAAHAAAACQOAQoTaG10eAAABHAAAAAWAAAASLQABgBsb2NhAAAEiAAAAEEAAABMAAB5CG1heHAAAATMAAAAGAAAACAAJgBwbmFtZQAABOQAAACpAAABaHNiTX5wb3N0AAAFkAAAABQAAAAgAGkANHicY2DiYmCcwMDKwMLEwMQAAhAaiI0ZzoD4LAxwwMiABCIdffQYHBgUGNL+AXlsDP8w1SgwMAAA9LMFsnicY2BgYGJgYGAGYhEgyQikUxhYGAKANAcQguQUGCwZ0v7/B7MMGRL/////6P+l/6vBaokDVDYPAFBZFuIAAAB4nLVWv2/VMBD+Yuf9SIpUoQoxIMTQgYEBMTB0QAhVCDF06MDAxMTAwL9P1fYl4WLf2edL0veeCon8znbO57v7zp8fGtDT0ot3eI8LfMAnfMZXXOEaqP79g5r2q6g5lmMbjOy5r5ue741+Vei5ma96x3uWHcs66cRVrfFoYN0BpWfLHkTpzP4yP+4nmv3EUjk/mPk19+ATbmd4gfPDsPJhb52fMZ6dikvylKPxM5G0e1bLLkOBoKcsdsYSeS9xnOApnuElXnMlfsQlvoQ6/Ibv+IGf+IXf/6UmH3im6MVWc3y5PyKms+ooM3pdz/iV47Hd8NyK7eR1PeUsfnMsfToHeZ3V2Smdterv+Lv4oOvcIiiRSh9AgZ2uEL2uU+NK2a6UHW3bnuTe2J/71s/YtvrhoMS6OqUae05n5BXeHl89dapnYQGp+SpU9GAwkByvWN4FuVYe7wobLY9sHiTvGhedv6Vxrj7Oy3qUDb2Uh5iFczphB+ehTgzZoUS8C/O7Auku1WDNsjKyMZYsh1rm9wvxJukr0tnSS2JDHIKp9wPtuCF5m1Daml2GbLWuJF/R3uk0V9lqlBszbhawk7gjMKE2fbQeGfUP/4bHJZ0Twm0RLxQVJLt2nH9pnu3WQVuq16lV4zPeiyseS1/dM57Y+YjKkZisH7q67a3qjF6ldCQ3TZgR3zWH5Ln7wqLW82qMJym2iPSZOiFviC0uHnPbZOaImRdmcHvk7YF6NwnLPjV9L1s2fkjiQD3734vXaq7N2Ts6d664L6eMtkp1I2iWrCnnrzI2hKNbZfFO9eXfyjLLx+/6LtRVK2OsI3e0j+Laufi74IVLbDjHnlOubbHE2vl/r77Ttc4s1zYukOI2c2M+MQdFaW8HQcwZpAYz35l1wt/7bsWleTWux36jYzqa78WbJb7/C3DSZl54nGNgZGBgAOIDfL3m8fw2XxkYWBhAoEatqBOZ5gJCIOBgYAKpBgDYLgaRAHicY2BkYPjHwMDAxsDFAAJAkpEBFQgBACKeAS14nONiYGDgwosZoRiXHBOYBgAbYAC7AAB4nGNgQAeMOxgYmBoYGFhuMDCwPmBgYDvAwMAuAMQlQDyDgYFDAYj/MDBwuTAwcPswMPDoMDDwAvXxpgAAAasHewAAAHicY2BkYGAQYshjEGYAASYGNAAADroAl3icjY5BCoMwEEV/NCiF0k27KF25KrqTrKQH6AGkFxAJLiIJiCL0GF30MD1dPzgLFxU6MMnLm8wwAPZ4Q2GJlLmwok+FI9JROKa/CGuccBVO6G+sKr3j64C7sMIZD+GIvheO6Z/CGjlewgn9J28LUxrjrHc+zP0YfFXbbuqbYa3WnP2oc2qLAgYl08DBwvP0CJi5x8jbo0JN32GiaTBs/try2X/9X/7FO20AAAB4nGNgZoCANAZjIMnIgAYADecAng=="
                "')} text{font-family:A;font-size: 4px;fill: black;}</style><rect width='100%' height='100%' fill='white' /><text x='-10'>",
                getTemplate(),
                "</text></svg>"
            );
    }

    /// @notice Token URI for the contract, only renders 1 token.
    /// @dev gated by msg.sender and tokenId for only one token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId == 1, "only one token");

        return
            sharedMetadata.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "',
                    contractName,
                    '", "description": "',
                    unicode"This portrait of Julie Martin, Director of Experiments in Art and Technology (E.A.T.), was created in 2022 by Ken Knowlton and Jim Boulton. It was made with a reconstruction of the algorithm Knowlton and Leon Harmon used to create the 1966 artwork Studies in Perception I, also known as Computer Nude. \\n\\nComputer Nude was displayed at a press conference for E.A.T., held in October 1967 at Robert Rauschenberg’s Lafayette Street studio. \\n\\n© Ken Knowlton 2022. Minted on the occasion of Rhizome’s 2022 benefit. Custom contract by Iain Nash. \\n\\n",
                    license(),
                    '", "image": "data:image/svg+xml;base64,',
                    sharedMetadata.base64Encode(getImage()),
                    '"}'
                )
            );
    }
}
