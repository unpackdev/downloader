// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleProof.sol";
import "./Counters.sol";
import "./IERC721Enumerable.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

/*
* @title ERC1155 token for Cranky Critter Passes
*/

interface CritterERC721Contract {
    function ownerOf(uint256 id) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
 }

contract CritterPasses is ERC1155, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 
    mapping(uint256 => bool) private isClaimClosed;

    mapping(uint256 => Pass) public passes;

    struct Pass {
        uint256 maxSupply;
        uint256 totalSupply;
        string ipfsMetadataHash;
        address burnContract;
        address claimContract;
        bytes32 merkleRoot;
        mapping(address => bool) addressClaimed;
        mapping(uint256 => bool) tokenClaimed;
    }

    constructor() ERC1155("ipfs://") {
    }

    /**
    * @notice adds a new pass
    * 
    * @param _merkleRoot the merkle root to verify eligible claims
    * @param _maxSupply maximum total supply  (if mintable in future)
    * @param _ipfsMetadataHash the ipfs hash for metadata
    * @param _burnContract  the contract that will burn the pass
    * @param _claimContract  the contract with tokens that will claim the pass
    */
    function addpass(
        bytes32 _merkleRoot, 
        uint256 _maxSupply,            
        string memory _ipfsMetadataHash,
        address _burnContract,
        address _claimContract
    ) public onlyOwner {
        Pass storage p = passes[counter.current()];
        p.merkleRoot = _merkleRoot;
        p.maxSupply = _maxSupply;                                        
        p.ipfsMetadataHash = _ipfsMetadataHash;
        p.burnContract = _burnContract;
        p.claimContract = _claimContract;
        counter.increment();
    }    

    /**
    * @notice edit an existing pass
    * @param _merkleRoot the merkle root to verify eligile claims
    * @param _ipfsMetadataHash the ipfs hash for pass metadata
    * @param _burnContract  the contract that will burn the pass
    * @param _passIndex the pass id to change
    */
    function editpass(
        bytes32 _merkleRoot,      
        string memory _ipfsMetadataHash,
        address _burnContract,
        address _claimContract,
        uint256 _passIndex
    ) external onlyOwner {
        require(exists(_passIndex), "Editpass: pass does not exist");
        passes[_passIndex].merkleRoot = _merkleRoot;                   
        passes[_passIndex].ipfsMetadataHash = _ipfsMetadataHash;  
        passes[_passIndex].burnContract = _burnContract;  
        passes[_passIndex].claimContract = _claimContract;
    }    

    /**
    * @notice owner mint pass tokens for airdrops
    * @param passID the pass id to mint
    * @param amount the amount of tokens to mint
    */
    function mint(uint256 passID, uint256 amount, address to) external onlyOwner {
        require(exists(passID), "pass does not exist");
        require(passes[passID].totalSupply + amount <= passes[passID].maxSupply, "Max supply reached");

        _mint(to, passID, amount, "");
        passes[passID].totalSupply += amount;
    }

    /**
    * @notice close claiming passes for MHs hold
    * 
    * @param passId the pass ids to close claiming for 
    */
    function closeClaim(uint256 passId) external onlyOwner {
        isClaimClosed[passId] = true;
    }

    /**
    * @param passId the id of the pass to claim for
    * @param merkleProof the valid merkle proof of sender for given pass id
    */
    function claim(
        uint256 passId,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimClosed[passId], "Claim: is closed");  
        require(passes[passId].totalSupply < passes[passId].maxSupply, "Would go over max supply");      
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, passes[passId].merkleRoot, node),
            "Invalid proof."
        );
        require(!passes[passId].addressClaimed[msg.sender], "This address has already claimed");

        passes[passId].addressClaimed[msg.sender] = true;
        passes[passId].totalSupply++;
        _mint(msg.sender, passId, 1, "");             
    }

    function setIsFullyClaimable(uint256[] calldata ids, uint256 passId) public view returns(bool){
        for (uint256 i = 0; i < ids.length;  i++) {
            if (passes[passId].tokenClaimed[ids[i]]) {
                return false;
            } 
        }
        return true;
    }
    
    function setIsFullyOwned(address account, uint256[] calldata ids, uint256 passId)
        internal
        view
        returns (bool)
    {
        CritterERC721Contract claimTokens = CritterERC721Contract(passes[passId].claimContract);
        for (uint256 i = 0; i < ids.length; i++) {
            if (claimTokens.ownerOf(ids[i]) != account) {
                return false;
            }
        }
        return true;
    }

    /**
    * @param passId the id of the pass to claim for
    * @param ids the tokens to claim for
    */
    function claimForTokens(
        uint256 passId,
        uint256[] calldata ids 
    ) external {
        require(!isClaimClosed[passId], "Claim: is closed");    
        require(passes[passId].claimContract != address(0), "No token set for claim");  
        require(passes[passId].totalSupply + ids.length <= passes[passId].maxSupply, "Would go over max supply");
        require(setIsFullyClaimable(ids, passId), "Some are already claimed");
        require(setIsFullyOwned(msg.sender, ids, passId), "Some are not owned by sender");
        for (uint256 i; i < ids.length; i++) {
           passes[passId].tokenClaimed[ids[i]] = true;
        }
        passes[passId].totalSupply += ids.length;
        _mint(msg.sender, passId, ids.length, "");             
    }


     function burnToClaim(
        address account, 
        uint256 index, 
        uint256 amount
    ) external {
        require(passes[index].burnContract == msg.sender, "Only allow from specified contract");
        _burn(account, index, amount);
    }  

    /**
    * @notice return total supply for all existing passes
    */
    function totalSupplyAll() external view returns (uint[] memory) {
        uint[] memory result = new uint[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = passes[i].totalSupply;
        }
        return result;
    }

    /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 id) public view returns (bool) {
        return passes[id].maxSupply > 0;
    }    

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the pass id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), passes[_id].ipfsMetadataHash));
    }

    function whatTokensHaveClaimed(uint256[] calldata tokens, uint256 passId) public view returns (uint256[] memory){
        uint256[] memory haveClaimed = new uint256[](tokens.length);
        uint256 addedCounter;
        for (uint256 index = 0; index < tokens.length; index++) {
            if (passes[passId].tokenClaimed[tokens[index]]) {
                haveClaimed[addedCounter] = tokens[index];
                addedCounter++;
            } 
        }
        return haveClaimed;
    }
}