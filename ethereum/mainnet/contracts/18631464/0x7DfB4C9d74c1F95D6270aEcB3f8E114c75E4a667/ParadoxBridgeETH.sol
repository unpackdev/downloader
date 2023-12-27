// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./Paradox.sol";

contract ParadoxBridgeETH is Ownable {
    using ECDSA for bytes32;

    Paradox public paradox;
    address public bridgeSigner;
    address private bridgeFeeWalet;
    bool public bridgeOpen;
    uint256 public bridgeFee;

    // This Will be created each time a transaction happens
    struct BridgeTransaction {
        uint256 chainA;
        uint256 chainB;
        address sender;
        uint256 amount;
        uint256 nonce;
        bytes32 messageHash;
        uint256 blockNumber;
    }
    //Keep track of each addresses transactions, increase nonce every time
    mapping(address => uint256) public nonce;
    // Allows to save and retrieve the struct
    mapping(address => mapping(uint256 => BridgeTransaction))
        private bridgeTransactions;
    // Manages Allowed Chains
    mapping(uint256 => bool) public allowedChain;

    // Invalidates signatures when users claim
    mapping(address => mapping(bytes => bool)) public signaturesUsed;

    // This event will be caught by backend, which will then be signed by BridgeSigner
    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 originChain,
        uint256 destinationChain,
        bytes32 indexed messageHash,
        uint256 nonce,
        uint256 indexed block
    );
    event Claimed(address indexed receiver, uint256 amount);

    modifier onlyWhenBridgeIsOpen() {
        require(bridgeOpen, "Bridge is not open");
        _;
    }

    constructor(address _paradox, address _feeWallet) {
        paradox = Paradox(_paradox);
        bridgeSigner = 0xCfF393258a4838D87f98b0c14Da064Dc86402E71;
        bridgeFee = 5;
        bridgeFeeWalet = _feeWallet;
        allowedChain[56] = true;
    }

    function deposit(
        uint256 _amount,
        uint256 _destinationChain
    ) external onlyWhenBridgeIsOpen returns (bytes32) {
        require(_amount > 0, "Bridging amount cannot be 0");
        require(_destinationChain != 1, "Cannot bridge to origin chain");
        require(
            allowedChain[_destinationChain],
            "Destination chain not supported yet"
        );
        // Require user to lock their tokens
        require(paradox.transferFrom(msg.sender, address(this), _amount));

        uint256 fee = (_amount * bridgeFee) / 1000;
        require(paradox.transfer(bridgeFeeWalet, fee));
        _amount = _amount - fee;

        nonce[msg.sender]++;

        bytes32 messageHash = getMessageHash(
            msg.sender,
            1,
            _destinationChain,
            _amount,
            nonce[msg.sender]
        );

        bridgeTransactions[msg.sender][nonce[msg.sender]] = BridgeTransaction(
            1,
            _destinationChain,
            msg.sender,
            _amount,
            nonce[msg.sender],
            messageHash,
            block.number
        );

        emit Deposit(
            msg.sender,
            _amount,
            1,
            _destinationChain,
            messageHash,
            nonce[msg.sender],
            block.number
        );

        return messageHash;
    }

    function claim(
        address _sender,
        uint256 _originChain,
        uint256 _destinationChain,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external onlyWhenBridgeIsOpen {
        // Must be from the opposite chain
        require(_originChain != 1, "Signature is for incorrect network");
        // Check that the signature hasnt been invalidated
        require(
            !signaturesUsed[msg.sender][_signature],
            "Signature already used!"
        );
        // Recover signer
        require(
            verify(
                _sender,
                _originChain,
                _destinationChain,
                _amount,
                _nonce,
                _signature
            )
        );
        // Invalidate signature
        signaturesUsed[msg.sender][_signature] = true;

        // Finally release tokens to user
        require(paradox.transfer(_sender, _amount));

        emit Claimed(msg.sender, _amount);
    }

    function updateBridgeSigner(address _newSigner) external onlyOwner {
        require(_newSigner != address(0));
        bridgeSigner = _newSigner;
    }

    function updateFeeWallet(address _newFeeWallet) external onlyOwner {
        bridgeFeeWalet = _newFeeWallet;
    }

    function manageBridge() external onlyOwner {
        bridgeOpen = !bridgeOpen;
    }

    function updateBridgeFee(uint256 _newFee) external onlyOwner {
        require(_newFee < 10, "Fee cannot be more than 1%");
        bridgeFee = _newFee;
    }

    function manageChains(uint256 _chain, bool _allowed) external onlyOwner {
        allowedChain[_chain] = _allowed;
    }

    function getMessageHash(
        address _sender,
        uint256 _originChain,
        uint256 _destinationChain,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _sender,
                    _originChain,
                    _destinationChain,
                    _amount,
                    _nonce
                )
            );
    }

    function verify(
        address _sender,
        uint256 _originChain,
        uint256 _destinationChain,
        uint256 _amount,
        uint256 _nonce,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _sender,
            _originChain,
            _destinationChain,
            _amount,
            _nonce
        );

        return
            messageHash.toEthSignedMessageHash().recover(signature) ==
            bridgeSigner;
    }

    function returnBridgeTransaction(
        address _user,
        uint256 _nonce
    ) public view returns (BridgeTransaction memory) {
        return bridgeTransactions[_user][_nonce];
    }
}
