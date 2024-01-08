// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Address.sol";

/*
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;
    using Address for address;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant TYPEHASH = keccak256(
        "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
    );

    mapping(address => mapping(uint256 => bool)) private _nonces;

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        virtual
        returns (bool)
    {
        address signer =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        TYPEHASH,
                        req.from,
                        req.to,
                        req.value,
                        req.gas,
                        req.nonce,
                        keccak256(req.data)
                    )
                )
            )
                .recover(signature);
        return !_nonces[req.from][req.nonce] && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        virtual
        returns (bool, bytes memory)
    {
        require(
            verify(req, signature),
            "MinimalForwarder: signature does not match request"
        );
        _nonces[req.from][req.nonce] = true;

        (bool success, bytes memory returndata) = req.to.call(abi.encodePacked(req.data, req.from));

        return (success, returndata);
    }
}
