// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

/*
                                                                                                                                                                                                   @*   
                                 @@@@@                                                                                                                                                         /@@@@@@@@
               @@               @@@@@@@                                                                    .@@@@@@@@@@@                                                 @@@@@@@@@@             @@@@@@@@@
     @@@@@@@@@ @@@@             @@@@@@@   @@@@@                      @@@@@@@@@@@@@@@@@@&    @@@    @@@@  @@@@@@*     @@@,        @@@@      @@@@@                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@ .@@@@           @@@@@ ,@@@@@@@@@@@@@@@                @@@@@@@@@,@@   @@@@  @@@@   @@@@@              @@@@       @@@@@    @@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
    @@@@@@@@@@@    @@@@       @@@@@  (@@@@@(     @@@@@@                 @@@@@@@@      @@@% @@@@@ @@@ @@    @@@@@@@@@@@@@@       @@@@@@   @@@@@@                          @@@@@@@     @@@@@@@      @#    
     @@@@@@@        @@@@@@@@@@@@@@@   @@@@@@    %@@@@@@                  @@@@@@@@@@   @@@& @@@@@@@@  @@   .@@@@  @@@@@ @        @@@@@@  @@@@@                                        @@@@@              
       @@@@         @@@    @@@ @@@@    @@@@@@@@@@@@        @@@@@*        @@@@@ /@@@@ @@@@( @@ @@@@    @    @@@@ ,@@@@ ,@        @@ @@@@@@@  @@@@@@@@@@@@@@@      @@@@     &@@@@@@@   #@@@.              
        @@@,        @@@     @@ @@@(    @@@@      @@@@@@@@@@@@@@@@@@.    @@@@@@@  @@@@@@@   @. @@@@     @     @@@@@@   @@@@@@@@  @@ @@@@@@   @@@@@@    @@@@       @@@@@@@@@@@@@@@@@@  &@@@               
        @@@@      @@@@@@       @@@@    @@@@    @@@@@@@@@@@@@@@@@@@@  @@@@@@  @@@@         @@           @@@@*           @@@@@@   @@ .@@@@@,  @@@@@                @@@@@@@@@@@    @@@&  @@@@              
       @@@@@   @@@@@@@@@         @@@@  @@@@      @@@@@@               @@@@@  @@@@      /@@@@            @@@@@@@                ,@@  @@@@@    @@@@@@@              @@@@@@@   @@@@@@@   @@@@@             
      #@@@@    @@@@@@@@           @@@@  @@@       @@@@@    .#@@@@@@@@@       @@@@     @@@@@              %@@@@@                @@@          @@@@@@@@@@@@@@@        @@@@@@   @@@@@@   @@@@@@@@@@         
  @@@@@@@@@@                           @@@@@@     @@@@@@@@@@@@@@@@@@@@      @@@@@@@@%                                        @@@@,          &@@@                  @@@@@      @@@&   @@@@@@@@@@@@@       
 @@@@@@@@@@@@                       @@@@@@@@@@     @@@@@(  &@               @@@@@@@@@@@                                   @@@@@@@          @@@@@                 @@@@@      @@@@    #@@@@@@@@@@@@       
 @@@@@@@@@@@@                      @@@@@@@@@@@@    @@@@@ ,@@@@                @@@@@@@@@                                   @@@@@          @@@@@@@@@@@@@@@@@@@@@   @@@@@@     @@@@@@     @@@@@@@          
    @@@@@@                          %@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@                                                                   (@@@@@     .@@@@@@@@   @@@@@@     @@@@@@                      
                                       .@@@@       @@@@@@                                                                                                         @@@@@      @@@@@                      

*/

contract IDVaultTokenDistributor is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public vaultTokenContractInstance;

    // replace with merkle root
    bytes32 public merkleRoot = 0x238420bb38177724e9871199560323aa0150f6d32ca977a1cf14f19034d74f23;

    mapping (address => bool) public claimed;

    event VaultTokenClaim(address indexed user, uint256 amount);

    constructor(address vaultTokenAddress) {
        vaultTokenContractInstance = IERC20(vaultTokenAddress);
    }

    function setTokenAddress(address vaultTokenAddress) external onlyOwner {
        vaultTokenContractInstance = IERC20(vaultTokenAddress);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function pauseClaim() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseClaim() external onlyOwner whenPaused {
        _unpause();
    }

    function withdraw(uint256 tokenAmount) external onlyOwner {
        vaultTokenContractInstance.transfer(msg.sender, tokenAmount);
    }

    function hashLeaf(address claimAddress, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            claimAddress,
            amount
        ));
    }

    function claimTokens(uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused nonReentrant {
        require(!claimed[msg.sender], "Already claimed");

        // Compute the node and verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot, hashLeaf(msg.sender, amount)), "Invalid proof");

        // Set as claimed
        claimed[msg.sender] = true;

        // Transfer tokens
        vaultTokenContractInstance.safeTransfer(msg.sender, amount * 10 ** 18);

        emit VaultTokenClaim(msg.sender, amount);
    }
}
