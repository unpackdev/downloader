//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract CharizardNFT is ERC721Enumerable, Ownable {
    string tokenImg =
        "https://1of1.fra1.digitaloceanspaces.com/Charizard-holo-psa-10.jpg";

    constructor()
        ERC721("Charizard 1st Edition PSA 10 GEM", "CHARIZARD-1st-10")
        Ownable()
    {
        _safeMint(msg.sender, totalSupply());

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
                                    '{"name": "Charizard 1st Edition PSA 10 GEM", "description": "Ownership of this NFT grants a right to redeem the physical object by international shipping", "attributes": [{"trait_type": "Edition", "value": "1st Edition 1999"},{"trait_type": "Grade", "value": "PSA 10 GEM"}], "image": "',
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
