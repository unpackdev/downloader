pragma solidity ^0.8.4;
pragma abicoder v2;

//SPDX-License-Identifier: MIT

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

import "./LibPart.sol";

//import "./console.sol";

contract Payment is Initializable, EIP712Upgradeable, AccessControlUpgradeable {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    string private constant SIGNING_DOMAIN = "Xooa Market";
    string private constant SIGNATURE_VERSION = "1";

    bytes32 public constant PAY_TYPEHASH =
        keccak256(
            "Order(string transferId,string appId,Part[] fees)Part(address account,uint96 value)"
        );

    struct OrderData {
        string transferId;
        string appId;
        LibPart.Part[] fees;
        bytes signature;
    }

    event PaymentEvent(string transferId, string appId);

    constructor(address signer) {}

    function initialize(address signer) public initializer {
        require(signer != address(0), "Trusted signer is required");

        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        _setupRole(SIGNER_ROLE, signer);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _totalFunds(LibPart.Part[] memory fees)
        internal
        pure
        returns (uint256)
    {
        uint256 totalFees = 0;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees += fees[i].value;
        }
        return totalFees;
    }

    function pay(OrderData calldata data) public payable virtual {
        require(
            _verify(_hash(data), data.signature),
            "Signature invalid or unauthorized"
        );

        require(msg.value >= _totalFunds(data.fees), "Insufficient funds");

        for (uint256 i = 0; i < data.fees.length; i++) {
            data.fees[i].account.transfer(data.fees[i].value);
        }
        emit PaymentEvent(data.transferId, data.appId);
    }

    function _hash(OrderData calldata data) internal view returns (bytes32) {
        bytes32[] memory feesBytes = new bytes32[](data.fees.length);
        for (uint256 i = 0; i < data.fees.length; i++) {
            feesBytes[i] = LibPart.hash(data.fees[i]);
        }

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PAY_TYPEHASH,
                        keccak256(bytes(data.transferId)),
                        keccak256(bytes(data.appId)),
                        keccak256(abi.encodePacked(feesBytes))
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            hasRole(SIGNER_ROLE, ECDSAUpgradeable.recover(digest, signature));
    }
}
