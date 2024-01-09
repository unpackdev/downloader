// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./Whitelist.sol";
import "./ERC721Holder.sol";

interface IToken {
    function mintHedgie(uint256 tier, bytes32[] calldata merkleProof) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract Mint is ERC721Holder, Whitelist {
    address public _contractAddress;
    bytes32[] public _merkleProof;

    constructor(address contractAddress, bytes32[] memory merkleProof) {
        _contractAddress = contractAddress;
        _merkleProof = merkleProof;
    }

    function mint(uint256 amount) external onlyWhitelisted {
        IToken token = IToken(_contractAddress);

        uint256 mintedAmount = amount;

        for (uint256 i = 0; i < amount; i++) {
            try token.mintHedgie(2, _merkleProof) {
                continue;
            } catch {
                mintedAmount = i;
                break;
            }
        }

        if (mintedAmount > 0) {
            _withdraw(_getTokenIds(mintedAmount), msg.sender);
        }
    }

    function _getTokenIds(uint256 amount) internal returns (uint256[] memory) {
        IToken token = IToken(_contractAddress);
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = token.tokenOfOwnerByIndex(address(this), i);
        }
        return tokenIds;
    }

    function _withdraw(uint256[] memory tokenIds, address recipient) internal {
        IToken token = IToken(_contractAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            token.safeTransferFrom(address(this), recipient, tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds, address recipient)
        external
        onlyWhitelisted
    {
        _withdraw(tokenIds, recipient);
    }
}
