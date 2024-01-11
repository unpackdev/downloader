// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SignatureUtils.sol";
import "./Structs.sol";
import "./IERC20.sol";
import "./IProxy.sol";

contract Upgradeable is ReentrancyGuard {
    address public immutable proxy;
    address public signer;
    mapping(address => bool) public isApprovedToken;
    mapping(bytes => bool) public isExecutedTransaction;
    mapping(address => bool) blacklist;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier onlyOwner() {
        require(
            msg.sender == IProxy(proxy).proxyOwner(),
            "Diamond Alpha Bridge: Only owner"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !blacklist[msg.sender],
            "Diamond Alpha Bridge: This address is blacklisted"
        );
        _;
    }

    event MintOrBurnEvent(
        string internalTxId,
        address indexed toAddress,
        address indexed fromAddress,
        address indexed fromToken,
        address toToken,
        uint256 amount,
        uint8 eventType
    );

    event SetSignerEvent(address indexed newSigner);
}
