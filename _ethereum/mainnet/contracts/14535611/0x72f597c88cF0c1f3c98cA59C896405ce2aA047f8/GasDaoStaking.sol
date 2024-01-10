// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

/**
 Staking contract that awards GAS holders that delegate based on how much Ethereum gas they spend while delegated.
 The Merkle root, token allocation, and claim end date are settable by the owner, the DAO Timelock/Treasury.

Governance Proposal to start the staking contract:
targets = [0x6Bba316c48b49BD1eAc44573c5c871ff02958469, 0x72f597c88cF0c1f3c98cA59C896405ce2aA047f8, 0x72f597c88cF0c1f3c98cA59C896405ce2aA047f8]
values = [0, 0, 0],
calldata = [
    transfer(0x72f597c88cF0c1f3c98cA59C896405ce2aA047f8, 30000010000000000000000000000),
    setMerkleRoot(0x8facf34818fc868f4d93d71a430b70e3c1cbbf2ab10133110e3718fce4215d02),
    setClaimPeriodEnds(1651017600),
]

targets
[0x6Bba316c48b49BD1eAc44573c5c871ff02958469, 0x72f597c88cF0c1f3c98cA59C896405ce2aA047f8, 0x72f597c88cF0c1f3c98cA59C896405ce2aA047f8]
values
[0, 0, 0]
calldata
[0xa9059cbb00000000000000000000000072f597c88cf0c1f3c98ca59c896405ce2aa047f8000000000000000000000000000000000000000060ef6b1aba6f072335f5e100, 0x7cb647598facf34818fc868f4d93d71a430b70e3c1cbbf2ab10133110e3718fce4215d02, 0x2503c057000000000000000000000000000000000000000000000000000000006269d900]
description
Seed staking contract
*/

contract GasDaoStaking is Ownable {
    address private constant GAS_TOKEN_ADDRESS = 0x6Bba316c48b49BD1eAc44573c5c871ff02958469;
    address private constant GAS_TIMELOCK_ADDRESS = 0xC9A7D537F17194c68455D75e3d742BF2c3cE3c74;
    bytes32 public merkleRoot;
    mapping(address=>bool) private claimed;

    event MerkleRootChanged(bytes32 merkleRoot);
    event ClaimPeriodEndsChanged(uint256 claimPeriodEnds);
    event Claim(address indexed claimant, uint256 amount);

    uint256 public claimPeriodEnds;

    constructor() {
        // transfer ownership to the timelock
        _transferOwnership(GAS_TIMELOCK_ADDRESS);
    }

    /**
     * @dev Sets the merkle root.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev Sets the claim period end.
     * @param _claimPeriodEnds The new claim period end timestamp.
     */
    function setClaimPeriodEnds(uint256 _claimPeriodEnds) public onlyOwner {
        claimPeriodEnds = _claimPeriodEnds;
        emit ClaimPeriodEndsChanged(_claimPeriodEnds);
    }

    /**
     * @dev Claims airdropped tokens.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "GasDao: Valid proof required.");
        require(!claimed[msg.sender], "GasDao: Tokens already claimed.");
        claimed[msg.sender] = true;
    
        emit Claim(msg.sender, amount);

        ERC20(GAS_TOKEN_ADDRESS).transfer(msg.sender, amount);
    }

    /**
     * @dev Returns true if the claim at for the address has already been made.
     * @param account The address to check if claimed.
     */
    function hasClaimed(address account) public view returns (bool) {
        return claimed[account];
    }

    /**
     * @dev Allows anyone to sweep unclaimed tokens after the claim period ends.
     */
    function sweep() public {
        require(block.timestamp > claimPeriodEnds, "GasDao: Claim period not yet ended");
        ERC20(GAS_TOKEN_ADDRESS).transfer(GAS_TIMELOCK_ADDRESS, ERC20(GAS_TOKEN_ADDRESS).balanceOf(address(this)));
    }
}