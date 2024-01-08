//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Base64.sol";

interface iOtakuCoinArcadeGame {

    function remainingAmount() external view returns (uint256);

    function isOnSale() external view returns (bool);

    function mintedTokenIdList() external view returns (uint256[] memory);

    function toggleSale(bool _isOnSale) external;

    function buy(uint256 tokenId) external payable;

    function withdrawETH() external;
}

contract OtakuCoinArcadeGame is iOtakuCoinArcadeGame, ERC721Burnable, ReentrancyGuard, Ownable {

    using Strings for uint256;

    uint256 public constant PRICE = 0.03 ether;
    uint256 public _remainingAmount = 666;
    uint256[] private _mintedTokenIdList;
    address payable private _recipient;
    bool private _isOnSale;

    constructor(address payable __recipient)
    ERC721("Otaku Coin Arcade Game", "OCAG")
    {
        require(__recipient != address(0), "Invalid address");
        _recipient = __recipient;
    }

    function remainingAmount() external override view returns (uint256) {
        return _remainingAmount;
    }

    function isOnSale() external view override returns (bool) {
        return _isOnSale;
    }

    function mintedTokenIdList() external override view returns (uint256[] memory) {
        return _mintedTokenIdList;
    }

    function generateMetadataJson(uint256 tokenId) public view returns(string memory) {
        require(_exists(tokenId), "nonexistent token");

        string [25] memory parts;

        parts[0] = '{"name": "Otaku Coin Arcade Game #';
        parts[1] = tokenId.toString();
        parts[2] = '", ';
        parts[3] = '"description": "Generative Art NFT game \\"Otaku Coin Arcade Game\\" is an exciting action game that includes a DAO army of numerous Otaku Coin owners who fight off the giant Otaku Coin \\"invaders\\" on the NFT.';
        parts[4] = '\\n\\n';
        parts[5] = 'Tx ID: [3mAmpxaFL1iS5AVQ9uvwZPFaDSIooP00PuQA3m7B4QY](https://arweave.net/3mAmpxaFL1iS5AVQ9uvwZPFaDSIooP00PuQA3m7B4QY?s=';
        parts[6] = tokenId.toString();
        parts[7] = '';
        parts[8] = ')\\n\\n';
        parts[9] = 'License: [Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)\\n\\n';
        parts[10] = 'Library: [three.js](https://threejs.org/), [cannon.js](https://schteppe.github.io/cannon.js/)\\n\\n';
        parts[11] = 'Artist SNS: [Twitter](https://twitter.com/ikeryou)", ';
        parts[12] = '"image": "ar://2E4evXQsddIZ-vKii3F_6soVDC6rKB15xE0gHDZxD6Q/';
        parts[13] = tokenId.toString();
        parts[14] = '.png", ';
        parts[15] = '"animation_url": "ar://3mAmpxaFL1iS5AVQ9uvwZPFaDSIooP00PuQA3m7B4QY?s=';
        parts[16] = tokenId.toString();
        parts[17] = '", ';
        parts[18] = '"external_url": "https://arweave.net/3mAmpxaFL1iS5AVQ9uvwZPFaDSIooP00PuQA3m7B4QY?s=';
        parts[19] = tokenId.toString();
        parts[20] = '", ';
        parts[21] = '"origin_arweave_tx_id": "3mAmpxaFL1iS5AVQ9uvwZPFaDSIooP00PuQA3m7B4QY", ';
        parts[22] = '"attributes":[ { "trait_type":"Artist", "value":"ikeryou" }, { "trait_type":"License", "value":"Attribution 4.0 International (CC BY 4.0)" }, { "trait_type":"Library", "value":"three.js" }, { "trait_type":"Library", "value":"cannon.js" } ],';
        parts[23] = '"license_url": "https://creativecommons.org/licenses/by/4.0/"';
        parts[24] = '}';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(generateMetadataJson(tokenId))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    function toggleSale(bool __isOnSale) external override onlyOwner {
        _isOnSale = __isOnSale;
    }

    function buy(uint256 tokenId) external override nonReentrant payable {
        require(_isOnSale, "Not on sale");
        require(msg.value == PRICE, "Invalid value");
        require(tokenId < 666, "Invalid id");

        _mintedTokenIdList.push(tokenId);

        _remainingAmount--;

        _safeMint(_msgSender(), tokenId);
    }

    function withdrawETH() external override {
        Address.sendValue(_recipient, address(this).balance);
    }

}
