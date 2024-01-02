// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

abstract contract VerifySignature {
    bytes32 public immutable DOMAIN_SEPARATOR;

    struct Request {
        address token;
        uint256 amount;
        address recipient;
        uint256 deadline;
        uint256 nonce;
    }

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256(bytes("VerifySignature")), block.chainid, address(this)));
    }

    function getMessageHash(Request calldata request) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(request.token, request.amount, request.recipient, request.deadline, request.nonce)
        );
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", DOMAIN_SEPARATOR, _messageHash));
    }

    function verify(Request calldata request, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
        bytes32 messageHash = getMessageHash(request);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external;
}

contract Pool is Owned, VerifySignature {
    event Withdraw(address indexed token, address indexed recipient, uint256 amount, uint256 timestamp);

    mapping(address => Request[]) public records;
    mapping(address => uint256) public userNonce;

    address public signer;

    constructor() Owned(msg.sender) {
        signer = msg.sender;
    }

    function withdraw(Request calldata request, uint8 v, bytes32 r, bytes32 s) external {
        address recipient = request.recipient;
        require(request.deadline > block.timestamp, "deadline");
        require(request.nonce > userNonce[recipient], "nonce");
        require(verify(request, v, r, s) == signer, "not match");

        records[recipient].push(request);
        userNonce[recipient] = request.nonce;

        IERC20(request.token).transfer(recipient, request.amount);
        emit Withdraw(request.token, recipient, request.amount, block.timestamp);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function requestCount(address account) external view returns (uint256) {
        return records[account].length;
    }

    function requestByAccount(address account) external view returns (Request[] memory) {
        return records[account];
    }

    function withdrawToken(IERC20 token, uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }
}