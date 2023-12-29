// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./base64.sol";

contract BONKC20 is ERC721A, Ownable {
    uint256 public maxSupply = 2100;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public cost = .002 ether;
    bool public sale;

    mapping(address => uint256) public mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor() ERC721A("BONKC20", "BNKC") {}

    function _createSVG() internal pure returns (string memory) {

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1080" viewBox="0 0 1080 1080">',
                '<rect width="100%" height="100%" fill="black"/>',
                '<text x="35%" y="30%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">{</text>',
                '<text x="50%" y="40%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">"p":"bnk-20",</text>',
                '<text x="50%" y="50%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">"op":"mint",</text>',
                '<text x="50%" y="60%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">"tick":"bnkc"</text>',
                '<text x="50%" y="70%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">"amt":1000</text>',
                '<text x="35%" y="80%" fill="gold" font-family="Arial" font-size="30" text-anchor="middle">}</text>',
                '</svg>'
            )
        );
        return svg;
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory svg = _createSVG();
        string memory encodedSvg = Base64.encode(bytes(svg));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Token ', 
                        Strings.toString(tokenId), 
                        '", "description": "Custom SVG Token", "image": "data:image/svg+xml;base64,', 
                        encodedSvg, 
                        '"}'
                    )
                )
            )
    );

    return string(abi.encodePacked("data:application/json;base64,", json));
}


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            mintedFreeAmount[msg.sender] += _amount;
        }

        _safeMint(msg.sender, _amount);
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}