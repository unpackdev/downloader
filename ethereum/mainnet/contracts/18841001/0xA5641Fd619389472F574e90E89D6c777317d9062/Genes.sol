// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IGenes.sol";

import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

abstract contract Genes is Initializable, EIP712Upgradeable, IGenes {
    
    using ECDSAUpgradeable for bytes32;


    bytes32 private constant TYPEHASH = keccak256("uint256 tokenId");

    mapping(bytes => bool) private invalid;

    function __Genes_init() internal onlyInitializing {
        __EIP712_init("SignatureGenes", "1");
    }

    function __Genes_init_unchained() internal onlyInitializing {}

    function verifyTokenId(uint256 _tokenId, bytes calldata _sig)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_tokenId, _sig);

        success = _isAuthorizedSigner2(signer);
    }

    function _isAuthorizedSigner2(address _signer) public view virtual returns (bool);

    function _recoverAddress(uint256 _tokenId, bytes calldata _sig) internal view returns (address) {
        bytes32 structHash = keccak256(_encodeRequest(_tokenId));
        return _hashTypedDataV4(structHash).recover(_sig);
    }

    function _encodeRequest(uint256 _tokenId) internal pure returns (bytes memory) {
        return abi.encode(TYPEHASH, _tokenId);
    }


    
}
