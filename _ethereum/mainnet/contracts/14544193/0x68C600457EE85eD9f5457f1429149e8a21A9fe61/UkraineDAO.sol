// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./MerkleProof.sol";

/**
 * @dev An ERC20 token for UkraineDAO.
 */
contract UkraineDAO is ERC20, ERC20Permit, ERC20Votes, Ownable {


    struct Airdrop {
        bytes32 merkleRoot;
    }

    Airdrop[] airdrops;
    mapping(bytes32 => bool) claims;

    event AirdropCreated(uint16 index);
    event Claim(address indexed claimant, uint16 index, uint256 amount);


    /**
     * @dev Constructor.
     */
    constructor(

    )
        ERC20("UkraineDAO", "UkraineDAO")
        ERC20Permit("UkraineDAO")
    {
        // _mint(address(this), airdropSupply);
        // _mint(address(this), devSupply);
    }


    /**
     * @dev Claims airdropped tokens.
     * @param index Airdrop index.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claim(uint16 index, uint256 amount, bytes32[] calldata merkleProof) public {
        require(index < airdrops.length, "Invalid index");

        Airdrop storage airdrop = airdrops[index];


        bytes32 key = keccak256(abi.encodePacked(index, msg.sender));
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, airdrop.merkleRoot, leaf);
        require(valid, "Invalid proof");
        require(!claims[key], "Already claimed");

        claims[key] = true;

        _mint(msg.sender, amount);
        emit Claim(msg.sender, index, amount);
    }


    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(uint16 index, address account) public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(index, account));
        return claims[key];
    }

    function airdropsCount() public view returns (uint256) {
        return airdrops.length;
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function openAidrop(uint16 index, bytes32 _merkleRoot) public onlyOwner {
        require(index == airdrops.length, "Airdrop already created");

        Airdrop memory airdrop = Airdrop(_merkleRoot);
        airdrops.push(airdrop);
        emit AirdropCreated(index);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
