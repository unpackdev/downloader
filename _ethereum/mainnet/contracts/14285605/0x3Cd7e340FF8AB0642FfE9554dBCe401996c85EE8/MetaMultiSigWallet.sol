// import "./Ownable.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./console.sol";
import "./ECDSA.sol";

contract MetaMultiSigWallet {
    // use ECDSA for bytes 32
    using ECDSA for bytes32;

    // Create an event for successful deposits
    event Deposit(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed balance
    );

    // Create an event for successful transaction execution via multisig.
    event ExecuteTransaction(
        address indexed owner,
        address payable to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );

    // Create an event to record owner change.
    event Owner(address indexed owner, bool added);

    // state variable (hint mapping) to check if an address is a owner
    mapping(address => bool) public isOwner;
    // Keep track of owners address
    address[] public owners;

    //keep track of active owners
    uint256 public numberOfOwners;

    // state variable to store # of signature required.
    uint256 public signaturesRequired;

    // state variable to keep track of the number of transaction executed by this contract
    // aka nonce
    uint256 public nonce;

    // state variable to keep track of the chainId .
    uint256 public chainId;

    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) {
        // Check following .
        // non zero number of confirmation required
        require(_signaturesRequired > 0, "constructor: non zero sig required");
        signaturesRequired = _signaturesRequired;
        // valid owner addresses rquired.
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "zero address can't be owner");
            require(isOwner[owner] != true, "Duplicate owners in list ");
            isOwner[owner] = true;
            owners.push(owner);
            numberOfOwners++;
            emit Owner(owner, isOwner[owner]);
        }
        chainId = _chainId;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Not self");
        _;
    }

    modifier minimumOwners() {
        require(numberOfOwners > 1, "Atleast one owner is required");
        _;
    }

    function addSigner(address newSigner, uint256 newSignaturesRequired)
        public
        onlySelf
    {
        // Check below when adding a new signer.
        // new owner can't be zero address. i.e address(0)
        require(newSigner != address(0), "zero address");
        require(newSignaturesRequired > 0, "Non zero signature required");
        require(isOwner[newSigner] != true, "Owner exsists");
        isOwner[newSigner] = true;
        owners.push(newSigner);
        numberOfOwners++;
        signaturesRequired = newSignaturesRequired;

        emit Owner(newSigner, isOwner[newSigner]);
    }

    function removeSigner(address oldSigner, uint256 newSignaturesRequired)
        public
        onlySelf
        minimumOwners
    {
        require(isOwner[oldSigner] == true, "Owner doesn't exist");
        require(newSignaturesRequired > 0, "Non zero sig required");
        signaturesRequired = newSignaturesRequired;
        isOwner[oldSigner] = false;
        numberOfOwners--;
        emit Owner(oldSigner, isOwner[oldSigner]);
    }

    function updateSignaturesRequired(uint256 newSignaturesRequired)
        public
        onlySelf
    {
        require(newSignaturesRequired > 0, "Non zero signature required");
        signaturesRequired = newSignaturesRequired;
    }

    function getTransactionHash(
        uint256 _nonce,
        address to,
        uint256 value,
        bytes memory data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    to,
                    value,
                    data
                )
            );
    }

    function executeTransaction(
        address payable to,
        uint256 value,
        bytes memory data,
        bytes[] memory signatures
    ) public returns (bytes memory) {
        // only owners can execute transaction
        require(isOwner[msg.sender] == true, "Sender is not owner");
        bytes32 _hash = getTransactionHash(nonce, to, value, data);
        nonce++;
        uint256 validSignatures;
        address duplicateGuard;

        for (uint256 i; i < signatures.length; i++) {
            address recoveredAddress = recover(_hash, signatures[i]);
            require(
                recoveredAddress > duplicateGuard,
                "executeTransaction: duplicate or unordered signatures"
            );
            console.log(recoveredAddress);
            duplicateGuard = recoveredAddress;
            if (isOwner[recoveredAddress] == true) {
                validSignatures++;
            }
        }
        console.log("validSignatures", validSignatures);

        require(
            validSignatures >= signaturesRequired,
            " not enough valid signatures"
        );

        console.log("to", to);
        console.log("value", value);

        // execute transaction
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "executeTransaction: tx failed");

        // emit execute transaction event

        emit ExecuteTransaction(
            msg.sender,
            to,
            value,
            data,
            nonce - 1,
            _hash,
            result
        );
        return result;
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        // recover address from signed message _hash and signature
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    function ownersArrayLength() public view returns (uint256) {
        return owners.length;
    }

    receive() external payable {
        //emit event for successful deposits
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
