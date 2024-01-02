// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";
import "./Utils.sol";

/**
 * @title - dev3.eth : ENS-on-Github Resolver implementing CCIP-Read & Wildcard Resolution
 * @author - sshmatrix.eth, freetib.eth
 * @notice - https://dev3.eth.limo
 * https://github.com/namesys-eth/dev3-eth-resolver
 */
contract Dev3 is iDev3 {
    using Utils for *;

    address public owner;
    iENS public immutable ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    error InvalidRequest(string);
    error InvalidSignature(string);
    error FeatureNotImplemented(bytes4);

    string public chainID = block.chainid == 1 ? "1" : "5";

    event ApprovedSigner(bytes32 indexed _node, address indexed _signer, bool indexed _set);
    event DomainSetup(bytes32 indexed _node, string _gateway, bool _core);
    event WrapperUpdate(address indexed _wrapper, bool indexed _set);
    event FunctionMapUpdate(bytes4 indexed _func, string _name);
    event ThankYou(address indexed _addr, uint256 indexed _value);

    /**
     * @dev Checks if a given selector is supported by this contract
     * @param _selector The selector to check
     * @return true if the selector is supported, false otherwise
     */
    function supportsInterface(bytes4 _selector) external pure returns (bool) {
        return (_selector == Dev3.resolve.selector || _selector == Dev3.supportsInterface.selector);
    }

    struct Space {
        bool _core;
        string _gateway;
        string _fallback;
    }

    mapping(bytes32 => Space) public dev3Space;
    mapping(bytes4 => string) public funcMap;
    mapping(bytes32 => mapping(address => bool)) public isApprovedSigner;
    mapping(address => bool) public isWrapper;

    constructor() {
        owner = msg.sender;
        funcMap[iResolver.addr.selector] = "address/60";
        funcMap[iResolver.pubkey.selector] = "publickey";
        funcMap[iResolver.name.selector] = "name"; // NOT used for reverse lookup
        funcMap[iResolver.contenthash.selector] = "contenthash";
        funcMap[iResolver.zonehash.selector] = "dns/zonehash";
        funcMap[iResolver.recordVersions.selector] = "version";

        bytes32 _root = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        bytes32 _node = keccak256(abi.encodePacked(_root, keccak256("dev3")));
        dev3Space[_node] = Space(true, "namesys-eth.github.io", "dev3.namesys.xyz");
        isApprovedSigner[_node][0xae9Cc8813ab095cD38F3a8d09Aecd66b2B2a2d35] = true;
        emit DomainSetup(_node, "namesys-eth.github.io", true);
        emit ApprovedSigner(_node, 0xae9Cc8813ab095cD38F3a8d09Aecd66b2B2a2d35, true);
        _node = keccak256(abi.encodePacked(_root, keccak256("isdev")));
        dev3Space[_node] = Space(true, "namesys-eth.github.io", "dev3.namesys.xyz");
        isApprovedSigner[_node][0xae9Cc8813ab095cD38F3a8d09Aecd66b2B2a2d35] = true;
        emit DomainSetup(_node, "namesys-eth.github.io", true);
        emit ApprovedSigner(_node, 0xae9Cc8813ab095cD38F3a8d09Aecd66b2B2a2d35, true);
        isWrapper[0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401] = true;
    }

    /**
     * @dev Resolves a given ENS name and returns the corresponding record (ENSIP-10)
     * @param name DNS-encoded subdomain or domain.eth
     * @param request ENS Resolver request
     * @return result The resolved record
     */
    function resolve(bytes calldata name, bytes calldata request) external view returns (bytes memory) {
        uint256 level;
        uint256 pointer;
        uint256 len;
        bytes[] memory _labels = new bytes[](43);
        string memory _path;
        while (name[pointer] > 0x0) {
            len = uint8(bytes1(name[pointer:++pointer]));
            _labels[level] = name[pointer:pointer += len];
            _path = string.concat(string(_labels[level++]), "/", _path);
        }
        string[] memory _urls = new string[](2);
        string memory _recordType = jsonFile(request);
        string memory _gateway;
        pointer = level;
        bytes32 _namehash = keccak256(abi.encodePacked(bytes32(0), keccak256(_labels[--pointer])));
        bytes32 _node;
        while (pointer > 0) {
            _namehash = keccak256(abi.encodePacked(_namehash, keccak256(_labels[--pointer])));
            if (bytes(dev3Space[_namehash]._gateway).length > 0) {
                _node = _namehash;
            }
        }
        if (_node == 0x0) revert InvalidRequest("INVALID_DOMAIN");
        if (!dev3Space[_node]._core || level == 2) {
            _gateway = dev3Space[_node]._gateway;
            _urls[0] = string.concat("https://", _gateway, "/.well-known/", _path, _recordType, ".json?{data}");
            _urls[1] = bytes(dev3Space[_node]._fallback).length == 0
                ? string.concat(_urls[0], "=retry")
                : string.concat(
                    "https://", dev3Space[_node]._fallback, "/.well-known/", _path, _recordType, ".json?{data}=retry"
                );
        } else {
            _gateway = string.concat(string(_labels[level - 3]), ".github.io");
            _urls[0] = string.concat("https://", _gateway, "/.well-known/", _path, _recordType, ".json?{data}");
            _urls[1] = string.concat(
                "https://raw.githubusercontent.com/",
                string(_labels[level - 3]),
                "/",
                _gateway,
                "/main/.well-known/",
                _path,
                _recordType,
                ".json?{data}"
            );
        }
        bytes32 _callhash = keccak256(msg.data);
        uint256 _blockNum = block.number - 1;
        bytes32 _checkhash = keccak256(abi.encodePacked(this, blockhash(_blockNum), _callhash));
        revert OffchainLookup(
            address(this),
            _urls,
            abi.encodePacked(uint16(block.timestamp / 60)),
            iENSIP10.__callback.selector,
            abi.encode(_blockNum, _callhash, _checkhash, _node, _gateway, _recordType)
        );
    }

    /**
     * @dev Callback function called by ENSIP-10 resolver to handle off-chain lookup
     * @param response The response from the off-chain lookup
     * @param extradata Extra data for processing the off-chain lookup response
     * @return result The result of the off-chain lookup
     */
    function __callback(bytes calldata response, bytes calldata extradata)
        external
        view
        returns (bytes memory result)
    {
        (
            uint256 _blocknumber,
            bytes32 _callhash,
            bytes32 _checkhash,
            bytes32 _node,
            string memory _gateway,
            string memory _recType
        ) = abi.decode(extradata, (uint256, bytes32, bytes32, bytes32, string, string));
        if (block.number > _blocknumber + 4) {
            revert InvalidRequest("CALLBACK_TIMEOUT");
        }
        if (_checkhash != keccak256(abi.encodePacked(this, blockhash(_blocknumber), _callhash))) {
            revert InvalidRequest("CHECKSUM_FAILED");
        }
        if (bytes4(response[:4]) != iCallbackType.signedRecord.selector) {
            revert InvalidRequest("BAD_RECORD_PREFIX");
        }
        (address _signer, bytes memory _recordSig, bytes memory _approvedSig, bytes memory _result) =
            abi.decode(response[4:], (address, bytes, bytes, bytes));
        address _manager = ENS.owner(_node);
        if (isWrapper[_manager]) {
            _manager = iToken(_manager).ownerOf(uint256(_node));
        }
        if (_approvedSig.length > 63) {
            address _approvedBy = Dev3(this).getSigner(
                string.concat(
                    "Requesting Signature To Approve ENS Records Signer\n",
                    "\nGateway: https://",
                    _gateway,
                    "\nResolver: eip155:",
                    chainID,
                    ":",
                    address(this).toChecksumAddress(),
                    "\nApproved Signer: eip155:",
                    chainID,
                    ":",
                    _signer.toChecksumAddress()
                ),
                _approvedSig
            );
            if (!isApprovedSigner[_node][_approvedBy]) {
                revert InvalidSignature("BAD_APPROVAL_SIG");
            }
        } else if (dev3Space[_node]._core) {
            revert InvalidRequest("BAD_CORE_APPROVER");
        } else if (!isApprovedSigner[_node][_signer]) {
            revert InvalidRequest("BAD_SIGNER");
        }
        address _signedBy = Dev3(this).getSigner(
            string.concat(
                "Requesting Signature To Update ENS Record\n",
                "\nGateway: https://",
                _gateway,
                "\nResolver: eip155:",
                chainID,
                ":",
                address(this).toChecksumAddress(),
                "\nRecord Type: ",
                _recType,
                "\nExtradata: 0x",
                abi.encodePacked(keccak256(_result)).bytesToHexString(),
                "\nSigned By: eip155:",
                chainID,
                ":",
                _signer.toChecksumAddress()
            ),
            _recordSig
        );
        if (_signer != _signedBy) {
            revert InvalidRequest("BAD_SIGNED_RECORD");
        }
        return _result;
    }

    /**
     * @dev Converts a resolver request to a JSON file format
     * @param _request The resolver request
     * @return _recType The record type in JSON file format
     */
    function jsonFile(bytes calldata _request) public view returns (string memory) {
        bytes4 func = bytes4(_request[:4]);
        if (bytes(funcMap[func]).length > 0) {
            return funcMap[func];
        } else if (func == iResolver.text.selector) {
            (, string memory _key) = abi.decode(_request[4:], (bytes32, string));
            return string.concat("text/", _key);
        } else if (func == iOverloadResolver.addr.selector) {
            (, uint256 _coinType) = abi.decode(_request[4:], (bytes32, uint256));
            return string.concat("address/", _coinType.uintToString());
        } else if (func == iResolver.interfaceImplementer.selector) {
            (, bytes4 _interface) = abi.decode(_request[4:], (bytes32, bytes4));
            return string.concat("interface/0x", abi.encodePacked(_interface).bytesToHexString());
        } else if (func == iResolver.ABI.selector) {
            (, uint256 _abi) = abi.decode(_request[4:], (bytes32, uint256));
            return string.concat("abi/", _abi.uintToString());
        } else if (func == iOverloadResolver.dnsRecord.selector) {
            (, bytes memory _name, uint16 resource) = abi.decode(_request[4:], (bytes32, bytes, uint16));
            return string.concat("dns/0x", _name.bytesToHexString(), "/", resource.uintToString());
        } else if (func == iResolver.dnsRecord.selector) {
            (, bytes32 _name, uint16 resource) = abi.decode(_request[4:], (bytes32, bytes32, uint16));
            return string.concat("dns/0x", abi.encodePacked(_name).bytesToHexString(), "/", resource.uintToString());
        }
        revert FeatureNotImplemented(func);
    }

    /**
     * @dev Checks if a signature is valid
     * @param _message - String-formatted message that was signed
     * @param _signature - Compact signature to verify
     * @return _signer - Signer of message
     * @notice - Signature Format:
     * a) 64 bytes - bytes32(r) + bytes32(vs) ~ compact, or
     * b) 65 bytes - bytes32(r) + bytes32(s) + uint8(v) ~ packed, or
     * c) 96 bytes - bytes32(r) + bytes32(s) + uint256(v) ~ longest
     */
    function getSigner(string calldata _message, bytes calldata _signature) external pure returns (address _signer) {
        bytes32 r = bytes32(_signature[:32]);
        bytes32 s;
        uint8 v;
        uint256 len = _signature.length;
        if (len == 64) {
            bytes32 vs = bytes32(_signature[32:]);
            s = vs & bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            v = uint8((uint256(vs) >> 255) + 27);
        } else if (len == 65) {
            s = bytes32(_signature[32:64]);
            v = uint8(bytes1(_signature[64:]));
        } else if (len == 96) {
            s = bytes32(_signature[32:64]);
            v = uint8(uint256(bytes32(_signature[64:])));
        } else {
            revert InvalidSignature("BAD_SIG_LENGTH");
        }
        if (s > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert InvalidSignature("INVALID_S_VALUE");
        }
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", (bytes(_message).length).uintToString(), _message)
        );
        _signer = ecrecover(digest, v, r, s);
        if (_signer == address(0)) {
            revert InvalidSignature("ZERO_ADDR");
        }
    }

    /// @dev Extra functions
    /**
     * @dev Modifier to restrict access to only the owner of the contract
     */
    modifier onlyDev() {
        if (msg.sender != owner) revert InvalidRequest("ONLY_DEV");
        _;
    }

    /**
     * @dev Transfers ownership of the Dev3 contract to a new owner
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) external payable onlyDev {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Adds a core domain to the Dev3 contract
     * @param _node The ENS node of the core domain
     * @param _gateway The gateway associated with the core domain
     * @param _fallback The fallback associated with the core domain
     */
    function setCoreDomain(bytes32 _node, string calldata _gateway, string calldata _fallback)
        external
        payable
        onlyDev
    {
        if (bytes(dev3Space[_node]._gateway).length > 0) {
            revert InvalidRequest("ACTIVE_DOMAIN");
        }
        dev3Space[_node] = Space(true, _gateway, _fallback);
        emit DomainSetup(_node, _gateway, true);
    }

    /**
     * @dev Adds a core domain to the Dev3 contract
     * @param _node The ENS node of the core domain
     * @param _approver The approved signer for the core domain
     * @param _gateway The gateway associated with the core domain
     * @param _fallback The fallback associated with the core domain
     */
    function setCoreDomain(bytes32 _node, address _approver, string calldata _gateway, string calldata _fallback)
        external
        payable
        onlyDev
    {
        if (bytes(dev3Space[_node]._gateway).length > 0) {
            revert InvalidRequest("ACTIVE_DOMAIN");
        }
        dev3Space[_node] = Space(true, _gateway, _fallback);
        isApprovedSigner[_node][_approver] = true;
        emit ApprovedSigner(_node, _approver, true);
        emit DomainSetup(_node, _gateway, true);
    }

    /**
     * @dev Removes a core domain from the Dev3 contract
     * @param _node The ENS node of the core domain
     */
    function removeCoreDomain(bytes32 _node) external payable onlyDev {
        if (!dev3Space[_node]._core) revert InvalidRequest("NOT_CORE_DOMAIN");
        delete dev3Space[_node];
        emit DomainSetup(_node, "", false);
    }

    /**
     * @dev Adds a custom ENS domain to the Dev3 contract
     * @param _node The ENS node of the custom domain
     * @param _gateway The gateway associated with the custom domain
     * @param _fallback The fallback associated with the custom domain
     */
    function updateYourENS(bytes32 _node, string calldata _gateway, string calldata _fallback) external payable {
        address _manager = ENS.owner(_node);
        if (isWrapper[_manager]) {
            _manager = iToken(_manager).ownerOf(uint256(_node));
        }
        if (msg.sender != _manager) revert InvalidRequest("ONLY_MANAGER");
        dev3Space[_node] = Space(false, _gateway, _fallback);
        emit DomainSetup(_node, _gateway, false);
    }

    /**
     * @dev Adds a custom ENS domain with an approved signer to the Dev3 contract
     * @param _node The ENS node of the custom domain
     * @param _signer The approved signer for the custom domain
     * @param _gateway The gateway associated with the custom domain
     * @param _fallback The fallback associated with the custom domain
     */
    function setupYourENS(bytes32 _node, address _signer, string calldata _gateway, string calldata _fallback)
        external
        payable
    {
        address _manager = ENS.owner(_node);
        if (isWrapper[_manager]) {
            _manager = iToken(_manager).ownerOf(uint256(_node));
        }
        if (msg.sender != _manager) revert InvalidRequest("ONLY_MANAGER");
        dev3Space[_node] = Space(false, _gateway, _fallback);
        isApprovedSigner[_node][_signer] = true;
        emit ApprovedSigner(_node, _signer, true);
        emit DomainSetup(_node, _gateway, false);
    }

    /**
     * @dev Sets the approval status of a signer for a specific ENS node
     * @param _node The ENS node of the domain
     * @param _signer The signer address to set approval for
     * @param _set The approval status (true/false)
     */
    function setApprovedSigner(bytes32 _node, address _signer, bool _set) external payable {
        if (bytes(dev3Space[_node]._gateway).length == 0) {
            revert InvalidRequest("NOT_ACTIVE");
        }
        address _manager = ENS.owner(_node);
        if (isWrapper[_manager]) {
            _manager = iToken(_manager).ownerOf(uint256(_node));
        }
        if (msg.sender != _manager) revert InvalidRequest("ONLY_MANAGER");
        isApprovedSigner[_node][_signer] = _set;
        emit ApprovedSigner(_node, _signer, _set);
    }

    /**
     * @dev Sets the core approver for a specific ENS node
     * @param _node The ENS node of the domain
     * @param _approver The approver address to set
     * @param _set The approval status (true/false)
     */
    function setCoreApprover(bytes32 _node, address _approver, bool _set) external payable onlyDev {
        if (!dev3Space[_node]._core) revert InvalidRequest("NOT_CORE_DOMAIN");
        isApprovedSigner[_node][_approver] = _set;
        emit ApprovedSigner(_node, _approver, _set);
    }

    /**
     * @dev Sets the status of a wrapper contract
     * @param _wrapper The address of the wrapper contract
     * @param _set The status to set (true/false)
     */
    function setWrapper(address _wrapper, bool _set) external payable onlyDev {
        isWrapper[_wrapper] = _set;
        emit WrapperUpdate(_wrapper, _set);
    }

    /**
     * @dev Sets the function to JSON filename
     * @param _func bytes4 function selector to map
     * @param _name String mapped to function for JSON filename
     */
    function setFunctionMap(bytes4 _func, string calldata _name) external payable onlyDev {
        funcMap[_func] = _name;
        emit FunctionMapUpdate(_func, _name);
    }

    /**
     * @dev Sets the chain ID for the Dev3 contract
     */
    function setChainID() external {
        chainID = (block.chainid).uintToString();
    }

    /**
     * @dev Withdraws a specified balance of a given token to the owner
     * @param _token The address of the token
     * @param _balance The amount to withdraw
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transfer(owner, _balance);
    }

    /**
     * @dev Withdraws the entire balance of Ether to the owner
     */
    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        emit ThankYou(msg.sender, msg.value);
    }
}
