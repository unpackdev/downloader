// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Errors.sol";
import "./ITiki.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";

contract ParrotMint is OwnableUpgradeable {

    address public txnSigner;
    bool public paused;

    struct contractState {
        address txnSigner;
        bool paused;
    }

    contractState public settings;

    int constant TX_TYPE_MINT = 0;
    int constant TX_TYPE_REVEAL = 1;

    event MintPassesCreated(bytes32 indexed nonce, address indexed operator, uint256[] tokenIDs);
    event Revealed(bytes32 indexed nonce, address indexed operator, uint256[] tokenIDs);

    modifier whileUnpaused() {
        if (settings.paused) {
            revert Errors.Paused();
        }
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setup(address signer) onlyOwner public {
        settings = contractState(
            signer,
            false
        );
    }

    function pause(bool _pause) external {
        settings.paused = _pause;
    }

    function deposit() public payable {}

    function withdraw() onlyOwner external {
        address payable recipient = payable(_msgSender());
        uint256 amount = address(this).balance;
        (bool success, ) = recipient.call{ value: amount }("");
        if ( ! success) {
            revert Errors.PaymentFailed(amount);
        }
    }

    function create(uint256[] memory tokenIDs, bytes32 nonce, bytes memory signature) whileUnpaused external payable {
        verifyTransaction(TX_TYPE_MINT, tokenIDs, nonce, signature);
        emit MintPassesCreated(nonce, _msgSender(), tokenIDs);
    }

    function reveal(uint256[] memory tokenIDs, bytes32 nonce, bytes memory signature) whileUnpaused external payable {
        verifyTransaction(TX_TYPE_REVEAL, tokenIDs, nonce, signature);
        emit Revealed(nonce, _msgSender(), tokenIDs);
    }

    function verifyTransaction(int txType, uint256[] memory tokenIDs, bytes32 nonce, bytes memory signature) internal {
        if ( ! verifySignature(signature, getHash(getDigest(txType, _msgSender(), tokenIDs, msg.value, nonce)))) {
            revert Errors.InvalidSignature();
        }
    }

    function verifySignature(bytes memory signature, bytes32 digestHash) public view returns(bool) {
        return settings.txnSigner == getSigner(signature, digestHash);
    }

    function getSigner(bytes memory signature, bytes32 digestHash) public pure returns(address) {
        bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(digestHash);
        return ECDSA.recover(ethSignedHash, signature);
    }

    function getHash(bytes memory digest) public pure returns (bytes32 hash) {
        return keccak256(digest);
    }

    function getDigest(int txType, address wallet, uint256[] memory tokenIDs, uint256 cost, bytes32 nonce) public pure returns (bytes memory) {
        return abi.encodePacked(
            txType,
            wallet,
            keccak256(abi.encodePacked(tokenIDs)),
            cost,
            nonce
        );
    }
}
