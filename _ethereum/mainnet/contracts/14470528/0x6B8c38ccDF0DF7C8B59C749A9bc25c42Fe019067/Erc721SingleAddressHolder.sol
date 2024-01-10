// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./ERC721.sol";

/**
 * @dev holds and manages tokens from a single address
 * in order to use, the giving contracts must call
 * function setApprovalForAll(THE_ADDRESS_OF_THIS_CONTRACT, true)
 */
contract Erc721SingleAddressHolder is IERC721Receiver {
    address public proxyAddr;
    uint256[] public availableErc721Tokens;

    constructor(address _proxyAddr) {
        proxyAddr = _proxyAddr;
    }

    function safeGetFirstErc721Token() public view returns (uint256) {
        return availableErc721Tokens.length > 0 ? availableErc721Tokens[0] : 0;
    }

    function _removeListedErc721Token(uint256 tokenId) internal {
        uint256 len = availableErc721Tokens.length;
        for (uint256 i = 0; i < len; i++) {
            if (availableErc721Tokens[i] == tokenId) {
                availableErc721Tokens[i] = availableErc721Tokens[len - 1];
                availableErc721Tokens.pop();
                return;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) public virtual override returns (bytes4) {
        if (msg.sender == proxyAddr) {
            availableErc721Tokens.push(tokenId);
        }
        return this.onERC721Received.selector;
    }

    function _safeTransferErc721Token(
        uint256 tokenId,
        address to,
        bytes calldata data
    ) internal {
        ERC721 nft = ERC721(proxyAddr);
        nft.safeTransferFrom(address(this), to, tokenId, data);
        _removeListedErc721Token(tokenId);
    }
}
