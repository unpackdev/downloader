// SPDX-License-Identifier: MIT
// 𝗔𝗻 𝗶𝗻-𝗵𝗮𝘂𝘀 𝗽𝗿𝗼𝗱𝘂𝗰𝘁𝗶𝗼𝗻 𝗯𝘆 𝗔𝗿𝘁𝗵𝘂𝗿 𝗛𝗮𝘂𝘀𝗲𝗻 𝗳𝗿𝗼𝗺 𝗔𝗥𝗧.𝗛𝗔𝗨𝗦
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./base64.sol";

contract Embryonic is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 private _tokenIds;
    uint256 public constant price = 0.042 ether;
    uint256 private constant _maxTokens = 4242;
    uint256 public constant maximumMintQuantity = 42;
    uint256 private _seed;
    mapping(uint256 => uint256) private _seeds;

    constructor() ERC721("Embryonic", "LIFE") {
        _seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number-1), block.timestamp)));
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(quantity > 0 && quantity <= maximumMintQuantity, "Quantity invalid");
        require(msg.value >= price * quantity, "Ether amount incorrect");
        require( quantity + _tokenIds <= _maxTokens, "Maximum count exceeded");

        _seed = uint256(keccak256(abi.encodePacked(_seed >> 1, msg.sender, blockhash(block.number-1), block.timestamp)));
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIds;
            _safeMint(msg.sender, tokenId);
            _tokenIds ++;
            _seeds[tokenId] = _seed;
            if (i + 1 < quantity) {
                _seed = uint256(keccak256(abi.encodePacked(_seed >> 1)));
            }
        }
    }

    function createSvg(uint256 tokenId) private view returns (bytes memory) {
        return abi.encodePacked(
            svgOpen(_seeds[tokenId] % 4 + 2, _seeds[tokenId] % 10000)
        );
    }

    function svgOpen(uint256 _hertz, uint256 _inSeed) private pure returns (string memory) {
        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 800' style='background: radial-gradient(circle, hsla(61, 91%, 87%, 1) 0%, hsla(31, 98%, 76%, 1) 12.5%, hsla(15, 95%, 68%, 1) 25%, hsla(353, 75%, 61%, 1) 37.5%, hsla(329, 54%, 46%, 1) 50%, hsla(301, 56%, 33%, 1) 62.5%, hsla(275, 74%, 28%, 1) 75%, hsla(253, 63%, 17%, 1) 87.5%, hsla(240, 100%, 1%, 1) 100%);'><filter id='a'><feTurbulence baseFrequency='0.00", _hertz.toString(), "' seed='", _inSeed.toString(), "'/></filter><rect width='100%' height='100%' filter='url(#a)'/></svg>"));
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _attributesFromDetail(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked('trait_type":"Zygote","value":"', (_seeds[tokenId] % 10000).toString(), '"},{"trait_type":"Frequency","value":"', (_seeds[tokenId] % 4 + 2).toString(), 'Hz'));
    }

    function _tokenUriForDetail(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(
            _baseURI(),
            Base64.encode(abi.encodePacked(
                '{"name":"',
                    'Embryo #', tokenId.toString(),
                '","description":"',
                    'Zygote ', (_seeds[tokenId] % 10000).toString(), ' at ', (_seeds[tokenId] % 4 + 2).toString(), 'Hz',
                '","attributes":[{"',
                    _attributesFromDetail(tokenId),
                '"}],"image":"',
                    "data:image/svg+xml;base64,", Base64.encode(createSvg(tokenId)),
                '"}'
            ))
        ));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenUriForDetail(tokenId);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 amount = address(this).balance;
        payable(0x79FD2F15e0EA8C27b5192259F9da63f4E562f021).transfer(amount);
    }

}