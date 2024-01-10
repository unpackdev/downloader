// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./CustomErrors.sol";

contract ERC721Splitter is ERC721, Ownable {
    using Strings for uint256;

// Variables

    uint16 internal constant _PI = 31415;
    bytes16 internal constant _HEX_SYMBOLS = "0123456789ABCDEF";

    uint256 internal _totalSupply;
    mapping(uint256 => uint16) internal _tokenArea;

    struct Metadata {
        uint256 size;
        uint256 radius;
        uint256 generation;
        string number;
        string supply;
        string color;
    }

// Initialization

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

// Minting

    function airdrop(address[] calldata wallets) external onlyOwner {
        if (totalSupply() >= 128) revert OutOfBounds();
        
        uint256 nextTokenId = _totalSupply + 1;
        _totalSupply += wallets.length;

        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], nextTokenId++);
        }
    }

    function _mintNext(address to, uint16 areaMask) internal {
        uint256 nextTokenId = ++_totalSupply;
        _tokenArea[nextTokenId] = areaMask;
        _mint(to, nextTokenId);
    }

// Transfers

    function directTransfer(address from, address to, uint256 tokenId) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert Unauthorized();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert ServiceUnavailable();
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {

        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert Unauthorized();
        if (ownerOf(tokenId) != from) revert Forbidden();
        if (to == address(0)) revert InvalidArgument();
        
        uint16 maskedArea = _tokenArea[tokenId];
        uint16 availableArea = type(uint16).max - maskedArea;

        if (availableArea > 1) { // Mint and halve token

            uint256 nextTokenId = ++_totalSupply;
            uint16 newMask = maskedArea + (availableArea / 2);
            
            _tokenArea[tokenId] = newMask;
            _tokenArea[nextTokenId] = newMask;
            _owners[nextTokenId] = from;

            emit Transfer(address(0), from, nextTokenId);

        } else { // Otherwise decrement from balance as no token will be added to owner
            
            _balances[from] -= 1;
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

// Metadata

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NotFound();

        Metadata memory metadata = getTokenMetadata(tokenId);

        bytes memory byteString;
        byteString = abi.encodePacked(byteString, 'data:application/json;utf8,{');
        byteString = abi.encodePacked(byteString, '"name": "Mitosis #', metadata.number, '",');
        byteString = abi.encodePacked(byteString, '"description": '
            ,'"**Mitosis** (b. 2022)\\n\\n'
            ,'Mitosis #', metadata.number, '\\n\\n'
            ,'*Hand crafted SVG, 1920 x 1920 pixels*",'
        );
        byteString = abi.encodePacked(byteString, '"image": "data:image/svg+xml;utf8,' ,_generateSvg(metadata), '",');
        byteString = abi.encodePacked(byteString, '"attributes": ', _generateAttributes(metadata));
        byteString = abi.encodePacked(byteString, '}');
        
        return string(byteString);
    }

    function getTokenMetadata(uint256 tokenId) public view returns (Metadata memory metadata) {

        uint256 area = type(uint16).max - _tokenArea[tokenId];
        uint256 radius = _sqrt(area * 10000 / _PI);
        uint256 generation = 17 - _log2(area);
        string memory color = _generateColorHexCode(tokenId);

        metadata = Metadata(
            area,
            radius,
            generation,
            tokenId.toString(),
            _totalSupply.toString(),
            color
        );
    }

    function _generateColorHexCode(uint256 tokenId) private pure returns (string memory buffer) {
        
        bytes32 random = keccak256(abi.encodePacked(tokenId));
        uint8 r = uint8(random[0]);
        uint8 g = uint8(random[1]);
        uint8 b = uint8(random[2]);

        bytes memory byteString = new bytes(6);
        byteString[0] = _HEX_SYMBOLS[r >> 4 & 0xf];
        byteString[1] = _HEX_SYMBOLS[r & 0xf];
        byteString[2] = _HEX_SYMBOLS[g >> 4 & 0xf];
        byteString[3] = _HEX_SYMBOLS[g & 0xf];
        byteString[4] = _HEX_SYMBOLS[b >> 4 & 0xf];
        byteString[5] = _HEX_SYMBOLS[b & 0xf];

        buffer = string(byteString);
    }

    function _generateSvg(Metadata memory metadata) private pure returns (bytes memory svg) {

        svg = abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='1920' height='1920' viewBox='0 0 288 288'>"
            ,"<style>#r{fill:#fff}#c{fill:#", metadata.color, "}</style>"
            ,"<rect id='r' width='100%' height='100%'/><circle id='c' cx='144' cy='144' r='", metadata.radius.toString(), "'/></svg>"
        );
    }

    function _generateAttributes(Metadata memory metadata) private pure returns (bytes memory attr) {

        attr = abi.encodePacked('['
            ,'{"trait_type": "Size", "value": ', metadata.size.toString(), '},'
            ,'{"trait_type": "Color", "value": "#', metadata.color, '"},'
        );

        attr = abi.encodePacked(attr
            ,'{"display_type": "number", "trait_type": "Generation", "value": ', metadata.generation.toString(), '},'
            ,'{"display_type": "number", "trait_type": "Edition", "value": ', metadata.number, ', "max_value": ', metadata.supply, '}'
            ,']'
        );
    }

// Math

    function _sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _log2(uint256 x) internal pure returns (uint y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
}
