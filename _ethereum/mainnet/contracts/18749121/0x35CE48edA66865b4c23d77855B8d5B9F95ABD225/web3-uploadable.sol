// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Web3Uploadable {
    event FilePartUploaded(
        uint256 indexed tokenId,
        uint256 indexed partIndex,
        uint256 partSize
    );

    struct FilePart {
        bytes data;
        uint256 size;
    }

    mapping(uint256 => mapping(uint256 => FilePart)) private _files;
    mapping(uint256 => uint256) private _fileParts;

    function _uploadFilePart(
        uint256 _tokenId,
        uint256 _partIndex,
        bytes calldata _data
    ) internal {
        require(_data.length > 0, "data is empty");

        _files[_tokenId][_partIndex] = FilePart(_data, _data.length);
        if (_partIndex > _fileParts[_tokenId]) {
            _fileParts[_tokenId] = _partIndex;
        }
        emit FilePartUploaded(_tokenId, _partIndex, _data.length);
    }

    function getFilePart(
        uint256 _tokenId,
        uint256 _partIndex
    ) public view returns (bytes memory) {
        return _files[_tokenId][_partIndex].data;
    }

    function getFilePartSize(
        uint256 _tokenId,
        uint256 _partIndex
    ) public view returns (uint256) {
        return _files[_tokenId][_partIndex].size;
    }

    function getFilePartCount(uint256 _tokenId) public view returns (uint256) {
        return _fileParts[_tokenId] + 1;
    }
}
