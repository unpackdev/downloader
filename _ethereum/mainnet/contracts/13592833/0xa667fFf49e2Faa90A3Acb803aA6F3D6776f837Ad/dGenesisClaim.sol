// SPDX-License-Identifier: MIT
/*
     _ _____                      _     
    | |  __ \                    (_)    
  __| | |  \/ ___ _ __   ___  ___ _ ___ 
 / _` | | __ / _ \ '_ \ / _ \/ __| / __|
| (_| | |_\ \  __/ | | |  __/\__ \ \__ \
 \__,_|\____/\___|_| |_|\___||___/_|___/
                                        
                                        
         _____ _       _                
        /  __ \ |     (_)               
        | /  \/ | __ _ _ _ __ ___       
        | |   | |/ _` | | '_ ` _ \      
        | \__/\ | (_| | | | | | | |     
         \____/_|\__,_|_|_| |_| |_|   
*/
pragma solidity =0.8.2;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/**
 * Slightly modified version of: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
 * Changes include:
 * - remove "./interfaces/IMerkleDistributor.sol" inheritance
 * - Contract name and require statement message string changes
 * - add withdrawBlock and withdrawAddress state variables and withdraw() method
 */
interface dGenesisPrimeInterface {
    function claimMint(uint256 projectId,        
        uint256 numberOfTokens,
        address claimer)
        external
        ;
}

contract dGenesisClaim is Ownable, Pausable {
    struct Claim {
        uint256 projectId;
        bytes32 merkleRoot;
        address mintContract;
        // This is a packed array of booleans.
        mapping(uint256 => uint256) claimedBitMap;
    }
    uint256 public nextClaimId = 1;

    mapping(uint256 => Claim) claims;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        uint256 claimIndex,
        uint256 index,
        address account,
        uint256 amount
    );

    function addClaim(
        address _mintContract,
        uint256 _projectId,
        bytes32 _merkleRoot
    ) public onlyOwner returns (uint256) {
        claims[nextClaimId].mintContract = _mintContract;
        claims[nextClaimId].projectId = _projectId;
        claims[nextClaimId].merkleRoot = _merkleRoot;
        nextClaimId = nextClaimId + 1;
        return nextClaimId-1;
    }

    function isClaimed(uint256 claimIndex, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claims[claimIndex].claimedBitMap[
            claimedWordIndex
        ];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 claimIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claims[claimIndex].claimedBitMap[claimedWordIndex] =
            claims[claimIndex].claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * No caller permissioning needed since token is transfered to account argument,
     *    and there is no incentive to call function for another account.
     * Can only submit claim for full claimable amount, otherwise proof verification will fail.
     */
    function claim(
        uint256 claimIndex,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(
            !isClaimed(claimIndex, index),
            "dGenesisVaultClaim: Drop already claimed."
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(
                merkleProof,
                claims[claimIndex].merkleRoot,
                node
            ),
            "dGenesisVaultClaim: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(claimIndex, index);
        //mint logic goes here
        

        dGenesisPrimeInterface(claims[claimIndex].mintContract).claimMint(claims[claimIndex].projectId,
                amount,
                account);



        emit Claimed(claimIndex, index, account, amount);
    }
}
