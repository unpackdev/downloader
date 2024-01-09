// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./INftCollection.sol";
import "./AuthorizeAccess.sol";
import "./OperatorAccess.sol";
import "./ContractGuard.sol";

/** @title NftMintingStation.
 */
contract NftMintingStation is AuthorizeAccess, OperatorAccess, EIP712, ReentrancyGuard, ContractGuard {
    using Address for address;
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint8 public constant STATUS_NOT_INITIALIZED = 0;
    uint8 public constant STATUS_PREPARING = 1;
    uint8 public constant STATUS_CLAIM = 2;
    uint8 public constant STATUS_CLOSED = 3;

    uint8 public currentStatus = STATUS_NOT_INITIALIZED;

    uint256 public maxSupply;
    uint256 public availableSupply;
    uint256 public unitPrice;

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

    function setUnitPrice(uint256 _amount) external onlyOwnerOrOperator {
        unitPrice = _amount;
    }

    function setStatus(uint8 _status) external onlyOwnerOrOperator {
        currentStatus = _status;
    }

    function getNextTokenId() internal virtual returns (uint256) {
        return maxSupply - availableSupply + 1;
    }

    function _mint(uint256 _quantity, address _to) internal {
        require(availableSupply >= _quantity, "Not enough supply");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = getNextTokenId();
            nftCollection.mint(_to, tokenId);
            availableSupply = availableSupply - 1;
        }
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
