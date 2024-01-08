pragma solidity ^0.8.0;

// Libraries
import "./MerkleProof.sol";
import "./AccessControlUpgradeable.sol";
// Contracts

import "./ClaimableFortuneTeller.sol";

contract ClaimableNFTDistributor is AccessControlUpgradeable {
    

    /** Storage */
    mapping(bytes32 => uint256) public merkleRootTokenId;
    mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;
    ClaimableFortuneTeller immutable nft;

    /** Events */

    event Claimed(address indexed account, uint256 tokenId, uint256 amount);

    event MerkleAdded(uint256 indexed tokenId, bytes32 indexed merkleRoot);


     /**
     * @notice Initializes the Distributor contract with the Bonus & Teller NFTs
     *  
     * @param claimableNFT The address of the nft being distributed.
     */
   
    constructor(address claimableNFT){
        require(isContract(claimableNFT),'Initialize: claimableNFT must be a contract');
        __AccessControl_init(); 
        
        nft = ClaimableFortuneTeller(claimableNFT);
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }



    /** External functions */

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleRoot Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     * @return claimed_ returns a boolean to check if the tier has already been claimed
     */
    function isClaimed(bytes32 merkleRoot, uint256 nodeIndex)
        external
        view
        returns (bool claimed_)
    {
        claimed_ = _isClaimed(merkleRoot, nodeIndex);
    }

    /**
     * @notice Adds a new merkle to be able to claim NFTs.
     * @param tokenId Id of NFT to assign merkle for.
     * @param merkleRoot The merkle root to assign to the new tier.
     *
     * Requirements:
     *  - Caller must be an admin
     */
    function addMerkle(uint256 tokenId, bytes32 merkleRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRootTokenId[merkleRoot] = tokenId;

        emit MerkleAdded(tokenId, merkleRoot);
    }

    /**
     * @notice Claims TellerNFTs for a given verifiable merkle proofs for each tier.
     * @param account The address to claim NFTs on behalf.
     * @param proofs An array proofs generated from the merkle tree.
     *
     * Requirements:
     *  - Node in the merkle root must not be claimed already
     *  - Proof of the node must match the merkle tree
     */
    function claim(bytes32 merkleRoot, address account, uint256 nodeIndex, uint256 amount, bytes32[] calldata proofs) external {
        require(
            !_isClaimed(merkleRoot, nodeIndex),
            "TellerNFT Distributor: already claimed"
        );
        require(
            _verifyProof(merkleRoot, nodeIndex, account, amount, proofs),
            "TellerNFT Distributor: invalid proof"
        );

        // Mark it claimed and send the token.
        _setClaimed(merkleRoot, nodeIndex);
        uint256 tokenId = merkleRootTokenId[merkleRoot];
        nft.mint(account, tokenId, amount);
        emit Claimed(account, tokenId, amount);
    }

   
    /** Internal Functions */

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleRoot Root of the merkle.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _setClaimed(bytes32 merkleRoot, uint256 nodeIndex) internal {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        claimedBitMap[merkleRoot][claimedWordIndex] =
            claimedBitMap[merkleRoot][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param merkleRoot Root of the merkle.
     * @param nodeIndex Index of the node in the merkle root.
     * @return claimed_ returns a boolean to check if the tier has already been claimed
     */
    function _isClaimed(bytes32 merkleRoot, uint256 nodeIndex)
        internal
        view
        returns (bool)
    {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        uint256 claimedWord = claimedBitMap[merkleRoot][
            claimedWordIndex
        ];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @notice it verifies the request's merkle proof with the merkle root in order to claim an NFT
     * @param account the account's address to be hashed and verified with the claim
     * @param proof the merkle proof to verify
     */
    function _verifyProof(bytes32 merkleRoot, uint256 nodeIndex, address account, uint256 amount, bytes32[] calldata proof)

        internal
        view
        returns (bool verified)
    {
        verified = MerkleProof.verify(
            proof,
            merkleRoot,
            keccak256(
                abi.encodePacked(nodeIndex, account, amount)
            )
        );
    }

    function isContract(address addr) internal returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
            
}
