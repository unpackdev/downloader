// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./MerkleProof.sol";

contract OGX is ERC20, ERC20Burnable {
    bytes32 public immutable merkleRoot;
    mapping(address => bool) public hasClaimed;

    error DeadlineReached();
    error AlreadyClaimed();
    error NotInMerkle();
    error TransfersNotYetEnabled();

    constructor() ERC20("OGX", "OGX") {
        merkleRoot = 0xe72353e2f6010f96a36250acf32969ce9c708306426e834eb3931ff25b9310db;
    }

    event Claim(uint32 rank, address indexed to, uint16 term);

    function claim(
        uint32 rank,
        address to,
        uint16 term,
        bytes32[] calldata proof
    ) external {
        if (block.number >= 20000000) revert DeadlineReached();
        if (hasClaimed[to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(rank, to, term)))
        );
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[to] = true;

        _mint(to, term * (10 ** uint256(decimals())));
        emit Claim(rank, to, term);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0))
            if (block.number < 18250000) revert TransfersNotYetEnabled();
    }
}