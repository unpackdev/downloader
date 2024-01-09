// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

interface IGiftRenderer {
    function generateGltf(uint256 tokenId) external view returns (string memory);
}

contract ChainGifts is ERC721, Ownable, ReentrancyGuard {

    address public _rendererAddress;

    string[] private giftMeshes = [
        '{"mesh": 0}',
        '{"mesh": 0,"translation": [ 0, 0, 0.45 ], "scale": [ 1.1, 1.1, 0.1 ]}',
        '{"mesh": 1, "scale": [ 1.02, 0.1, 0.95 ], "translation": [ 0, 0, -0.035 ]}',
        '{"mesh": 1, "scale": [ 1.02, 0.1, 0.95 ],  "translation": [ 0, 0, -0.035 ], "rotation": [ 0, 0, 0.7071081, 0.7071055 ]}',
        '{"mesh": 1, "scale": [ 1.12, 0.1, 0.12 ],  "translation": [ 0, 0, 0.45 ]}',
        '{"mesh": 1, "scale": [ 1.12, 0.1, 0.12 ],  "translation": [ 0, 0, 0.45 ], "rotation": [ 0, 0, 0.7071081, 0.7071055 ]}',
        '{"mesh": 1, "scale": [ 0.1, 0.1, 0.1 ], "translation": [ 0.1, 0, 0.55 ]}',
        '{"mesh": 1, "scale": [ 0.1, 0.1, 0.1 ], "translation": [ -0.1, 0, 0.55 ]}',
        '{"mesh": 1, "scale": [ 0.1, 0.1, 0.1 ], "translation": [ 0, 0.1, 0.55 ]}',
        '{"mesh": 1, "scale": [ 0.1, 0.1, 0.1 ], "translation": [ 0, -0.1, 0.55 ]}',
        '{"mesh": 1, "scale": [ 0.1, 0.1, 0.1 ], "translation": [ 0, 0, 0.6 ]}'
    ];

    string[] private materials = [
        '{"pbrMetallicRoughness": {"baseColorFactor": [0.800000011920929,0.0,0.0,1.0],"metallicFactor": 0.0},"name": "material"}',
        '{"pbrMetallicRoughness": {"baseColorFactor": [1.0,1.0,1.0,1.0],"metallicFactor": 0.0},"name": "material"}'
    ];

    string private _converterUri;
    uint256 private constant MAX_PUBLIC = 420;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _mintPrice = 0.01 ether;
    uint256 private _unwrapTimestamp = 1640419200;

    mapping(uint256 => address) private _giftedTokens;


    constructor() ERC721("ChainGifts", "GIFTS") Ownable() {
    }

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Gift #', Strings.toString(tokenId), '", "description": "Chain Gifts are 3D NFTs that are generated and stored on-chain as a glb. They are meant to be gifted to someone else for the 2021 holiday season. Minted gifts will not be unwrapped unless they are gifted to another wallet. On December 25, 2021 eligible gifts will be unwrapped.", "image":"ipfs:///Qmd9iGcAUqbcs1w1UQp7mG6e46pxStxXSM19BfDxTP8DkN","animation_url":"', _converterUri, Strings.toString(tokenId),'.glb"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function setConverterUri(string memory converterUri) public onlyOwner {
        _converterUri = converterUri;
    }

    function canBeUnwrapped(uint256 tokenId) external view returns(bool){
        return block.timestamp > _unwrapTimestamp && _giftedTokens[tokenId] != address(0x0);
    }

    function mintAtMyOwnRisk() external payable nonReentrant {
        require(_tokenIds.current() <= MAX_PUBLIC, "All gifts have been minted.");
        require(_mintPrice == msg.value, "Not enough ether sent to mint a gift.");

        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
    }

    function _beforeTokenTransfer( address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        _giftedTokens[tokenId] = from;
    }

    function setUnwrapTimestamp(uint256 unwrapTimestamp) public onlyOwner {
        _unwrapTimestamp = unwrapTimestamp;
    }

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }

    function setRendererAddress(address addr) public onlyOwner {
        _rendererAddress = addr;
    }

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function generateGltf(uint256 id) external view returns (string memory) {

        if (_rendererAddress != address(0)) return IGiftRenderer(_rendererAddress).generateGltf(id);

        //render the placeholder gift if there is no renderer contract set
        string memory gltfAccumulator = '{"asset": {"generator": "ChainGifts.sol","version": "2.0"},';
        gltfAccumulator = strConcat(gltfAccumulator, '"scene": 0,');
        gltfAccumulator = strConcat(gltfAccumulator, '"scenes": [{"nodes": [0]}],');
        gltfAccumulator = strConcat(gltfAccumulator, '"nodes": [{"children": [');
        for(uint i=0; i < giftMeshes.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator, Strings.toString(i + 1));
            if(i + 1 < giftMeshes.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"matrix": [1.0,0.0,0.0,0.0,0.0,0.0,-1.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0,1.0]},');
        for(uint i=0; i < giftMeshes.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator, giftMeshes[i]);
            if(i + 1 < giftMeshes.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"meshes": [');
        for(uint i=0; i < materials.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator,'{"primitives": [{"attributes": {"NORMAL": 1,"POSITION": 2},"indices": 0,"mode": 4,"material": ');
            gltfAccumulator = strConcat(gltfAccumulator, Strings.toString(i));
            gltfAccumulator = strConcat(gltfAccumulator,'}],"name": "Mesh');
            gltfAccumulator = strConcat(gltfAccumulator, Strings.toString(i));
            gltfAccumulator = strConcat(gltfAccumulator,'"}');
            if(i + 1 < materials.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }

        gltfAccumulator = strConcat(gltfAccumulator,'],');
        gltfAccumulator = strConcat(gltfAccumulator, '"accessors": [');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView": 0,"byteOffset": 0,"componentType": 5123,"count": 36,"max": [23],"min": [0],"type": "SCALAR"},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView": 1,"byteOffset": 0,"componentType": 5126,"count": 24,"max": [1.0,1.0,1.0],"min": [-1.0,-1.0,-1.0],"type": "VEC3"},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"bufferView": 1,"byteOffset": 288,"componentType": 5126,"count": 24,"max": [0.5,0.5,0.5],"min": [-0.5,-0.5,-0.5],"type": "VEC3"}');
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"materials": [');
        for(uint i=0; i < materials.length; i++){
            gltfAccumulator = strConcat(gltfAccumulator, materials[i]);
            if(i + 1 < materials.length ){
                gltfAccumulator = strConcat(gltfAccumulator, ',');
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator,'],');
        gltfAccumulator = strConcat(gltfAccumulator, '"bufferViews": [');
        gltfAccumulator = strConcat(gltfAccumulator, '{"buffer": 0,"byteOffset": 576,"byteLength": 72,"target": 34963},');
        gltfAccumulator = strConcat(gltfAccumulator, '{"buffer": 0,"byteOffset": 0,"byteLength": 576,"byteStride": 12,"target": 34962}');
        gltfAccumulator = strConcat(gltfAccumulator, '],');
        gltfAccumulator = strConcat(gltfAccumulator, '"buffers": [{"byteLength": 648,"uri": "data:application/octet-stream;base64,AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAC/AAAAvwAAAL8AAAC/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAPwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAvwAAAD8AAAC/AAAAPwAAAD8AAAC/AAAAvwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAPwAAAD8AAAC/AAABAAIAAwACAAEABAAFAAYABwAGAAUACAAJAAoACwAKAAkADAANAA4ADwAOAA0AEAARABIAEwASABEAFAAVABYAFwAWABUA"}]');
        gltfAccumulator = strConcat(gltfAccumulator, '}');
        return gltfAccumulator;
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}