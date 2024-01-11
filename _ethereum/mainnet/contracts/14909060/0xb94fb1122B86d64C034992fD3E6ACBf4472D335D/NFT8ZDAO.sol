// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";

contract NFT8ZDAO is ERC721, Ownable {
    address public renderer;
    uint256 public totalSupply;

    string[] private TIAN_GAN = [
        unicode"甲",
        unicode"乙",
        unicode"丙",
        unicode"丁",
        unicode"戊",
        unicode"己",
        unicode"庚",
        unicode"辛",
        unicode"壬",
        unicode"癸"
    ];

    string[] private DI_ZHI = [
        unicode"寅",
        unicode"卯",
        unicode"辰",
        unicode"巳",
        unicode"午",
        unicode"未",
        unicode"申",
        unicode"酉",
        unicode"戌",
        unicode"亥",
        unicode"子",
        unicode"丑"
    ];

    constructor(address renderer_) ERC721("8Z DAO", "8ZDAO") {
        renderer = renderer_;
    }

    function setRenderer(address renderer_) external onlyOwner {
        renderer = renderer_;
    }

    function mint() public payable {
        require(totalSupply < 70, "Only 70 8ZDAO NFT");
        require(msg.value == 0.1 ether, "Incorrect ether value");
        _safeMint(msg.sender, ++totalSupply);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        string[] memory words;
        string memory name;
        if (tokenId <= 10) {
            words = new string[](1);
            words[0] = TIAN_GAN[(tokenId - 1) % 10];
            name = words[0];
        } else {
            words = new string[](2);
            words[0] = TIAN_GAN[(tokenId - 11) % 10];
            words[1] = DI_ZHI[((tokenId - 11) + 10) % 12];
            name = string(abi.encodePacked(words[0], words[1]));
        }
        return IRenderer(renderer).renderStrings(tokenId, name, words);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

interface IRenderer {
    function renderStrings(uint256, string memory, string[] memory) external view returns (string memory);
}

abstract contract IERC20 {
    mapping(address => uint256) public balanceOf;
    function transfer(address to, uint256 amount) public virtual returns (bool);
}
