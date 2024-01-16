// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC165Checker.sol";
import "./IERC721.sol";
import "./LibSwap.sol";
import "./LibEIP712.sol";

abstract contract ValidatorSwap {

    string private constant _VERSION_SWAP = "1.0";
    uint8 private constant _MAX_TOKENS = 10;

    /**
     * @dev Return swap cancell status
     * @return  cancelld mapping of cancelled swap
     */
    function getCancelled() internal virtual view returns (mapping(address => mapping(bytes32 => bool)) storage);

    /**
     * @dev Return swap filled status
     * @return  filled mapping of filled swap
     */
    function getFilled() internal virtual view returns (mapping (bytes32 => bool) storage);

    /**
     * @dev Validate swap and signature
     * @param swap Swap struct containing swap specifications.
     * @param  signature Proof that swap has been created by maker.
     * @param  swapInfo Infor about actual swap before validation.
     */
    function validateFillSwap(
        LibSwap.Swap calldata swap, bytes calldata signature, LibSwap.SwapInfo memory swapInfo) 
        internal view {
        _validateCommonSwap(swap, signature, swapInfo);
        _isSender(swap.takerAddress);
        _isExpired(swapInfo.timestamp, swap.expirationTimeSeconds);
        _isValidTokenData(swap.makerTokenData, swap.makerAddress);
        _isValidTokenData(swap.takerTokenData, swap.takerAddress);


    }

    function validateCancelSwap(
        LibSwap.Swap calldata swap, bytes calldata signature, LibSwap.SwapInfo memory swapInfo) 
        internal view {
        _validateCommonSwap(swap, signature, swapInfo);
        _isSender(swap.makerAddress); 
    }

    function _validateCommonSwap(
        LibSwap.Swap calldata swap, bytes calldata signature, LibSwap.SwapInfo memory swapInfo) 
        private view {
        _isVersionValid(swap.version);
        _addressIsNotZero(swap.makerAddress);
        _addressIsNotZero(swap.takerAddress);
        _isFilled(swapInfo.swapHash);
        _isCancelled(swap.makerAddress, swapInfo.swapHash);
        _isValidSignature(swap.makerAddress, swapInfo.swapHash, signature);
    }

    function _isVersionValid(string calldata version) private pure {
        require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked(_VERSION_SWAP)), 
            "Invalid Swap version");
    }

    function _addressIsNotZero(address addrs) private pure {
        require(addrs != address(0), "Adderss con't be 0");
    }

    function _isSender(address operator) private view {
        require(operator == msg.sender, "Sender not allowed");
    }

    function _isExpired(uint256 fillTime, uint256 expirationTime) private pure {
        require(fillTime <= expirationTime, "Swap has expired");
    }

    function _isCancelled(address maker, bytes32 swapHash) private view {
        require(getCancelled()[maker][swapHash] ==  false, "The swap has already been cancelled");

    }

    function _isFilled(bytes32 swapHash) private view {
        require(getFilled()[swapHash] ==  false, "The swap has already been filled");

    }

    function _isValidSignature(address signer, bytes32 swapHash, bytes memory signature) private view {
        require(LibEIP712.isValidSignature(signer, swapHash, signature), "Invalid signature");

    }

    function _isValidTokenData(LibSwap.TokenData[] calldata tokenData, address owner) private view {
        require(tokenData.length != 0, "There is not token data");
        require(tokenData.length <= _MAX_TOKENS, "Max number tokens rached");

        for(uint256 i = 0; i < tokenData.length; i++) {
            _isValidTokenData(tokenData[i], owner);
        }
    }

    function _isValidTokenData(LibSwap.TokenData calldata tokenData, address owner) private view {
        _isValidTokenDataCommon(tokenData);
        _isValidTokenDataERC721(tokenData, owner);

    }

    function _isValidTokenDataCommon(LibSwap.TokenData calldata tokenData) private pure {
        _isTokenTypeValid(tokenData.tokenType);
        _addressIsNotZero(tokenData.tokenContract);
    }

    function _isTokenTypeValid(LibSwap.TokenType tokenType) private pure {
        require( 0 <= uint8(tokenType) && uint8(tokenType) <= 2, "Token type invalid");
        require( tokenType == LibSwap.TokenType.ERC721, "Not implemented. Only ERC721 alowed");
    }

    function _isValidTokenDataERC721(LibSwap.TokenData calldata tokenData, address owner) private view {
        if(tokenData.tokenType == LibSwap.TokenType.ERC721) {
            require(tokenData.amount == 1, "Amount must be 1");

            require(
                ERC165Checker.supportsInterface(tokenData.tokenContract, type(IERC721).interfaceId), "Contract not supported");

            require(IERC721(tokenData.tokenContract).ownerOf(tokenData.tokenId) == owner, 
                    "Token is not owned by address");

            require(IERC721(tokenData.tokenContract).getApproved(tokenData.tokenId) == address(this) 
                    || IERC721(tokenData.tokenContract).isApprovedForAll(owner, address(this)),
                    "SP Swap is not approved for this token");
        }
    }
}
