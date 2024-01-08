//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "./IERC721.sol";

contract EnojiDataRegistry {
    IERC721 public enoji;
    mapping(uint256 => string) dataByTokenId;

    constructor(address _enoji) {
        enoji = IERC721(_enoji);
    }

    function setData(uint256 _tokenId, string memory data) external {
        require(enoji.ownerOf(_tokenId) == msg.sender, "Enoji:INVALID_OWNER");
        dataByTokenId[_tokenId] = data;
    }

    function getData(uint256 _tokenId) external view returns (string memory) {
        return dataByTokenId[_tokenId];
    }
}
