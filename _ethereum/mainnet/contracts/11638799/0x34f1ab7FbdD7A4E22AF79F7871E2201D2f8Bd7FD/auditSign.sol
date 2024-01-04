// SPDX-License-Identifier: MIT
//
//   _             _                           _          _          _
//  | |__   _   _ | |_  ___  _ __  ___    ___ | | __ ___ | |_     __| |  ___ __   __
//  | '_ \ | | | || __|/ _ \| '__|/ _ \  / __|| |/ // _ \| __|   / _` | / _ \\ \ / /
//  | |_) || |_| || |_|  __/| |  | (_) || (__ |   <|  __/| |_  _| (_| ||  __/ \ V /
//  |_.__/  \__, | \__|\___||_|   \___/  \___||_|\_\\___| \__|(_)\__,_| \___|  \_/
//          |___/
//
// AuditSign contracts are storing the signatures of audit reports, developed by
// byterocket.dev. The IPFS hash is stored on-chain and signed by both parties,
// the auditors (us) and the client. This way, third parties and users may
// verify for themselves, that an audit report is legitimate.

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./ECDSAUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract auditSign is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // Stores the actual signature together with the signers address,
    // name and the signing date
    struct Signature {
        string name;
        address signer;
        bytes signature;
        uint256 date;
    }

    // Stores the audit report
    struct Audit {
        string name;
        string ipfsHash;
        uint256 date;
    }

    // Mirroring Contracts on other networks
    // ChainID => Address
    mapping(uint256 => address) public mirrorContracts;

    // IPFS Base URL
    string public ipfsBase;

    // Audit Reports
    Audit[] public audits;
    // IPFSHash => Index
    mapping(string => uint256) public indexOfAudit;
    // IPFSHash => true/false
    mapping(string => bool) internal auditExists;

    // Signatures
    // IPFSHash => Signatures
    mapping(string => Signature[]) public signatures;
    // IPFSHash => SignerAddress => true/false
    mapping(string => mapping(address => bool)) internal hasSignedAuditReport;

    // Allowed addresses to submit signatures (currently just our backend node,
    // since we are paying for the signing process)
    mapping(address => bool) internal hasSigningRights;

    // Events
    event NewAudit(string indexed ipfsHash, string auditName);
    event NewSignature(
        string indexed ipfsHash,
        address indexed signer,
        string signerName,
        bytes signature
    );

    function initialize(string memory _baseUrl, address _adminAddress, address _signerAddress)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        hasSigningRights[_signerAddress] = true;
        transferOwnership(_adminAddress);
        ipfsBase = _baseUrl;
    }

    // Change the signing rights of an address
    function modifySigningRights(address _address, bool _access)
        external
        onlyOwner
    {
        hasSigningRights[_address] = _access;
    }

    // Change the IPFS base url
    function modifyBaseUrl(string memory _baseUrl) external onlyOwner {
        ipfsBase = _baseUrl;
    }

    // Add or change a record for a mirroring contract
    function changeMirrorContract(uint256 _chainID, address _mirrorContract)
        external
        onlyOwner
    {
        mirrorContracts[_chainID] = _mirrorContract;
    }

    // Only allows authorized addresses to submit a new signature
    modifier onlySigner() {
        require(hasSigningRights[msg.sender], "AUDITSIGN/NOT-AUTHORIZED");
        _;
    }

    // createAudit will create a new audit object which can be signed from now on
    function createAudit(string memory _name, string memory _ipfsHash)
        public
        onlySigner
    {
        require(!auditExists[_ipfsHash], "AUDITSIGN/AUDIT-ALREADY-EXISTS");

        auditExists[_ipfsHash] = true;
        indexOfAudit[_ipfsHash] = audits.length;
        Audit memory newAudit = Audit(_name, _ipfsHash, now);
        audits.push(newAudit);

        emit NewAudit(_ipfsHash, _name);
    }

    // signAudit allows people to attach a signatures to an NFT token
    // They have to be either whitelisted (if the token works with a whitelist)
    // or everyone can sign if it's not a token using a whitelist
    function signAudit(
        string memory _ipfsHash,
        string memory _name,
        address _signer,
        bytes memory _signature
    ) public onlySigner {
        require(auditExists[_ipfsHash], "AUDITSIGN/AUDIT-DOESNT-EXIST");

        // Message that was signed conforms to this structure:
        // This Audit Report (IPFSHash: Q0123012301012301230101230123010123012301)
        // by byterocket was signed by Name
        //(Address: 0x5123012301012301230101230123010123012301)!
        string memory signedMessage =
            string(
                abi.encodePacked(
                    "This Audit Report (IPFS-Hash: ",
                    _ipfsHash,
                    ") by byterocket was signed by ",
                    _name,
                    " (Address: ",
                    addressToString(_signer),
                    ")!"
                )
            );

        // Recreating the messagehash that was signed
        // Sidenote: I am aware that bytes(str).length isn't perfect, but
        // as the strings can only contain A-Z, a-z and 0-9 characters,
        // it's always 1 byte = 1 characater, so it's fine in this case
        // - and the most efficient
        bytes32 messageHash =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    uintToString(bytes(signedMessage).length),
                    signedMessage
                )
            );

        // Checking whether the signer matches the signature (signature is correct)
        address signer = messageHash.recover(_signature);
        require(signer == _signer, "AUDITSIGN/WRONG-SIGNATURE");

        // Users can only sign a report once
        require(
            !hasSignedAuditReport[_ipfsHash][signer],
            "AUDITSIGN/ALREADY-SIGNED"
        );

        // Store the signer and the signature
        Signature memory newSignature =
            Signature(_name, signer, _signature, now);
        signatures[_ipfsHash].push(newSignature);
        hasSignedAuditReport[_ipfsHash][signer] = true;

        emit NewSignature(_ipfsHash, signer, _name, _signature);
    }

    // signMultipleAudits just calls signAudit based on the input to save some gas
    function signMultipleAudits(
        string memory _ipfsHash,
        string[] memory _names,
        address[] memory _signers,
        bytes[] memory _signatures
    ) public {
        uint256 amount = _names.length;
        require(
            _signers.length == amount && _signatures.length == amount,
            "AUDITSIGN/LENGTHS-DONT-MATCH"
        );

        for (uint256 i = 0; i < amount; i++) {
            signAudit(_ipfsHash, _names[i], _signers[i], _signatures[i]);
        }
    }

    // createAndSignAudit combined the functions of createAudit and multiple signAudits to save gas
    function createAndSignAudit(
        string memory _auditName,
        string memory _ipfsHash,
        string[] memory _signerNames,
        address[] memory _signers,
        bytes[] memory _signatures
    ) external {
        createAudit(_auditName, _ipfsHash);
        signMultipleAudits(_ipfsHash, _signerNames, _signers, _signatures);
    }

    // getSignatures returns all signers of an audit report with their name and signature
    function getSignatures(string memory _ipfsHash)
        external
        view
        returns (
            string[] memory namesOfSigners,
            address[] memory addressesOfSigners,
            bytes[] memory allSignatures
        )
    {
        namesOfSigners = new string[](signatures[_ipfsHash].length);
        addressesOfSigners = new address[](signatures[_ipfsHash].length);
        allSignatures = new bytes[](signatures[_ipfsHash].length);

        for (uint256 i = 0; i < signatures[_ipfsHash].length; i++) {
            namesOfSigners[i] = signatures[_ipfsHash][i].name;
            addressesOfSigners[i] = signatures[_ipfsHash][i].signer;
            allSignatures[i] = signatures[_ipfsHash][i].signature;
        }

        return (namesOfSigners, addressesOfSigners, allSignatures);
    }

    // From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function uintToString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    // From https://ethereum.stackexchange.com/questions/70300/how-to-convert-an-ethereum-address-to-an-ascii-string-in-solidity
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
