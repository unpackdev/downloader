// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./Lendable.sol";
import "./Roles.sol";

contract ERC721Metadata is
    IERC721Metadata,
    Lendable,
    Roles
{
    string private constant nftName = "Aelig";
    string private constant nftSymbol = "AELIG";
    string private baseURL;

    function name()
        external
        override
        pure
        returns(string memory)
    {
        return nftName;
    }

    function symbol()
        external
        override
        pure
        returns(string memory)
    {
        return nftSymbol;
    }

    function tokenURI(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        return baseURL;
    }

    function updateBaseUrl(
        string memory _newBaseUrl
    )
        isAdmin(msg.sender)
        external
        override
    {
        baseURL = _newBaseUrl;
        emit BaseUrlUpdate(_newBaseUrl);
    }
}
