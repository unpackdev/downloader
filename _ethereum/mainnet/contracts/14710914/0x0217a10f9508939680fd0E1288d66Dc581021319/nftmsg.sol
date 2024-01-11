//   ,_,
//  (o,o)
//  {`"'}
//  -"-"-
//
// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";

contract nftmsg is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    bool public paused = false;
    mapping(uint256 => HootMessage) public HootMessagesToTokenId;
    string public domain = "hoots.xyz";
    string public description = "";
    string public nft_name = "A hoot for you";
    string public header = "";
    string public footer = "";
    uint256 public minPrice = 0.01 ether;
    
    struct HootMessage {
        string name;
        string description;
        bytes bytesValue;
    }

    struct HootMessageLines {
        string[12] lines;
    }

    constructor() ERC721("hoots", "HOOT") {
        header = string(abi.encodePacked(
                        '<svg id="card" viewBox="0 0 200 300" xmlns="http://www.w3.org/2000/svg">',
                        '<rect x="2" y="2" rx="2" ry="2" width="196" height="296" style="fill:white;stroke:black;stroke-width:2;opacity:1"></rect>',
                        '<text style="white-space:pre;fill:rgb(15,12,29);font:normal 16px Courier, Monospace, serif;" x="7" y="17">'));

        footer = string(abi.encodePacked(
            '<rect x="3" y="245" rx="0" ry="0" width="194" height="52" style="fill:rgb(15, 12, 29);stroke-width:0;opacity:0.0;"></rect>',
            '<text style="font:bold 10px Courier, Monospace, serif;fill:rgb(88, 85, 122)" x="7" y="278">',
            domain,
            '<tspan x="171" y="257">,_,</tspan>',
            '<tspan x="164" y="269">(o,o)</tspan>',
            '<tspan x="164" y="281">{`"\'}</tspan>',
            '<tspan x="164" y="293">-"-"-</tspan>',
            '</text>'));
      description = string(abi.encodePacked(
        domain,
        ': airdropped messages from frens (o,0)'
      ));
    }

    function mint(bytes memory _userTextLines) public payable {
        address[] memory _to = new address[](1);
        _to[0] = msg.sender;
        mintTo(_userTextLines, 1, _to, false);
    }

    function mintTo(bytes memory _userTextLines, uint256 _quantity, address[] memory _to, bool asAirdrop) public payable {
        require(!paused, "Minting is paused.");

        uint256 supply = totalSupply();

        HootMessage memory newHootMessage = HootMessage(
            string(abi.encodePacked(nft_name,
            ' (#', uint256(supply + 1).toString(), ')')),
            description,
            _userTextLines
        );

        for (uint256 i = 0; i < _quantity; i++) {
            if (msg.sender != owner()) {
                require((msg.value/_quantity) >= minPrice);
            }

            HootMessagesToTokenId[supply + 1] = newHootMessage; //Add HootMessage to mapping @tokenId
            if (asAirdrop) { 
                _safeMint(_to[i], supply + 1);
            } else {
                _safeMint(msg.sender, supply + 1);
                transferFrom(msg.sender, _to[i], supply + 1);
            }
            supply = totalSupply();
        }
    }

    function getSVGTextLine(uint256 _startingY, string memory _text) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<tspan x="7" y="', 
                Strings.toString(_startingY),
                '">',
                _text,
                '</tspan>'));
    }

    function getTextBlock0(bytes memory _bytesMessage) private pure returns (string memory) {
        HootMessageLines memory currentHootMessageLines = abi.decode(_bytesMessage, (HootMessageLines));
        return string(abi.encodePacked(currentHootMessageLines.lines[0]));
    }

    function getTextBlock1(uint256 _startingY, bytes memory _bytesMessage) private pure returns (string memory) {
        HootMessageLines memory currentHootMessageLines = abi.decode(_bytesMessage, (HootMessageLines));
        return string(abi.encodePacked(
            getSVGTextLine(_startingY+20, currentHootMessageLines.lines[1]),
            getSVGTextLine(_startingY+40, currentHootMessageLines.lines[2]),
            getSVGTextLine(_startingY+60, currentHootMessageLines.lines[3]),
            getSVGTextLine(_startingY+80, currentHootMessageLines.lines[4]),
            getSVGTextLine(_startingY+100, currentHootMessageLines.lines[5])
            ));
    }

    function getTextBlock2(uint256 _startingY, bytes memory _bytesMessage) private pure returns (string memory) {
        HootMessageLines memory currentHootMessageLines = abi.decode(_bytesMessage, (HootMessageLines));
        return string(abi.encodePacked(
            getSVGTextLine(_startingY, currentHootMessageLines.lines[6]),
            getSVGTextLine(_startingY+20, currentHootMessageLines.lines[7]),
            getSVGTextLine(_startingY+40, currentHootMessageLines.lines[8]),
            getSVGTextLine(_startingY+60, currentHootMessageLines.lines[9]),
            getSVGTextLine(_startingY+80, currentHootMessageLines.lines[10]),
            getSVGTextLine(_startingY+100, currentHootMessageLines.lines[11])
            ));
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        HootMessage memory currentHootMessage = HootMessagesToTokenId[_tokenId];
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        header,
                        getTextBlock0(currentHootMessage.bytesValue),
                        getTextBlock1(37, currentHootMessage.bytesValue),
                        getTextBlock2(157, currentHootMessage.bytesValue),
                        '</text>',
                        footer,
                        '</svg>'
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        HootMessage memory currentHootMessage = HootMessagesToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentHootMessage.name,
                                '", "external_url": "https://',
                                domain,
                                '", "description":"',
                                currentHootMessage.description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "Hoot",',
                                '"value":"',
                                Strings.toString(_tokenId),
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
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
        return buildMetadata(_tokenId);
    }

    /* only owner... */
    function setPaused(bool _paused) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        paused = _paused;
    }

    function setMetadata(string memory _domain, string memory _name, string memory _description) public onlyOwner {
      require(msg.sender == owner(), "You are not the owner");
        description = _description;
        nft_name = _name;
        domain = _domain;
    }

    function setHeaderFooter(bytes memory _bHeader, bytes memory _bFooter) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        header = abi.decode(_bHeader, (string));
        footer = abi.decode(_bFooter, (string));
    }

    function setMinPrice(uint256 _newPrice) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        minPrice = _newPrice;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
