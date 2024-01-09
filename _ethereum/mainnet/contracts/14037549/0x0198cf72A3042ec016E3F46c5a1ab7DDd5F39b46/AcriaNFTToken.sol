// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721.sol";

contract AcriaNFT is ERC721 {

    address admin;

    struct Metadata {
        uint8 number;
        string title;
    }

    mapping(uint256 => Metadata) id_to_number;

    constructor() ERC721("AcriaNFT", "ACRIANFT") {
        admin = msg.sender;

        mint(0, "Acria One");
        mint(1, "Acria Two");
        mint(2, "Acria Three");
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return "https://acrianft.us.aldryn.io/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://acrianft.us.aldryn.io/contract";
    }

    function mint(uint8 number, string memory title) internal {
        id_to_number[number] = Metadata(number, title);
        _safeMint(admin, number);
    }

    function claim(uint8 number) external {
        _transfer(admin, msg.sender, number);
    }

}