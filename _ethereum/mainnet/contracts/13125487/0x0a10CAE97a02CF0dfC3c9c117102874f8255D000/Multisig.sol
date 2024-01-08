// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./OwnerManager.sol";
import "./Executor.sol";
import "./SafeMath.sol";
import "./Enum.sol";

contract Multisig is
    OwnerManager,
    Executor
{
    using SafeMath for uint256;

    uint256 public nonce = 0;
    mapping(bytes32 => Enum.HashState) public TxHashs;

    event ExecutionResult(bytes32 txHash, Enum.HashState);

    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    /// @dev initialize initial owners and threshold.
    /// @param _owners List of initial owners.
    /// @param _threshold Number of required confirmations.
    function initialize(address[] memory _owners, uint256 _threshold) external {
        setupOwners(_owners, _threshold);
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        bytes32 txHash,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) external payable returns (bool success) {
        require(TxHashs[txHash] != Enum.HashState.Success, "SP010");
        require(checkSignatures(to, value, data, txHash, operation, vs, rs, ss), "SP025");
        nonce++;
        success = execute(to, value, data, operation, safeTxGas);

        if (success) {
            TxHashs[txHash] = Enum.HashState.Success;
            ExecutionResult(txHash, Enum.HashState.Success);
        } else {
            TxHashs[txHash] = Enum.HashState.Fail;
            ExecutionResult(txHash, Enum.HashState.Fail);
        }
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function checkSignatures(
        address to,
        uint256 value,
        bytes calldata data,
        bytes32 txHash,
        Enum.Operation operation,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) private view returns (bool) {
        uint256 signum = vs.length;
        require(signum >= threshold, "SP020");
        require(signum <= ownerCount, "SP021");

        require(signum == rs.length, "SP022");
        require(signum == ss.length, "SP022");

        bytes32 message = _messageToSign(to, value, data, txHash, operation);
        address[] memory addrs = new address[](signum);
        for (uint256 i = 0; i < signum; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i]+27, rs[i], ss[i]);
            require(isOwner(addrs[i]), "SP023");

            //address should be distinct
            for (uint j = 0; j < i; j++) {
                require(addrs[i] != addrs[j], "SP024");
            }
        }
        return true;
    }

    // Generates the message to sign given the output destination address and amount and data.
    // includes this contract's address and a nonce for replay protection.
    function _messageToSign(
        address to,
        uint256 value,
        bytes calldata data,
        bytes32 txHash,
        Enum.Operation operation
    ) private view returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(address(this), to, value, data, txHash, operation));
        return message;
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public pure returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}
