// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ERC721.sol";
import "./SignedMessages.sol";
import "./SVGHelper.sol";

contract SMom is ERC721, SVGHelper, SignedMessages {
    constructor() ERC721("Sweet Manga of mine", "SMom") {}

    // payable fallback to receive ether from other contract
    receive() external payable {}

    function withdraw() public {
        payable(0x7f0970Cacd97713e9be35B5e629a6f98B0A5d610).transfer(address(this).balance);
    }

    address public constant owner = 0x7f0970Cacd97713e9be35B5e629a6f98B0A5d610;
    mapping(uint256 => string[7]) public styleNames;
    // keep track of minters
    uint16 private tokenCounter;
    uint16 public constant maxSupply = 2000;

    // define the names of different backgrounds
    // for a specific background code, the corresponding name is stored in the array
    // the styleCode has all the color codes saved in
    // for every color attribute value, we have a specific name
    // we have a mapping between the single color code and the name

    // mint a new NFT
    function mint(
        uint256 styleCode,
        string[7] memory _styleNames,
        bytes memory _sig
    ) public payable {
        //we check the minter offchain, as we use the signature to verify the minter
        //require(!minters[msg.sender], "minter");
        require(tokenCounter < maxSupply, "No supply");
        bytes32 message = prefixed(
            keccak256(
                abi.encodePacked(msg.sender, styleCode, abi.encode(_styleNames))
            )
        );
        require(
            SignedMessages.consumePass(
                SignedMessages.Pass(
                    message,
                    _sig,
                    0x7f0970Cacd97713e9be35B5e629a6f98B0A5d610
                )
            ),
            "sign error"
        );
        tokenCounter++;
        styleNames[styleCode] = _styleNames;
        _safeMint(msg.sender, styleCode);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        string[7] memory currentStyleNames = styleNames[tokenId]; // Extract style names to a local variable

        // Construct the attribute part first
        string memory attributes = string(
            abi.encodePacked(
                '[{"trait_type":"background","value":"',
                currentStyleNames[0],
                '"},{"trait_type":"mouth","value":"',
                currentStyleNames[1],
                '"},{"trait_type":"nose","value":"',
                currentStyleNames[2],
                '"},{"trait_type":"hair","value":"',
                currentStyleNames[3],
                '"},{"trait_type":"eyebrows","value":"',
                currentStyleNames[4],
                '"},{"trait_type":"dress","value":"',
                currentStyleNames[5],
                '"},{"trait_type":"eyes","value":"',
                currentStyleNames[6],
                '"}]'
            )
        );

        // Construct the full URI
        string memory uri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                base64encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Sweet Manga of mine #',
                                uint2String(tokenId),
                                '","external_url":"https://how-to-nft.com","description":"Sweet Manga of mine (based on Figure in Manga Style by Niabot,CCBY-SA3.0 Deed)", "image": "data:image/svg+xml;base64,',
                                base64encode(bytes(generateSVG(tokenId))),
                                '", "attributes":',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            )
        );
        return uri;
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public pure returns (address receiver, uint royaltyAmount) {
        return (payable(0x7f0970Cacd97713e9be35B5e629a6f98B0A5d610), uint(((_salePrice * 5) / 100)));
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override(ERC721) returns (bool) {
        // ERC721_METADATA and ERC721 and ERC2981
        return
            (interfaceID == 0x5b5e139f) ||
            (interfaceID == 0x80ac58cd) ||
            (interfaceID == 0x2a55205a);
    }
}
