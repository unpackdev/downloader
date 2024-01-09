// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Errors.sol";
import "./ITiki.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";

contract TikiCarving is OwnableUpgradeable {

    address public txnSigner;
    bool public paused;

    struct contractState {
        address txnSigner;
        bool paused;
    }

    contractState public settings;

    event TokenUpgraded(uint indexed tokenID, uint indexed level, bytes32 indexed nonce);
    event TokenSacrificed(uint indexed tokenID, bytes32 indexed nonce);
    event UpgradeCompleted(bytes32 indexed nonce, address indexed operator, uint256[] tokenIDs, uint256 level);

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

    function upgrade(uint256[] memory upgradeIDs, uint256[] memory sacrificeIDs, uint256 level, uint256 method, uint256 cost, bytes32 nonce, bytes memory signature) whileUnpaused external payable {
        address operator = _msgSender();
        if ( msg.value != cost) revert Errors.InsufficientBalance(msg.value, cost);
        if ( ! verifySignature(signature, getHash(getDigest(_msgSender(), upgradeIDs, sacrificeIDs, level, method, cost, nonce)))) {
            revert Errors.InvalidSignature();
        }

        for (uint i; i < upgradeIDs.length; i++) {
            emit TokenUpgraded(upgradeIDs[ i ], level, nonce);
        }

        for (uint i; i < sacrificeIDs.length; i++) {
            emit TokenSacrificed(sacrificeIDs[ i ], nonce);
        }

        emit UpgradeCompleted(nonce, operator, upgradeIDs, level);
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

    function getDigest(address wallet, uint256[] memory upgradeIDs, uint256[] memory sacrificeIDs, uint256 level, uint256 method, uint256 cost, bytes32 nonce) public pure returns (bytes memory) {
        return abi.encodePacked(
            wallet,
            getHash(abi.encodePacked(upgradeIDs)),
            getHash(abi.encodePacked(sacrificeIDs)),
            level,
            method,
            cost,
            nonce
        );
    }
}
