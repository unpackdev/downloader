// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ECDSAUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Initializable.sol";

import "./IERC1271Upgradeable.sol";

contract TestWallet is IERC1271Upgradeable, Initializable {
    bytes4 private constant ERC1271_MAGIC_VALUE = bytes4(keccak256('isValidSignature(bytes32,bytes)'));

    // TODO A transactionsExecuted mapping to ensure a meta transaction is only executed once. Note: Make sure to set transactionsExecuted[transactionHash] = true after a successful execution.
    event SetAllowedFunctionOnTarget(address target, bytes4 functionSig, bool isAllowed);
    event SetAllowedTarget(address target, bool isAllowed);
    event SetLockedToken(address collection, uint256 tokenId, bool isLocked);

    bool public _checkSignature; // TODO delete this

    address private _owner;
    address private _operator;
    // uint256 public _nonce;

    struct Target {
        bool isAllowed;
        bool isScoped;
        bool isFallbackAllowed; // TODO do more research on `Is there any reason to disable fallbacks?`
        mapping(bytes4 => bool) allowedFunctions;
    }

    mapping(address => Target) public _allowedTargets;
    mapping(address => mapping(uint256 => bool)) public _lockedTokens;

    modifier onlyOperator() {
        require(_operator == msg.sender, 'Caller is not the operator');
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Caller is not the owner');
        _;
    }

    function initialize(address operator, address owner) external initializer {
        _operator = operator;
        _owner = owner;
        _checkSignature = true;
    }

    function setOwnerAddress(address ownerAddress) public onlyOperator {
        _owner = ownerAddress;
    }

    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    function setCheckSignature(bool checkSignature) public onlyOperator {
        _checkSignature = checkSignature;
    }

    function getOperatorAddress() public view returns (address) {
        return _operator;
    }

    function setAllowedFunction(
        address target,
        bytes4 functionSig,
        bool isAllow
    ) public onlyOperator {
        _allowedTargets[target].isAllowed = true;
        _allowedTargets[target].isScoped = true;
        _allowedTargets[target].allowedFunctions[functionSig] = isAllow;

        emit SetAllowedFunctionOnTarget(target, functionSig, _allowedTargets[target].allowedFunctions[functionSig]);
    }

    function setTargetAllowed(address target, bool isAllowed) public onlyOperator {
        _allowedTargets[target].isAllowed = isAllowed;
        emit SetAllowedTarget(target, _allowedTargets[target].isAllowed);
    }

    function isAllowedTarget(address target) public view returns (bool) {
        return (_allowedTargets[target].isAllowed);
    }

    function setLockedToken(
        address collection,
        uint256 tokenId,
        bool isLocked
    ) public onlyOperator {
        _lockedTokens[collection][tokenId] = isLocked;
        emit SetLockedToken(collection, tokenId, isLocked);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // function getNonce() public view returns (uint256) {
    //     return _nonce;
    // }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        bytes memory signature
    ) public payable onlyOwner returns (bool success) {
        checkTransaction(to, value, data);

        // TODO we should check nonce
        // _nonce++;

        success = _execute(to, value, data, gasleft());
        return success;
    }

    function _execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        require(_allowedTargets[to].isAllowed, 'Target address is not allowed');
        if (data.length >= 4) {
            require(!_allowedTargets[to].isScoped || _allowedTargets[to].allowedFunctions[bytes4(data)], 'Target function is not allowed');
        } else {
            require(data.length == 0, 'Function signature too short');
            require(!_allowedTargets[to].isScoped || _allowedTargets[to].isFallbackAllowed, 'Fallback not allowed for this address');
        }
    }

    // Used to transfer tokens
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }

    function transferNFT(
        address to,
        address collection,
        uint256 tokenId
    ) external onlyOwner {
        require(!_lockedTokens[collection][tokenId], 'Locked!');
        ERC721Upgradeable(collection).safeTransferFrom(address(this), to, tokenId);
    }

    // ERC-1271
    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        if (_checkSignature) {
            require(signature.length == 65, 'Invalid signature length');
            address signer = recoverSigner(hash, signature);
            require(signer == _owner, 'Invalid signer');
            return ERC1271_MAGIC_VALUE;
        }

        return ERC1271_MAGIC_VALUE;
    }

    // ERC-721 Receiver
    // See more from: https://eips.ethereum.org/EIPS/eip-721
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    receive() external payable {}

    // https://help.gnosis-safe.io/en/articles/4738352-what-is-a-fallback-handler-and-how-does-it-relate-to-the-gnosis-safe
    fallback() external {}

    function recoverSigner(bytes32 signedHash, bytes memory signatures) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signatures, add(0x20, mul(0x41, 0))))
            s := mload(add(signatures, add(0x40, mul(0x41, 0))))
            v := and(mload(add(signatures, add(0x41, mul(0x41, 0)))), 0xff)
        }
        require(v == 27 || v == 28, 'Utils: bad v value in signature');

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), 'Utils: ecrecover returned 0');
        return recoveredAddress;
    }
}
