// SPDX-License-Identifier: GPL-3.0

import "./Ownable.sol";
import "./MerkleProof.sol";

pragma solidity ^0.8.0;



interface IERC721Extended {
    function purchaseMultipleFor(uint256 count, address to) external payable returns (uint256 id, uint256 purchased);
    function giveawayMint(uint256 count, address to) external payable;
}

contract PresaleMerkle is Ownable {

    /**
    * Merkle based whitelist and giveaway module. Works for any IERC721Extended contract 
    * CAUTION: This approach stores data based on the MERKLE ROOTS themselves. Because of this,
    * be careful to AVOID using a previously used merkle root, as previous data could exist.
    */


    /********* WHITELIST **********/
    // mapping of contract address to merkle root
    mapping(address /* contractAddress */ => bytes32 /* merkleRoot */) whitelistMerkleRoots;
    // maximum presale items per account
    mapping(bytes32 /* merkleRoot */ => uint256 /*presaleLimit */) public whitelistLimits;
    // mapping of contract addresses to mints per addresses
    mapping(bytes32 /*merkleRoot*/ => mapping(address /* userAddress */ => uint256 /* numMinted */)) whitelistMintsPerMerkleRoot;

    /********* GIVEAWAY **********/
    // mapping of contract address to merkle root
    mapping(address /* contractAddress */ => bytes32 /* merkleRoot */) giveawayMerkleRoots;
   // maximum presale items per account
    mapping(bytes32 /* contractAddress */ => uint256 /*presaleLimit */) public giveawayLimits;
    // mapping of contract addresses to mints per addresses
    mapping(bytes32 /*merkleRoot*/ => mapping(address /* userAddress */ => uint256 /* numMinted */)) giveawayMintsPerMerkleRoot;



    constructor () {

    }

    /**
     * @dev Checks whether current account is in the whitelist
     */
    function inMerkleTree(address addr, bytes32 merkleRoot, bytes32[] memory proof) public pure returns (bool) {
        // create hash of leaf data, using target address
        bytes32 leafHash = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, merkleRoot, leafHash);
    }

    /**
     * @dev View function to check if in whitelist for contract
     */
    function inWhitelist(address user, address contractAddress, bytes32[] calldata proof) public view returns (bool) {
        bytes32 root = whitelistMerkleRoots[contractAddress];
        return inMerkleTree(user, root, proof);
    }

    /**
     * @dev View function to check remaining whitelist mints
     */
    function whitelistMintsRemaining(address user, address contractAddress, bytes32[] calldata proof) public view returns (uint256) {
        bytes32 root = whitelistMerkleRoots[contractAddress];
   
        if(inMerkleTree(user, root, proof)) {
            uint256 mintLimit = whitelistLimits[root];
            uint256 alreadyMinted = whitelistMintsPerMerkleRoot[root][user]; 
            return mintLimit - alreadyMinted;
        }
        // otherwise not in whitelist so return 0
        return 0;
    }

    /**
     * @dev View function to check if in giveaway for contract
     */
    function inGiveaway(address user, address contractAddress, bytes32[] calldata proof) public view returns (bool) {
        bytes32 root = giveawayMerkleRoots[contractAddress];
        return inMerkleTree(user, root, proof);
    }

    /**
     * @dev View function to check remaining giveaway mints
     */
    function giveawayMintsRemaining(address user, address contractAddress, bytes32[] calldata proof) public view returns (uint256) {
        bytes32 root = giveawayMerkleRoots[contractAddress];
   
        if(inMerkleTree(user, root, proof)) {
            uint256 mintLimit = giveawayLimits[root];
            uint256 alreadyMinted = giveawayMintsPerMerkleRoot[root][user];
            return mintLimit - alreadyMinted;
        }
        // otherwise not in giveaway so return 0
        return 0;
    }

    /**
     * @dev Creates whitelist based on a merkle root
     *
     */
    function setWhitelist(bytes32 merkleRoot, address contractAddress, uint256 mintLimit) public onlyOwner {
        whitelistMerkleRoots[contractAddress] = merkleRoot;
        whitelistLimits[merkleRoot] = mintLimit;
    }

    /**
     * @dev Creates giveaway list based on a merkle root
     *
     */
    function setGiveaway(bytes32 merkleRoot, address contractAddress, uint256 mintLimit) public onlyOwner {
        giveawayMerkleRoots[contractAddress] = merkleRoot;
        giveawayLimits[merkleRoot] = mintLimit;
    }

    /**
     * @dev Try to mint via whitelist
     * Checks proof against merkle tree.
     * @param to -- the address to mint the asset to. This allows for minting on someone's behalf if neccesary
     * @param contractAddress -- the target token contract to mint from
     * @param amount -- the num to mint
     * @param proof -- the merkle proof for this address
     */
    function whitelistPurchase(address to, address contractAddress, uint256 amount, bytes32[] calldata proof) external payable {
        // validate authorization via merkle proof
        bytes32 merkleRoot = whitelistMerkleRoots[contractAddress];
        require(inMerkleTree(to, merkleRoot, proof), "PresaleMerkle: Invalid address or proof!");

        // validate still remaining mints
        uint256 mintLimit = whitelistLimits[merkleRoot];
        uint256 alreadyMinted = whitelistMintsPerMerkleRoot[merkleRoot][to];
        require(alreadyMinted + amount <= mintLimit, "PresaleMerkle: Too many mints.");

        // update mints
        whitelistMintsPerMerkleRoot[merkleRoot][to] = alreadyMinted + amount;

        // mint from contract, passing along eth
        IERC721Extended tokenContract = IERC721Extended(contractAddress);
        tokenContract.purchaseMultipleFor{value: msg.value}(amount, to);
    }

    /**
     * @dev Try to mint via giveaway -- essnetially the same as whitelist, just different data stores
     * Checks proof against merkle tree.
     * @param to -- the address to mint the asset to. This allows for minting on someone's behalf if neccesary
     * @param contractAddress -- the target token contract to mint from
     * @param amount -- the num to mint
     * @param proof -- the merkle proof for this address
     */
    function giveaway(address to, address contractAddress, uint256 amount, bytes32[] calldata proof) external {
        // validate authorization via merkle proof
        bytes32 merkleRoot = giveawayMerkleRoots[contractAddress];
        require(inMerkleTree(to, merkleRoot, proof), "PresaleMerkle: Invalid address or proof!");

        // validate mints
        uint256 mintLimit = giveawayLimits[merkleRoot];
        uint256 alreadyMinted = giveawayMintsPerMerkleRoot[merkleRoot][to];
        require(alreadyMinted + amount <= mintLimit, "PresaleMerkle: Too many mints.");

        // update mints
        giveawayMintsPerMerkleRoot[merkleRoot][to] = alreadyMinted + amount;

        // ask contract for giveaway
        IERC721Extended tokenContract = IERC721Extended(contractAddress);
        tokenContract.giveawayMint(amount, to);
    }


}