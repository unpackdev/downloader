// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Custom.sol";
import "./NonblockingReceiverCollectableBox.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract CollectableBox is
    ERC721Custom,
    Ownable,
    NonblockingReceiverCollectableBox
{
    using ECDSA for bytes32;
    address public nftContractAddress;
    mapping(uint256 => bool) public claimed; // tokenId => isClaimed

    error BoxAlreadyClaimed();
    error InvalidSignature();
    error CallerNotNFTContract();
    error NFTContractAlreadySet();
    error BoxDoesNotExist();

    constructor(
        string memory name_,
        string memory symbol_,
        uint16 sourceChainId_,
        address collectorContractAddress_,
        address lzEndpoint_
    ) ERC721Custom(name_, symbol_) {
        _lzEndpoint = ILayerZeroEndpoint(lzEndpoint_);
        sourceChainId = sourceChainId_;
        collectorContractAddress = abi.encodePacked(collectorContractAddress_);
    }

    modifier onlyNFTContract() {
        if (msg.sender != nftContractAddress) revert CallerNotNFTContract();
        _;
    }

    function setNFTContractAddress(address nftContractAddress_)
        public
        onlyOwner
    {
        if (nftContractAddress != address(0)) revert NFTContractAlreadySet();
        nftContractAddress = nftContractAddress_;
    }

    function _lzReceive(bytes memory _payload) internal virtual override {
        (address owner, uint256[] memory tokenIds) = abi.decode(
            _payload,
            (address, uint256[])
        );
        // (address owner, uint256 tokenId) = abi.decode(
        //     _payload,
        //     (address, uint256)
        // );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId >= 750) revert BoxDoesNotExist();
            if (claimed[tokenId]) revert BoxAlreadyClaimed();
            claimed[tokenId] = true;
            _safeMint(owner, tokenId);
        }
    }

    function burn(uint256 tokenId) public onlyNFTContract {
        _burn(tokenId);
    }
}
