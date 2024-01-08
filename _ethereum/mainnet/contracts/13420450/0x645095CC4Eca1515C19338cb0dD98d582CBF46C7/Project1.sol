// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FormaBase.sol";
import "./BurnMergeable.sol";
import "./HexStrings.sol";

contract Project1 is FormaBase, BurnMergeable {
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => string) public tokenIdToData;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        uint64 _maxTokens
    ) FormaBase(_tokenName, _tokenSymbol, _baseURI, _pricePerToken, _maxTokens) {
        licenseType = "CC BY-NC 4.0 and GNU Lesser";
    }

    function _mintToken(address _toAddress) internal override returns (uint256 _tokenId) {
        uint256 tokenId = freshTokensMinted;
        freshTokensMinted = freshTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        tokenIdToData[tokenId] = _generateTokenData(hash);
        tokenIdToCount[tokenId] = 1;

        emit Mint(_toAddress, tokenId);

        if (msg.value > 0) {
            _splitFunds();
        }

        return tokenId;
    }

    function _generateTokenData(bytes32 _seedHash) internal pure returns (string memory) {
        string memory _output;
        for (uint8 i = 0; i < 4; i++) {
            unchecked {
                uint8 _pseudoRandomNumber = uint8(bytes1(_seedHash << (8 * i)));
                _output = string(
                    abi.encodePacked(_output, HexStrings.toHexString(_pseudoRandomNumber % 16))
                );
            }
        }
        return _output;
    }

    function _mintMergedToken(uint256[] memory _tokenIds, address _toAddress)
        internal
        override
        returns (uint256)
    {
        uint256 tokenId = maxTokens + mergeTokensMinted;
        mergeTokensMinted = mergeTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        tokenIdToData[tokenId] = _mergeTokenData(_tokenIds);

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        emit Merge(_tokenIds, _toAddress, tokenId);
        emit Mint(_toAddress, tokenId);

        return tokenId;
    }

    function _mergeTokenData(uint256[] memory _tokenIds) internal view returns (string memory) {
        string memory _output;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            _output = string(abi.encodePacked(_output, tokenIdToData[_tokenIds[i]]));
        }
        return _output;
    }

    function tokenData(uint256 tokenId) public view returns (string memory) {
        return tokenIdToData[tokenId];
    }
}
