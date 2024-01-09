// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165Checker.sol";

import "./INFT2ERC20.sol";

contract ERC721NFT2ERC20Receiver is IERC721Receiver, Ownable {
    address private _nft2erc20;
    address private _fomoverse;
    mapping (address => bool) private _approved;
    mapping (address => uint16) private _splitBPS;

    constructor (address nft2erc20) {
        require(ERC165Checker.supportsInterface(nft2erc20, type(INFT2ERC20).interfaceId), "ERC721NFT2ERC20Receiver: Must implement INFT2ERC20");
        _nft2erc20 = nft2erc20;
    }

    function addSplit(address tokenAddress, uint16 splitBPS) external onlyOwner {
        require(splitBPS <= 10000, "Invalid BPS");
        _splitBPS[tokenAddress] = splitBPS;
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
        uint16 splitBPS = _splitBPS[msg.sender];
        if (splitBPS > 0) {
            uint256 priorBalance = INFT2ERC20(_nft2erc20).balanceOf(address(this));
            INFT2ERC20(_nft2erc20).burnToken(msg.sender, args, 'erc721', address(this));
            uint256 newBalance = INFT2ERC20(_nft2erc20).balanceOf(address(this));
            uint256 tokensReceived = newBalance - priorBalance;
            uint256 ownerAmount = tokensReceived*splitBPS/10000;
            uint256 senderAmount = tokensReceived-ownerAmount;
            INFT2ERC20(_nft2erc20).transfer(owner(), ownerAmount);
            INFT2ERC20(_nft2erc20).transfer(from, senderAmount);
        } else {
            INFT2ERC20(_nft2erc20).burnToken(msg.sender, args, 'erc721', from);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * Legacy onERC721Received for Makersplace tokens
     */
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external returns(bytes4) {
        if (!_approved[msg.sender]) {
            IERC721(msg.sender).setApprovalForAll(_nft2erc20, true);
            _approved[msg.sender] = true;
        }
        uint256[] memory args = new uint256[](1);
        args[0] = _tokenId;
        INFT2ERC20(_nft2erc20).burnToken(msg.sender, args, 'erc721', _from);
        return 0xf0b9e5ba;
    }

}