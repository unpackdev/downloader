// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ECDSAUpgradeable.sol";

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ExtensionUpgradeable.sol";

abstract contract CouponExtension is Initializable, ExtensionUpgradeable, AccessControlEnumerableUpgradeable {

    error CouponExtension_WrongSigner(address signer);
    error CouponExtension_WrongEthValue(uint256 value);
    error CouponExtension_CouponExpired(uint256 deadline);

    using ECDSAUpgradeable for bytes32;

    bytes32 public constant COUPON_EXTENSION = keccak256('CouponExtension');
    bytes32 private constant DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');
    bytes32 public constant SIGNER_ROLE = keccak256('SIGNER_ROLE');

    mapping(address => uint256) public nonces;
    address payable public saleEthRecipient;

    function __CouponExtension_init(address signer) internal onlyInitializing {
        __CouponExtension_init_unchained(signer);
    }

    function __CouponExtension_init_unchained(address signer) internal onlyInitializing {
        _grantRole(SIGNER_ROLE, signer);
    }

    function initializeCouponExtension(address payable _saleEthRecipient) public onlyRole(DEPLOYER_ROLE) {
        initializeExtension(COUPON_EXTENSION);
        saleEthRecipient = _saleEthRecipient;
    }

    function setSaleEthRecipient(address payable _saleEthRecipient) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        saleEthRecipient = _saleEthRecipient;
    }

    function _checkCoupon(uint256 tokenId, uint256 price, uint256 amount, uint256 deadline, bytes calldata signature) internal {
        bytes32 message = keccak256(abi.encodePacked(msg.sender, tokenId, price, amount, deadline, nonces[msg.sender]));
        address signer = message.recover(signature);

        if (!hasRole(SIGNER_ROLE, signer)) {
            revert CouponExtension_WrongSigner(signer);
        }
        if (msg.value != price) {
            revert CouponExtension_WrongEthValue(price);
        }
        if (block.timestamp > deadline) {
            revert CouponExtension_CouponExpired(deadline);
        }

        nonces[msg.sender]++;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}
