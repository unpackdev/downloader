//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract TomBradyNFT is ERC721, Ownable {
    string tokenImg =
        "https://1of1.fra1.digitaloceanspaces.com/TomBrady-2012.jpg";

    constructor()
        ERC721("Tom Brady, Pro Bowl game-worn double-signed cleats", "BRADY")
        Ownable()
    {
        _safeMint(msg.sender, 0);

        transferOwnership(0x2B3f6b069f3a0Ef3a523EE48713eAFA86Dba23Dd);
    }

    function setTokeImg(string memory _tokenImg) public onlyOwner {
        tokenImg = _tokenImg;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Tom Brady, Pro Bowl game-worn double-signed cleats", "description": "Ownership of this NFT grants a right to redeem the physical object by international shipping", "attributes": [{"trait_type": "Year", "value": "2012"}], "image": "',
                                    tokenImg,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
