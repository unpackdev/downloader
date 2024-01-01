// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// Interface for BEP20 tokens, which is a standard interface for tokens on the Binance Smart Chain.
interface IBEP20 {
    // Standard BEP20 functions
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Library to check if an address is a contract
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// Ownable contract to restrict certain functions to the owner
contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Owner can not be 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Contract to handle signature verification
contract VerifySignature {
    // Generate a hash of the message
    function getMessageHash(
        address _to,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce));
    }

    // Generate Ethereum signed message hash
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    // Verify the signature
    function verify(
        address _signer,
        address _to,
        uint _amount,
        uint _nonce,
        bytes memory signature

    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    // Recover the signer address from the signature
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // Split the signature into r, s, and v
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}



// Main TokenMigration contract
contract TokenMigration is Ownable, VerifySignature {
    using Address for address;

    mapping(address => bool) isValidSigner; 
    // Mapping to keep track of nonces for each address
    mapping(address => uint256) public nonces;
    mapping(address => uint256) public claimedAmounts;


    // Address of the token to be distributed
    address public tokenAddress;

    // Event to log successful claims
    event TokensClaimed(address indexed claimer, uint256 amount);

    // Constructor to set the initial token address
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Function to claim tokens
    function claimTokens(
        address _signer,
        address _claimer,
        uint256 _amount,
        uint256 _nonce,
        bytes memory signature
    ) public {
        // Verify the nonce to prevent replay attacks
        require(isValidSigner[_signer], "Invalid signer");

        require(nonces[_claimer] <= _nonce, "Invalid nonce");

        // Verify the signature
        require(
            verify(_signer, _claimer, _amount, _nonce, signature),
            "Invalid signature"
        );

        // Increment the nonce for the claimer
        nonces[_claimer]++;

        // Transfer the tokens to the claimer
        require(
            IBEP20(tokenAddress).transfer(_claimer, _amount),
            "Token transfer failed"
        );

        // Update the claimed amount for the claimer
        claimedAmounts[_claimer] += _amount;

        // Emit the TokensClaimed event
        emit TokensClaimed(_claimer, _amount);
    }

    function getTotalClaimed(address _claimer) public view returns (uint256) {
        return claimedAmounts[_claimer];
    }


    // Function to update the token address, only callable by the owner
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setSigner (address _signer, bool _flag) public onlyOwner {
        isValidSigner[_signer] = _flag;
    }
}