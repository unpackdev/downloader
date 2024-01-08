// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./base64.sol";
import "./Strings.sol";
import "./N.sol";

contract nDollars is ERC721Enumerable, ReentrancyGuard, Ownable {
    N public nContract;

    constructor(N _nContract) ERC721("n$", "$") {
        nContract = _nContract;
    }

    function claim(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 0 && tokenId <= 8888, "Token ID invalid");
        require(nContract.ownerOf(tokenId) == msg.sender, "Not the owner of this number");
        require(0.01 ether <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 amount = getAmount(tokenId);
        string memory image = Base64.encode(bytes(generateSVG(amount)));
        string memory name = generateName(amount, tokenId);
        string memory description = generateDescription();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getAmount(uint256 tokenId) public view returns (uint256) {
        uint256 baseAmount = nContract.getFirst(tokenId) +
            nContract.getSecond(tokenId) +
            nContract.getThird(tokenId) +
            nContract.getFourth(tokenId) +
            nContract.getFifth(tokenId) +
            nContract.getSixth(tokenId) +
            nContract.getSeventh(tokenId) +
            nContract.getEight(tokenId);

        uint256 rand1 = (uint256(keccak256(abi.encodePacked(baseAmount, tokenId))) % 899999) + 1;
        uint256 rand2 = uint256(keccak256(abi.encodePacked(baseAmount, tokenId))) % 10;

        if (rand2 >= 9) {
            rand1 += 100000;
        }
        return rand1;
    }

    /// @dev generate SVG
    function generateSVG(uint256 amount) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" id="Item" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="860px" height="560px" viewBox="0 0 860 560" enable-background="new 0 0 860 560" xml:space="preserve">',
                    '<rect id="Black" x="0.7" y="-0.6" width="862" height="560.2"/>',
                    '<g id="Bill">',
                    '<rect id="Bg" x="87.9" y="180.4" stroke="#FFFFFF" stroke-width="3" stroke-miterlimit="10" width="684.3" height="199.1"/>',
                    '<path id="Dollar" fill="#FFFFFF" d="M693.8,219.2c-1.5,0-2.6,1.2-2.6,2.6v121.4c0,1.5,1.2,2.6,2.6,2.6c1.5,0,2.6-1.2,2.6-2.6V221.8 C696.4,220.4,695.2,219.2,693.8,219.2z M693.8,229.8c-18.9,0-34.3,11.8-34.3,26.4c0,10,7.2,19.1,18.8,23.6c0.3,0.1,0.6,0.2,1,0.2 c1.1,0,2.1-0.6,2.5-1.7c0.5-1.4-0.1-2.9-1.5-3.4c-9.5-3.7-15.5-10.9-15.5-18.7c0-11.6,13-21.1,29-21.1c16,0,29,9.5,29,21.1 c0,1.5,1.2,2.6,2.6,2.6c1.5,0,2.6-1.2,2.6-2.6C728.1,241.6,712.7,229.8,693.8,229.8z M709.2,285.4c-1.4-0.5-2.9,0.1-3.4,1.5 c-0.5,1.4,0.1,2.9,1.5,3.4c9.5,3.7,15.5,10.9,15.5,18.7c0,11.6-13,21.1-29,21.1c-16,0-29-9.5-29-21.1c0-1.5-1.2-2.6-2.6-2.6 s-2.6,1.2-2.6,2.6c0,14.6,15.4,26.4,34.3,26.4c18.9,0,34.3-11.8,34.3-26.4C728.1,298.9,720.9,289.8,709.2,285.4z M709.3,285.4 c-7.7-3.1-11.4-4.3-15.3-5.6c-3.4-1.1-7-2.3-13.8-5c-1.4-0.5-2.9,0.1-3.4,1.5s0.1,2.9,1.5,3.4c6.9,2.7,10.5,3.9,14,5 c3.8,1.3,7.4,2.4,14.9,5.5c0.3,0.1,0.7,0.2,1,0.2c1,0,2-0.6,2.4-1.6C711.3,287.5,710.6,285.9,709.3,285.4z"/>',
                    "</g>",
                    generateSVGAmount(amount)
                )
            );
    }

    /// @dev Generate the number SVG inside the bill
    function generateSVGAmount(uint256 amount) private pure returns (string memory) {
        uint256 number1 = amount;
        uint256 number2 = number1 / 10;
        uint256 number3 = number2 / 10;
        uint256 number4 = number3 / 10;
        uint256 number5 = number4 / 10;
        uint256 number6 = number5 / 10;
        return
            string(
                abi.encodePacked(
                    '<text font-size="120" fill="#ffffff" x="150" y="323" font-family="Arial">',
                    Strings.toString(number6 % 10),
                    Strings.toString(number5 % 10),
                    Strings.toString(number4 % 10),
                    " ",
                    Strings.toString(number3 % 10),
                    Strings.toString(number2 % 10),
                    Strings.toString(number1 % 10),
                    "</text>",
                    "</svg>"
                )
            );
    }

    /// @dev generate Json Metadata name
    function generateName(uint256 amount, uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked(Strings.toString(amount), "$ - #", Strings.toString(tokenId)));
    }

    /// @dev generate Json Metadata description
    function generateDescription() private pure returns (string memory) {
        return string(abi.encodePacked("n dollars for n project"));
    }
}
