//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";

import "./NonblockingLzApp.sol";
import "./IONFT.sol";

abstract contract Traversable is ERC721, Ownable, NonblockingLzApp, IONFT {
    mapping(uint256 => uint256) private _birthChainSeeds;
    mapping(uint256 => uint256) private _tokenIdSeeds;

    constructor(address layerZeroEndpoint)
        NonblockingLzApp(layerZeroEndpoint)
    {} // solhint-disable-line no-empty-blocks

    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) external payable virtual override {
        _send(
            from,
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );
    }

    function send(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) external payable virtual override {
        _send(
            _msgSender(),
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );
    }

    function getTraversableSeeds(uint256 tokenId)
        public
        view
        returns (uint256 birthChainSeed, uint256 tokenIdSeed)
    {
        return (_birthChainSeeds[tokenId], _tokenIdSeeds[tokenId]);
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParam
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Traversable: transfer caller is not owner nor approved"
        );
        (uint256 birthChainSeed, uint256 tokenIdSeed) = getTraversableSeeds(
            tokenId
        );

        _unregisterTraversableSeeds(tokenId);
        _burn(tokenId);

        bytes memory payload = abi.encode(
            toAddress,
            tokenId,
            birthChainSeed,
            tokenIdSeed
        );

        _lzSend(
            dstChainId,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParam
        );

        uint64 nonce = lzEndpoint.getOutboundNonce(dstChainId, address(this));
        emit SendToChain(from, dstChainId, toAddress, tokenId, nonce);
    }

    function _registerTraversableSeeds(
        uint256 tokenId,
        uint256 birthChainSeed,
        uint256 tokenIdSeed
    ) internal {
        _birthChainSeeds[tokenId] = birthChainSeed;
        _tokenIdSeeds[tokenId] = tokenIdSeed;
    }

    function _unregisterTraversableSeeds(uint256 tokenId) internal {
        delete _birthChainSeeds[tokenId];
        delete _tokenIdSeeds[tokenId];
    }

    function _nonblockingLzReceive(
        uint16 srcChainId, // solhint-disable-line no-unused-vars
        bytes memory srcAddress, // solhint-disable-line no-unused-vars
        uint64 nonce, // solhint-disable-line no-unused-vars
        bytes memory payload
    ) internal override {
        (
            bytes memory toAddress,
            uint256 tokenId,
            uint256 birthChainSeed,
            uint256 tokenIdSeed
        ) = abi.decode(payload, (bytes, uint256, uint256, uint256));
        address localToAddress;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            localToAddress := mload(add(toAddress, 20))
        }
        if (localToAddress == address(0x0)) localToAddress == address(0xdEaD);

        _safeMint(localToAddress, tokenId);
        _registerTraversableSeeds(tokenId, birthChainSeed, tokenIdSeed);

        emit ReceiveFromChain(srcChainId, localToAddress, tokenId, nonce);
    }
}
