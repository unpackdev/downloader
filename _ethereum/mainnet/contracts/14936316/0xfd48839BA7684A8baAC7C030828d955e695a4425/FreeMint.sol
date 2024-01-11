// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Wandernaut.sol";

contract FreeMint is Ownable, Pausable {
    bytes32 public immutable root;
    Wandernaut public immutable wandernaut;

    /// The next token ID to mint
    uint256 public current;

    /// The final token ID to mint
    uint256 public end;

    mapping(address => bool) private claimed;

    constructor(
        bytes32 _root,
        address _wandernaut,
        uint256 _current,
        uint256 _end
    ) {
        wandernaut = Wandernaut(_wandernaut);
        root = _root;
        current = _current;
        end = _end;
        _pause();
    }

    /// Unpause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// Pause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Claim a Naut.
    /// @param proof leaves proof for address
    function claim(bytes32[] calldata proof) external whenNotPaused {
        require(current <= end, "Out of tokens");
        require(!claimed[msg.sender], "Already claimed");
        require(_verify(_leaf(msg.sender), proof), "Bad merkle proof");

        claimed[msg.sender] = true;
        uint256 id = current;
        current++;

        wandernaut.adminMint(msg.sender, id);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// Reclaim ownership of Naut contract
    function reclaim() external onlyOwner {
        wandernaut.transferOwnership(msg.sender);
    }
}
