// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ERC1155Base.sol";
import "./ERC165Base.sol";
import "./OwnableInternal.sol";
import "./ERC1155Metadata.sol";

contract ERC1155Facet is
    ERC1155Base,
    ERC165Base,
    OwnableInternal,
    ERC1155Metadata
{
    function devMint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _mint(to, id, amount, "");
    }

    function devMintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function devBurn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _burn(from, id, amount);
    }

    function devBurnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyOwner {
        _burnBatch(from, ids, amounts);
    }

    /// @notice Admin function to set the base URI for token IDs
    function setTokenURI(uint256 id, string calldata uri) public onlyOwner {
        _setTokenURI(id, uri);
    }

    function batchSetTokenUri(uint256[] calldata ids, string[] calldata uris)
        public
        onlyOwner
    {
        require(
            ids.length == uris.length,
            "ERC1155Facet: ids and uris length mismatch"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            _setTokenURI(ids[i], uris[i]);
        }
    }
}
