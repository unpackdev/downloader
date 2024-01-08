// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165Checker.sol";

import "./INFT2ERC20.sol";

contract ERC721NFT2ERC20Receiver is IERC721Receiver {

    address private _nft2erc20;
    mapping (address => bool) private _approved;

    constructor (address nft2erc20) {
        require(ERC165Checker.supportsInterface(nft2erc20, type(INFT2ERC20).interfaceId), "ERC721NFT2ERC20Receiver: Must implement INFT2ERC20");
        _nft2erc20 = nft2erc20;
    }

    /*
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns(bytes4) {    
        if (!_approved[msg.sender]) {
            IERC721(msg.sender).setApprovalForAll(_nft2erc20, true);
            _approved[msg.sender] = true;
        }
        uint256[] memory args = new uint256[](1);
        args[0] = tokenId;
        INFT2ERC20(_nft2erc20).burnToken(msg.sender, args, 'erc721', from);
        return this.onERC721Received.selector;
    }
}
