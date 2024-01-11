// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./MerkleProof.sol";
import "./Governor.sol";
import "./GovernorProposalThreshold.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorVotes.sol";
import "./GovernorVotesQuorumFraction.sol";
import "./GovernorTimelockControl.sol";

/**
 * @dev An ERC20 token for $UKRAINE.
 */
contract Ukraine is ERC20, ERC20Permit, ERC20Votes, Ownable {



    bytes32 merkleRoot;

    mapping(address => bool) claims;

    event AirdropCreated(bytes32 merkleRoot);
    event Claim(address indexed claimant, uint256 amount);

    // Total 44M
    // AIRDROP 50%
    // TREASURY 20%
    // LP 20%
    // UKRAINE OFFICIAL 10%

    uint256 SUPPLY_AIRDROP = 22_000_000 * 1e18;
    uint256 SUPPLY_LP = 8_800_000 * 1e18;
    uint256 SUPPLY_TREASURY = 8_800_000 * 1e18;
    uint256 SUPPLY_UKRAINE_OFFICIAL = 4_400_000 * 1e18;

    address UKRAINE_OFFICIAL = 0x165CD37b4C644C2921454429E7F9358d18A45e14;

    /**
     * @dev Constructor.
     */
    constructor(

    )
        ERC20("UKRAINE", "UKRAINE")
        ERC20Permit("UKRAINE")
    {
        _mint(address(this), SUPPLY_AIRDROP);
        _mint(UKRAINE_OFFICIAL, SUPPLY_UKRAINE_OFFICIAL);
        _mint(msg.sender, SUPPLY_TREASURY + SUPPLY_LP);
    }


    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claim(uint256 amount, bytes32[] calldata merkleProof) public {

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Invalid proof");
        require(!claims[msg.sender], "Already claimed");

        claims[msg.sender] = true;

        _transfer(address(this), msg.sender, amount);
        emit Claim(msg.sender, amount);
    }


    /**
     * @dev Returns true if the claim at the given index in the merkle tree has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(address account) public view returns (bool) {
        return claims[account];
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function openAidrop(bytes32 _merkleRoot) public onlyOwner {
        require(merkleRoot == bytes32(0), "Airdrop already created");

        merkleRoot = _merkleRoot;
        emit AirdropCreated(_merkleRoot);
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
