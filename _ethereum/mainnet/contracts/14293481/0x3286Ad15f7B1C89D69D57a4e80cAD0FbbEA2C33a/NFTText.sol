// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./Base64.sol";


contract NFTText is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint256 => Word) private wordsToTokenId;
    uint private fee = 0.005 ether;

    struct Word {
        string text;
        uint256 bgHue;
        uint256 textHue;
    }

    constructor() ERC721("NFTText", "NTXT") {
        mint('Pilate');
    }

    function randomHue(
        uint8 _salt
    ) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.number, 
                    false,
                    totalSupply(), 
                    false,
                    _salt)
            )
        ) % 361;
    }

    function mint(string memory _userText, address _destination) public payable {
        require(bytes(_userText).length <= 30, "Text is too long");
        uint256 newSupply = totalSupply() + 1;

        Word memory newWord = Word(
            _userText,
            randomHue(1),
            randomHue(2)
        );

        if (msg.sender != owner()) {
            require(msg.value >= fee, string(abi.encodePacked("Missing fee of ", fee.toString(), " wei")));
        }

        wordsToTokenId[newSupply] = newWord;
        _safeMint(_destination, newSupply);
    }

    function mint(string memory _userText) public payable {
        mint(_userText, msg.sender);
    }

    function buildImage(string memory _userText, uint256 _bgHue, uint256 _textHue) private pure returns (bytes memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg">'
                    '<rect height="100%" width="100%" y="0" x="0" fill="hsl(', _bgHue.toString(), ',50%,25%)"/>'
                    '<text y="50%" x="50%" text-anchor="middle" dy=".3em" fill="hsl(', _textHue.toString(), ',100%,80%)">', _userText, "</text>"
                    "</svg>"
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        Word memory tokenWord = wordsToTokenId[_tokenId];
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{"
                                '"name":"', tokenWord.text, '",'
                                '"description":"\'', bytes(tokenWord.text), '\' as NFTText by Pilate",'
                                '"image":"data:image/svg+xml;base64,', buildImage(tokenWord.text, tokenWord.bgHue, tokenWord.textHue), '"'
                            "}"
                        )
                    )
                )
            );
    }

    function getFee() public view returns (uint) {
        return fee;
    }

    function setFee(uint _newFee) public onlyOwner {
        fee = _newFee;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
