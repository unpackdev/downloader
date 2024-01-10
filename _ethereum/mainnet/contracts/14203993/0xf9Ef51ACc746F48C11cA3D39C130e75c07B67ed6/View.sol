// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC721.sol";

contract View {
    function getNFTsExist(address _nft, uint256[] memory _tokenIds) external view returns (bool[] memory) {
        bool[] memory result = new bool[](_tokenIds.length);

        IERC721 nft = IERC721(_nft);

        for(uint256 i = 0; i < result.length; i ++) {
            try nft.ownerOf(_tokenIds[i]) {
                result[i] = true;
            } catch {
                result[i] = false;
            }
        }

        return result;
    }
}