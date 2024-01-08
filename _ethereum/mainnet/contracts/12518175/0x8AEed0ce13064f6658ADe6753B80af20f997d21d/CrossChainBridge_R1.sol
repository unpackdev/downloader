// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMathUpgradeable.sol";
import "./SignedSafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./MintableToken.sol";

//
// If you have any questions related to this smart-contract
// implementation, feel free to reach me using email or telegram.
//
// @author Dmitry Savonin <dmitry@ankr.com>
//
contract CrossChainBridge_R1 is PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    event CrossChainDeposit(
        uint256 bridgeIndex, // index of bridge in this contract
        address fromToken, // source and target contracts (from -> to)
        address toToken,
        uint256 fromChain, // source and target chains (from -> to)
        uint256 toChain,
        address fromAddress, // sender and recipient addresses
        address toAddress,
        uint256 depositAmount // total burned or locked amount
    );
    event CrossChainWithdraw(
        uint256 bridgeIndex, // index of bridge in this contract
        address fromToken, // source and target contracts (from -> to)
        address toToken,
        uint256 fromChain, // source and target chains (from -> to)
        uint256 toChain,
        address fromAddress, // sender and recipient addresses
        address toAddress,
        uint256 withdrawAmount, // total burned or locked amount
        bytes32 depositTxHash // hash of the corresponding deposit transaction
    );

    event BridgeRegistered(uint256 index);
    event BridgeEnabled(uint256 index);
    event BridgeDisabled(uint256 index);

    enum BridgeStatus {
        Disabled,
        Enabled
    }

    enum BridgeType {
        Mintable,
        Lockable
    }

    //
    // Token indicates availability to do the swap, here
    // must understand next things:
    //  1. This contract exists in both networks and token must
    //     be registered in both of them but with opposite source/dest
    //  2. If you disable token in source blockchain then you
    //     also have to disable it in dest
    //  3. Our backend is stateless that means that it doesn't
    //     have its database and it can only check transaction validity
    //
    // We support next token types:
    //  1. Mintable - is the token which exists in both networks at
    //     the same time, in other words they exists independently to each
    //     other. When user lock funds in this contract we just burn them
    //     and mint in opposite network. The main problem of such tokens that
    //     contract should be able to do mint/burn operations. The only
    //     possibility to check the consistency of funds is to calc sum of
    //     locked balances in all blockchains and it should be zero.
    //  2. Lockable - is the token which exists only in one network and we want
    //     to created pegged token in another blockchain. It has a bit different
    //     scheme because we don't need to burn tokens, we can just lock them
    //     in source smart contract and mint in destination. If we want to get funds
    //     back we just burn them in destination and transfer in source blockchain.
    //     This scheme is useful for tokens that are already provided in ETH network
    //     and users want to use it in other blockchains.
    //
    // Here is the flow for lockable token:
    //  1. User locks his funds in smart contract and calculates proof
    //  2. He sends proof to oracle, it verified it and if everything is fine
    //     it also returns signature for minting funds in dest blockchain
    //  3. User switch his network and claims his funds from dest blockchain
    //  4. Profit
    //
    // What is proof? Proof is a special array that contains information about transaction
    // and can be verified by smart contract. Here we have one problem that destination blockchain
    // can't verify transaction and we use oracles to solve it. Oracle verifies transaction
    // and if transaction is fine it signs it using its own private key. Now user by using his
    // signed proof can claim funds.
    //
    // P.S: we don't support ERC20/BEP20 tokens that charges fee
    //
    struct Bridge {
        // type of token
        BridgeStatus bridgeStatus;
        BridgeType bridgeType;
        // source and destination addresses (in ETH and BSC networks)
        IERC20Mintable fromToken;
        IERC20Mintable toToken;
        // source and destination chains
        uint256 fromChain;
        uint256 toChain;
    }

    //
    // Locked indicates how many tokens was minted
    // or burned in different networks. Since this contract
    // is deployed in both networks, for example,
    // in ETH and in BSC then locked amounts should have
    // opposite values.
    //
    address private _operator;
    mapping(IERC20Mintable => int256) _minted;
    mapping(IERC20Mintable => int256) _locked;
    mapping(bytes32 => bool) _proofs;
    Bridge[] private _bridges;
    mapping(bytes32 => uint256) private _bridgesIndex;

    function initialize(address operator) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __CrossChainBridge_init(operator);
    }

    function __CrossChainBridge_init(address operator) internal {
        // operator signs withdraw messages, we can replace it with multi-sig later
        _operator = operator;
        // we need special dummy bridge to skip 0 position in array
        Bridge memory bridge = Bridge({
        bridgeStatus : BridgeStatus.Disabled, // don't allow to use this bridge
        bridgeType : BridgeType.Lockable, // bridge type doesn't matter
        fromToken : IERC20Mintable(0), // zero tokens which are not exist
        toToken : IERC20Mintable(0),
        fromChain : 0x00, // zero chains which are not exist too
        toChain : 0x00
        });
        _bridges.push(bridge);
    }

    function getAllBridges() public view returns (Bridge[] memory) {
        return _bridges;
    }

    function getBridgeBySourceAndTarget(IERC20Mintable fromToken, IERC20Mintable toToken, uint256 fromChain, uint256 toChain) public view returns (Bridge memory, uint256) {
        return _resolveBridgeBySourceAndTarget(fromToken, toToken, fromChain, toChain);
    }

    function getBridgeByIndex(uint256 index) public view returns (Bridge memory) {
        require(index > 0 && index < _bridges.length, "CrossChainBridge: bridge not found");
        Bridge memory bridge = _bridges[index];
        return bridge;
    }

    function registerBridge(BridgeType bridgeType, IERC20Mintable fromToken, IERC20Mintable toToken, uint256 toChain) public onlyOwner {
        uint256 fromChain = _currentChain();
        // avoid self swap registration
        require(fromToken != toToken, "CrossChainBridge: from/to tokens can't be the same");
        require(fromChain != toChain, "CrossChainBridge: from/to chains can't be the same");
        // calc bridge key and ensure same bridge doesn't exit
        bytes32 bridgeKey = getBridgeKey(fromToken, toToken, fromChain, toChain);
        require(_bridgesIndex[bridgeKey] == 0, "CrossChainBridge: this token is already registered");
        // push new bridge in array with bridges and index it by bridge key
        uint256 newIndex = _bridges.length;
        Bridge memory bridge = Bridge({
        bridgeStatus : BridgeStatus.Enabled,
        bridgeType : bridgeType,
        fromToken : fromToken,
        toToken : toToken,
        fromChain : fromChain,
        toChain : toChain
        });
        _bridgesIndex[bridgeKey] = newIndex;
        _bridges.push(bridge);
        // emit events
        emit BridgeRegistered(newIndex);
        emit BridgeEnabled(newIndex);
    }

    function changeBridgeStatus(bytes32 key, BridgeStatus newStatus) public onlyOwner {
        // find bridge by key and check it's status
        uint256 index = _bridgesIndex[key];
        require(index > 0 && index < _bridges.length, "CrossChainBridge: bridge not found");
        Bridge memory bridge = _bridges[index];
        require(bridge.bridgeStatus != newStatus, "CrossChainBridge: status is the same");
        // emit new event if its necessary
        if (newStatus == BridgeStatus.Enabled) {
            emit BridgeEnabled(index);
        } else if (newStatus == BridgeStatus.Disabled) {
            emit BridgeDisabled(index);
        }
        // save changes
        bridge.bridgeStatus = newStatus;
        _bridges[index] = bridge;
    }

    function getBridgeKey(IERC20Mintable fromToken, IERC20Mintable toToken, uint256 fromChain, uint256 toChain) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(address(fromToken), address(toToken), address(fromChain), address(toChain)));
    }

    function _resolveBridgeBySourceAndTarget(IERC20Mintable fromToken, IERC20Mintable toToken, uint256 fromChain, uint256 toChain) internal view returns (Bridge memory, uint256) {
        bytes32 bridgeKey = getBridgeKey(fromToken, toToken, fromChain, toChain);
        uint256 index = _bridgesIndex[bridgeKey];
        require(index > 0 && index < _bridges.length, "CrossChainBridge: bridge not found");
        Bridge memory bridge = _bridges[index];
        require(bridge.fromToken == fromToken && bridge.toToken == toToken, "CrossChainBridge: tokens mismatched");
        require(bridge.fromChain == fromChain && bridge.toChain == toChain, "CrossChainBridge: chains mismatched");
        return (bridge, index);
    }

    function deposit(IERC20Mintable fromToken, IERC20Mintable toToken, uint256 toChain, address toAddress, uint256 depositAmount) public nonReentrant {
        address fromAddress = address(msg.sender);
        uint256 fromChain = _currentChain();
        // resolve bridge and check its enabled
        (Bridge memory bridge, uint256 index) = _resolveBridgeBySourceAndTarget(fromToken, toToken, fromChain, toChain);
        require(bridge.bridgeStatus == BridgeStatus.Enabled, "CrossChainBridge: bridge is not enabled");
        // do deposit based on type
        if (bridge.bridgeType == BridgeType.Mintable) {
            _depositMintable(bridge, fromAddress, depositAmount);
        } else if (bridge.bridgeType == BridgeType.Lockable) {
            _depositLockable(bridge, fromAddress, depositAmount);
        } else {
            revert("CrossChainBridge: incorrect bridge type");
        }
        // emit event amount deposit
        emit CrossChainDeposit({
        bridgeIndex : index,
        fromToken : address(fromToken),
        toToken : address(toToken),
        fromChain : bridge.fromChain,
        toChain : bridge.toChain,
        fromAddress : fromAddress,
        toAddress : toAddress,
        depositAmount : depositAmount
        });
    }

    function _depositLockable(Bridge memory bridge, address fromAddress, uint256 amount) internal {
        // lock sender tokens to mint them in another blockchain
        uint256 balanceBefore = IERC20Mintable(bridge.fromToken).balanceOf(fromAddress);
        require(amount <= balanceBefore, "CrossChainBridge: insufficient balance");
        uint256 allowance = IERC20Mintable(bridge.fromToken).allowance(fromAddress, address(this));
        require(amount <= allowance, "CrossChainBridge: insufficient allowance");
        require(IERC20Mintable(bridge.fromToken).transferFrom(fromAddress, address(this), amount), "CrossChainBridge: can't transfer tokens");
        // remember how many tokens we locked
        _locked[bridge.fromToken] = _locked[bridge.fromToken].add(int256(amount));
    }

    function _depositMintable(Bridge memory bridge, address fromAddress, uint256 amount) internal {
        // burn sender tokens to mint them in another blockchain
        uint256 balanceOf = IERC20Mintable(bridge.fromToken).balanceOf(fromAddress);
        require(amount <= balanceOf, "CrossChainBridge: insufficient balance");
        IERC20Mintable(bridge.fromToken).burn(fromAddress, amount);
        // remember how many tokens was burned
        _minted[bridge.fromToken] = _minted[bridge.fromToken].sub(int256(amount));
    }

    function checkSignature(
        IERC20Mintable fromToken,
        IERC20Mintable toToken,
        uint256 fromChain,
        uint256 toChain,
        address fromAddress,
        address toAddress,
        uint256 amount,
        bytes32 transactionHash,
        bytes memory signature
    ) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(address(this),
            address(fromToken),
            address(toToken),
            fromChain,
            toChain,
            fromAddress,
            toAddress,
            amount,
            transactionHash));
        return ECDSAUpgradeable.recover(hash, signature);
    }

    function withdraw(
        IERC20Mintable fromToken,
        IERC20Mintable toToken,
        uint256 fromChain,
        address fromAddress,
        uint256 withdrawAmount,
        bytes32 transactionHash,
        bytes memory signature
    ) public nonReentrant {
        address toAddress = address(msg.sender);
        uint256 toChain = _currentChain();
        // we need to replace to/from positions because its opposite (destination) contract
        (Bridge memory bridge, uint256 index) = _resolveBridgeBySourceAndTarget(toToken, fromToken, toChain, fromChain);
        require(bridge.bridgeStatus == BridgeStatus.Enabled, "CrossChainBridge: bridge is not enabled");
        // make sure tx can't be claimed twice
        require(!_proofs[transactionHash], "CrossChainBridge: proof is already used");
        _proofs[transactionHash] = true;
        /* check that message was signed by operator */
        bytes32 hash = keccak256(abi.encodePacked(address(this),
            address(fromToken),
            address(toToken),
            fromChain,
            toChain,
            fromAddress,
            toAddress,
            withdrawAmount,
            transactionHash));
        require(ECDSAUpgradeable.recover(hash, signature) == _operator, "CrossChainBridge: bad signature");
        /* do withdraw based on type */
        if (bridge.bridgeType == BridgeType.Lockable) {
            _withdrawLockable(bridge, toAddress, withdrawAmount);
        } else if (bridge.bridgeType == BridgeType.Mintable) {
            _withdrawMintable(bridge, toAddress, withdrawAmount);
        } else {
            revert("CrossChainBridge: incorrect bridge type");
        }
        /* emit event amount withdrawal */
        emit CrossChainWithdraw({
        bridgeIndex : index,
        fromToken : address(fromToken),
        toToken : address(toToken),
        fromChain : fromChain,
        toChain : toChain,
        fromAddress : fromAddress,
        toAddress : toAddress,
        withdrawAmount : withdrawAmount,
        depositTxHash : transactionHash
        });
    }

    function _withdrawLockable(Bridge memory bridge, address toAddress, uint256 amount) internal {
        // mint tokens in this blockchain (we still use from token because we're in opposite contract)
        require(IERC20Mintable(bridge.fromToken).transfer(toAddress, amount), "CrossChainBridge: can't transfer tokens");
        // we also need to deduct minted amount (can be negative)
        _locked[bridge.fromToken] = _locked[bridge.fromToken].sub(int256(amount));
    }

    function _withdrawMintable(Bridge memory bridge, address toAddress, uint256 amount) internal {
        /* mint tokens in this blockchain */
        IERC20Mintable(bridge.fromToken).mint(toAddress, amount);
        /* we also need to deduct minted amount (can be negative) */
        _minted[bridge.fromToken] = _minted[bridge.fromToken].add(int256(amount));
    }

    function lockedOf(IERC20Mintable token) public view returns (int256) {
        return _locked[token];
    }

    function mintedOf(IERC20Mintable token) public view returns (int256) {
        return _minted[token];
    }

    function _currentChain() internal pure returns (uint256) {
        uint256 currentChain;
        assembly {
            currentChain := chainid()
        }
        return currentChain;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "CrossChainBridge: not allowed");
        _;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }
}