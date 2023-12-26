//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

/**
 * @title Refund Contract for ZachXBT Legal Case
 * @author 0xngmi (https://twitter.com/0xngmi)
 * @custom:coauthor cygaar (https://twitter.com/0xCygaar)
 * @custom:contributor pcaversaccio (https://pcaversaccio.com)
 * @custom:security-contact 0xngmi <0xngmi@protonmail.com>
 */
contract ZachRefund is Ownable {
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32[];

    bytes32 public immutable MERKLE_ROOT;
    IERC20 public immutable TOKEN;

    mapping(address claimant => bool flag) public claimed;

    error EtherTransferFail();
    error MerkleVerificationFail();

    /**
     * @dev You can cut out 10 opcodes in the creation-time EVM bytecode
     * if you declare a constructor `payable`.
     *
     * For more in-depth information see here:
     * https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966/5.
     */
    constructor(bytes32 merkleRoot_, IERC20 token_) payable {
        MERKLE_ROOT = merkleRoot_;
        TOKEN = token_;
    }

    function retrieveFundsETH(address to) external onlyOwner {
        // We don't care about a potential reentrancy in this case.
        (bool sent,) = to.call{value: address(this).balance}("");
        if (!sent) revert EtherTransferFail();
    }

    function retrieveFunds(IERC20 tokenFrom, address to, uint256 amount) external onlyOwner {
        tokenFrom.safeTransfer(to, amount);
    }

    /**
     * @dev There are some issues with Merkle trees such as pre-image attacks or
     * possibly duplicated leaves on unbalanced trees, but here we protect against
     * them by checking against `msg.sender` and only allowing each account to claim once.
     *
     * For more in-depth information see here:
     * https://github.com/miguelmota/merkletreejs#notes.
     */
    function claim(bytes32[] calldata merkleProof, uint256 amount) public {
        if (!merkleProof.verifyCalldata(MERKLE_ROOT, keccak256(abi.encode(msg.sender, amount))) || claimed[msg.sender])
        {
            revert MerkleVerificationFail();
        }
        claimed[msg.sender] = true;
        TOKEN.safeTransfer(msg.sender, amount);
    }
}
