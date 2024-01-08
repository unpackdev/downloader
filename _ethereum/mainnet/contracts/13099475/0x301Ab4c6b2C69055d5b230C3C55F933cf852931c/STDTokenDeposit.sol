// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessOperatable.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";

contract STDTokenDeposit is AccessOperatable, ERC721Holder {
    function transferFrom(
        address _assetContract,
        address _from,
        address _to,
        uint256 _tokenId
    ) public onlyOperator() {
        IERC721 assetContract = IERC721(_assetContract);
        assetContract.safeTransferFrom(_from, _to, _tokenId);
    }

    function bulkTransferFrom(
        address[] calldata _assetContracts,
        address[] calldata _froms,
        address[] calldata _tos,
        uint256[] calldata _tokenIds
    ) public onlyOperator() {
        require(
            _tokenIds.length == _assetContracts.length &&
                _tokenIds.length == _froms.length &&
                _tokenIds.length == _tos.length,
            "invalid length"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(
                _assetContracts[i],
                _froms[i],
                _tos[i],
                _tokenIds[i]
            );
        }
    }

}

