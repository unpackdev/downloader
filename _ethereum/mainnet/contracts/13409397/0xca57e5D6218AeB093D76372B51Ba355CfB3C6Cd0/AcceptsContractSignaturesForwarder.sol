// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;
pragma abicoder v2;

import "./ECDSA.sol";
import "./Address.sol";
import "./IERC1271.sol";
import "./IForwarder.sol";

contract AcceptsContractSignaturesForwarder is IForwarder {
    string public constant GENERIC_PARAMS =
        "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil";
    string public constant EIP712_DOMAIN_TYPE =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    mapping(bytes32 => bool) public typeHashes;
    mapping(bytes32 => bool) public domains;
    mapping(address => uint256) private nonces;

    function getNonce(address from) public view override returns (uint256) {
        return nonces[from];
    }

    constructor() {
        string memory requestType = string(
            abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")")
        );
        registerRequestTypeInternal(requestType);
    }

    function verify(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    ) external view override {
        require(req.value == 0, "FWD: forwarder does not allow calls with value");
        _verifyNonce(req);
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    }

    function execute(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    ) external payable override returns (bool success, bytes memory ret) {
        require(
            req.value == 0 && msg.value == 0,
            "FWD: forwarder does not allow calls with value"
        );
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
        _verifyAndUpdateNonce(req);

        require(req.validUntil == 0 || req.validUntil > block.number, "FWD: request expired");

        bytes memory callData = abi.encodePacked(req.data, req.from);
        require((gasleft() * 63) / 64 >= req.gas, "FWD: insufficient gas");

        // solhint-disable-next-line avoid-low-level-calls
        (success, ret) = req.to.call{gas: req.gas}(callData);

        return (success, ret);
    }

    function _verifyNonce(ForwardRequest calldata req) internal view {
        require(nonces[req.from] == req.nonce, "FWD: nonce mismatch");
    }

    function _verifyAndUpdateNonce(ForwardRequest calldata req) internal {
        require(nonces[req.from]++ == req.nonce, "FWD: nonce mismatch");
    }

    function registerRequestType(string calldata typeName, string calldata typeSuffix)
        external
        override
    {
        for (uint256 i = 0; i < bytes(typeName).length; i++) {
            bytes1 c = bytes(typeName)[i];
            require(c != "(" && c != ")", "FWD: invalid typename");
        }

        string memory requestType = string(
            abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix)
        );
        registerRequestTypeInternal(requestType);
    }

    function registerDomainSeparator(string calldata name, string calldata version)
        external
        override
    {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            chainId := chainid()
        }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        );

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    function registerRequestTypeInternal(string memory requestType) internal {
        bytes32 requestTypehash = keccak256(bytes(requestType));

        typeHashes[requestTypehash] = true;

        emit RequestTypeRegistered(requestTypehash, requestType);
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    ) internal view {
        require(domains[domainSeparator], "FWD: unregistered domain sep.");
        require(typeHashes[requestTypeHash], "FWD: unregistered typehash");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(_getEncoded(req, requestTypeHash, suffixData))
            )
        );
        require(isValidSignature(req.from, digest, sig), "FWD: signature mismatch");
    }

    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        if (Address.isContract(signer)) {
            try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
                return magicValue == IERC1271.isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSA.recover(hash, signature) == signer;
        }
    }

    function _getEncoded(
        ForwardRequest calldata req,
        bytes32 requestTypeHash,
        bytes calldata suffixData
    ) public pure returns (bytes memory) {
        // we use encodePacked since we append suffixData as-is, not as dynamic param.
        // still, we must make sure all first params are encoded as abi.encode()
        // would encode them - as 256-bit-wide params.
        return
            abi.encodePacked(
                requestTypeHash,
                uint256(uint160(req.from)),
                uint256(uint160(req.to)),
                req.value,
                req.gas,
                req.nonce,
                keccak256(req.data),
                req.validUntil,
                suffixData
            );
    }
}
