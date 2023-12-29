// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGreen {
    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
    function totalSupply() external view returns (uint);
    function distributeMinting(address[] memory to, uint256[] memory value) external;

}

contract BridgeMinterTL {
    address public owner;
    address private notary;
    address private approver;
    IGreen public tokenAddress;
    bool private bridging;
    uint256 private chainId;
    bytes32 private domainSeparator;
    address public pendingOwner;
    address public erc20PendingOwner;
    uint public ownershipTransferInitiatedAt;
    uint public erc20OwnershipTransferInitiatedAt;
    uint constant TRANSFER_DELAY = 48 hours;
    bool public notaryApprove;
    bool public approverApprove;

    mapping(bytes32 => bool) private nonces;

    event Bridged(address  receiver, uint256 amount);
    event TransferOwnership(address indexed owner, bool indexed confirmed);

    constructor(address _owner, address _approver, address _notary, address _tokenContractAddress, uint256 _chainId){
        require(_owner != address(0));       // dev: invalid owner
        require(_approver != address(0));     // dev: invalid approver
        require(_notary != address(0));       // dev: invalid notary
        owner = _owner;
        approver = _approver;
        notary = _notary;
        chainId = _chainId;

        tokenAddress = IGreen(_tokenContractAddress);

        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId)"),
                keccak256("Neptune Bridge"), 
                keccak256("0.0.1"), 
                _chainId
            )
        );
    }

    // Function to initiate ownership transfer
    function initiateTransferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != owner, "New owner is already the current owner");
        pendingOwner = _newOwner;
        ownershipTransferInitiatedAt = block.timestamp;
    }

    // Function to finalize ownership transfer after 48 hours
    function finalizeTransferOwnership() public {
        require(msg.sender == pendingOwner, "Only pending owner can finalize ownership transfer");
        require(block.timestamp >= ownershipTransferInitiatedAt + TRANSFER_DELAY, "Must wait 48 hours to confirm transfer.");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Function to initiate token ownership transfer
    function initiateTransferTokenOwnership(address _newOwner) public onlyOwner {
        erc20OwnershipTransferInitiatedAt = block.timestamp;
        erc20PendingOwner = _newOwner;
    }

    // Function to finalize token ownership transfer after 48 hours
    function completeTransferTokenOwnership() public onlyOwner {
        require(block.timestamp >= erc20OwnershipTransferInitiatedAt + TRANSFER_DELAY, "Must wait 48 hours to confirm transfer.");
        tokenAddress.transferOwnership(erc20PendingOwner);
    }

    function acceptTokenOwnership() public {
        tokenAddress.acceptOwnership();
    }
    
    modifier checkNonce(bytes32 nonce) {
        require(nonces[nonce]==false); // dev: already processed
        _;
    }

    function bridge(address sender, uint256 bridgedAmount, bytes32 nonce, bytes32 messageHash, bytes calldata approvedMessage, bytes calldata notarizedMessage)
    external checkNonce(nonce) {
        require(bridging == false, "Re-entrancy guard triggered: bridging already in progress"); // Re-entrancy guard
        bridging = true;

        bytes32 hashToVerify = keccak256(
            abi.encode(keccak256("SignedMessage(bytes32 key,address sender,uint256 amount)"), nonce, sender, bridgedAmount)
        );

        require(checkEncoding(approvedMessage, messageHash, hashToVerify, approver), "Invalid signature from approver"); // Check approver's signature
        require(checkEncoding(notarizedMessage, messageHash, hashToVerify, notary), "Invalid signature from notary"); // Check notary's signature

        nonces[nonce] = true;

        uint256 maxSupply = 5000000000000000000; // 50 billion tokens with 8 decimals precalculated
        uint256 totalSupply = tokenAddress.totalSupply();

        require(totalSupply + bridgedAmount <= maxSupply, "Minting would exceed the maximum supply of 50 billion tokens"); // Check max mint amount

        address[] memory recipients = new address[](1);
        recipients[0] = sender;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = bridgedAmount;

        tokenAddress.distributeMinting(recipients, amounts);

        emit Bridged(sender, bridgedAmount);
        bridging = false;
    }


    function checkEncoding(bytes memory signedMessage,bytes32 messageHash, bytes32 hashToVerify, address signer) 
    internal view returns(bool){

        bytes32 domainSeparatorHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashToVerify));
        require(messageHash == domainSeparatorHash); //dev: values do not match

        return signer == recoverSigner(messageHash, signedMessage);
    }

    function splitSignature(bytes memory sig)
    internal pure returns (uint8 v, bytes32 r, bytes32 s){
        require(sig.length == 65); // dev: signature invalid

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
    internal pure returns (address){
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return tryRecover(message, v, r, s);
    }

    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    internal 
    pure 
    returns (address) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        } else if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return address(0);
        }

        return signer;
    }
}