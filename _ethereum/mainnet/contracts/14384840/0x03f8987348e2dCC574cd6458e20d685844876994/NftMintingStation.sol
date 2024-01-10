// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./Address.sol";
import "./INftCollection.sol";
import "./AuthorizeAccess.sol";
import "./OperatorAccess.sol";

/** @title NftMintingStation.
 */
contract NftMintingStation is AuthorizeAccess, OperatorAccess, EIP712 {
    using Address for address;
    using ECDSA for bytes32;

    uint8 public constant STATUS_NOT_INITIALIZED = 0;
    uint8 public constant STATUS_PREPARING = 1;
    uint8 public constant STATUS_CLAIM = 2;
    uint8 public constant STATUS_CLOSED = 3;

    uint8 public currentStatus = STATUS_NOT_INITIALIZED;

    uint256 public maxSupply;
    uint256 public availableSupply;

    INftCollection public nftCollection;

    // modifier to allow execution by owner or operator
    modifier onlyOwnerOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "Not an owner or operator"
        );
        _;
    }

    constructor(
        INftCollection _nftCollection,
        string memory _eipName,
        string memory _eipVersion
    ) EIP712(_eipName, _eipVersion) {
        nftCollection = _nftCollection;
    }

    function setStatus(uint8 _status) external onlyOwnerOrOperator {
        currentStatus = _status;
    }

    function getNextTokenId() internal virtual returns (uint256) {
        return maxSupply - availableSupply + 1;
    }

    function _mint(uint256 _quantity, address _to) internal returns (uint256[] memory) {
        require(availableSupply >= _quantity, "Not enough supply");

        uint256[] memory tokenIds = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = getNextTokenId();
            availableSupply = availableSupply - 1;
            tokenIds[i] = tokenId;
        }

        if (_quantity == 1) {
            nftCollection.mint(_to, tokenIds[0]);
        } else {
            nftCollection.mintBatch(_to, tokenIds);
        }

        return tokenIds;
    }

    function _syncSupply() internal {
        uint256 totalSupply = nftCollection.totalSupply();
        maxSupply = nftCollection.maxSupply();
        availableSupply = maxSupply - totalSupply;
    }

    function syncSupply() external onlyOwnerOrOperator {
        _syncSupply();
    }

    /**
     * @notice verifify signature is valid for `structHash` and signers is a member of role `AUTHORIZER_ROLE`
     * @param structHash: hash of the structure to verify the signature against
     */
    function isAuthorized(bytes32 structHash, bytes memory signature) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(structHash);
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && hasRole(AUTHORIZER_ROLE, recovered)) {
            return true;
        }

        return false;
    }
}
