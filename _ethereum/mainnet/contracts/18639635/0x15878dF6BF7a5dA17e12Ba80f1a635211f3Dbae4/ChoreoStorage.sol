pragma solidity ^0.8.17;

import "./ChoreoLibraryConfig.sol";
import "./LibZip.sol";

contract ChoreoStorage is ChoreoLibraryConfig {
    using LibZip for bytes;

    /** Render Storage**/
    mapping(uint256 => bytes) internal _choreoCompressed;

    function decodeCompressedChoreo(
        uint256 tokenId
    ) public view returns (ChoreographyParams memory) {
        (
            uint8[] memory _tokenHashArray,
            uint8[] memory _sequence,
            uint8[] memory _pauseFrames,
            uint8[] memory _tempo,
            uint8[] memory _params
        ) = decodeChoreoParams(_choreoCompressed[tokenId]);
        return
            ChoreographyParams({
                tokenHashArray: _tokenHashArray,
                sequence: _sequence,
                pauseFrames: _pauseFrames,
                tempo: _tempo,
                params: _params
            });
    }

    function decodeChoreoProof(
        bytes memory choreoEncoded
    )
        public
        pure
        returns (
            bytes32 _tokenHash,
            bytes memory _compressedEncodedChoreoParams
        )
    {
        (_tokenHash, _compressedEncodedChoreoParams) = abi.decode(
            choreoEncoded,
            (bytes32, bytes)
        );
    }

    function decodeChoreoParams(
        bytes memory choreoEncoded
    )
        public
        pure
        returns (
            uint8[] memory _tokenHashArray,
            uint8[] memory _sequence,
            uint8[] memory _pauseFrames,
            uint8[] memory _tempo,
            uint8[] memory _params
        )
    {
        (_tokenHashArray, _sequence, _pauseFrames, _tempo, _params) = abi
            .decode(
                choreoEncoded.flzDecompress(),
                (uint8[], uint8[], uint8[], uint8[], uint8[])
            );
    }

    function _storeChoreoCompressed(
        uint256 tokenId,
        bytes memory choreoEncoded
    ) internal {
        _choreoCompressed[tokenId] = choreoEncoded;
    }
}
