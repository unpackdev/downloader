// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Validator.sol";
import "./IBountyBoard.sol";

contract IdValidator is IERC721Validator, Ownable {
    event IdsSet(IBountyBoard.ERC721Grouping[] tokenGroupings, bool set);

    mapping(address => mapping(uint256 => bool)) public acceptedTokens;

    // Used in ValidatorCloneFactory.
    function initialize(
        address _owner,
        IBountyBoard.ERC721Grouping[] calldata tokenGroupings
    ) external {
        require(owner() == address(0));
        _transferOwnership(_owner);
        _setIds(tokenGroupings, true);
    }

    function setIds(
        IBountyBoard.ERC721Grouping[] calldata tokenGroupings,
        bool set
    ) external onlyOwner {
        _setIds(tokenGroupings, set);
    }

    function _setIds(
        IBountyBoard.ERC721Grouping[] calldata tokenGroupings,
        bool set
    ) internal {
        for (uint256 i = 0; i < tokenGroupings.length; i++) {
            IBountyBoard.ERC721Grouping memory grouping = tokenGroupings[i];
            mapping(uint256 => bool) storage acceptedIds = acceptedTokens[
                address(grouping.erc721)
            ];
            uint256[] memory idsToSet = grouping.ids;
            for (uint256 j = 0; j < idsToSet.length; j++) {
                acceptedIds[idsToSet[j]] = set;
            }
        }
        emit IdsSet(tokenGroupings, set);
    }

    function meetsCriteria(address tokenAddr, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return acceptedTokens[tokenAddr][tokenId];
    }
}
