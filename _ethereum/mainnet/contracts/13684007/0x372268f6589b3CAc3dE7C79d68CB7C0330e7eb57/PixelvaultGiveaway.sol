// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./Counters.sol";

/*
* @title Contract for Pixelvault giveaways using Chainlink VRF 
*
* @author Niftydude
*/
contract Pixelvault1155Giveaway is VRFConsumerBase, ERC1155Holder, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(uint256 => Giveaway) public giveaways;

    IERC1155 public erc1155Contract;

    event Claimed(uint indexed index, address indexed account, uint amount);

    struct Giveaway {
        uint256 snapshotEntries;
        uint256 amountOfWinners;        
        uint256 randomNumber;
        uint256 tokenId;
        uint256 claimOpen;
        uint256 claimClose;
        bool isFulfilled;
        bool allowDuplicates;
        string entryListIpfsHash;
        address contractAddress;
        mapping(address => uint256) claimed;
        bytes32 merkleRoot;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;
    }   

    /**
    * @notice set merkle root for a given draw
    * 
    * @param _merkleRoot the merkle root to verify eligile claims
    */
    function setMerkleRoot(
        bytes32 _merkleRoot, 
        uint256 _drawId
    ) external onlyOwner {
        require(giveaways[_drawId].isFulfilled, "setMerkleRoot: draw not fulfilled");

        giveaways[_drawId].merkleRoot = _merkleRoot;
    } 

    /**
    * @notice return all winning entries for a given draw
    * 
    * @param giveawayId the giveaway id to return winners for
    */
    function getWinners(uint256 giveawayId) external view returns (uint256[] memory) {
        require(giveaways[giveawayId].isFulfilled, "GetWinners: draw not fulfilled");        
        require(giveaways[giveawayId].amountOfWinners > 0, "GetWinners: not a draw");        

        uint256[] memory expandedValues = new uint256[](giveaways[giveawayId].amountOfWinners);
        bool[] memory isNumberPicked = new bool[](giveaways[giveawayId].snapshotEntries);

        uint256 resultIndex;
        uint256 i;
        while (resultIndex < giveaways[giveawayId].amountOfWinners) {
            uint256 number = (uint256(keccak256(abi.encode(giveaways[giveawayId].randomNumber, i))) % giveaways[giveawayId].snapshotEntries) + 1;
            
            if(giveaways[giveawayId].allowDuplicates || !isNumberPicked[number-1]) {
                expandedValues[resultIndex] = number;
                isNumberPicked[number-1] = true;

                resultIndex++;
            }
            i++;
        }

        return expandedValues;
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }    

    /**
    * @notice initiate a new draw
    * 
    * @param _snapshotEntries the number of entries in the snapshot
    * @param _amountOfWinners the amount of winners to pick
    * @param _tokenId the token id which can be won
    * @param _contractAddress the contract address of the token
    * @param _entryListIpfsHash ipfs hash pointing to the list of entries
    * @param _allowDuplicates if true, a single entry is allowed to win multiple times
    * 
    */
    function startDraw(
        uint256 _snapshotEntries, 
        uint256 _amountOfWinners, 
        uint256 _tokenId, 
        address _contractAddress, 
        string memory _entryListIpfsHash, 
        bool _allowDuplicates, 
        uint256 _claimOpen, 
        uint256 _claimClose
    ) external onlyOwner returns (bytes32 requestId) {
        require(counter.current() == 0 || giveaways[counter.current()-1].isFulfilled, "Draw: previous draw not fulfilled");    
        require(_amountOfWinners < _snapshotEntries, "Draw: amount of winners must be smaller than number of entries");    
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );

        Giveaway storage d = giveaways[counter.current()];
        d.snapshotEntries = _snapshotEntries;
        d.amountOfWinners = _amountOfWinners;
        d.tokenId = _tokenId;     
        d.contractAddress = _contractAddress;
        d.entryListIpfsHash = _entryListIpfsHash;
        d.allowDuplicates = _allowDuplicates;
        d.claimOpen = _claimOpen;
        d.claimClose = _claimClose;

        counter.increment();

        return requestRandomness(keyHash, fee);
    }

    /**
    * @notice initiate a new giveaway
    * 
    * @param _tokenId the token id which can be won
    * @param _contractAddress the contract address of the token
    * @param _merkleRoot the merkle root to verify eligile claims
    */
    function startGiveaway(
        uint256 _tokenId, 
        address _contractAddress, 
        bytes32 _merkleRoot, 
        uint256 _claimOpen, 
        uint256 _claimClose
    ) external onlyOwner {
        require(counter.current() == 0 || giveaways[counter.current()-1].isFulfilled, "Giveaway: previous giveaway not fulfilled");    

        Giveaway storage d = giveaways[counter.current()];
        d.tokenId = _tokenId;     
        d.isFulfilled = true;
        d.contractAddress = _contractAddress;
        d.merkleRoot = _merkleRoot;
        d.claimOpen = _claimOpen;
        d.claimClose = _claimClose;

        counter.increment();
    }    

    /**
    * @notice claim tokens
    * 
    * @param amount the amount of tokens to claim
    * @param giveawayId the id of the token to claim
    * @param index the index of the merkle proof
    * @param maxAmount the max amount of tokens sender is eligible to claim
    * @param merkleProof the valid merkle proof of sender for given token id
    */
    function claim(
        uint256 amount,
        uint256 giveawayId,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(giveaways[giveawayId].claimed[msg.sender] + amount <= maxAmount, "Claim: Not allowed to claim given amount");
        require (block.timestamp >= giveaways[giveawayId].claimOpen && block.timestamp <= giveaways[giveawayId].claimClose, "Claim: time window closed");        

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, giveaways[giveawayId].merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        giveaways[giveawayId].claimed[msg.sender] = giveaways[giveawayId].claimed[msg.sender] + amount;

        IERC1155(giveaways[giveawayId].contractAddress).safeTransferFrom(address(this), msg.sender, giveaways[giveawayId].tokenId, amount, "");

        emit Claimed(giveaways[giveawayId].tokenId, msg.sender, amount);                
    }  

    /**
    * @notice withdraw ERC1155 tokens from contract
    * 
    * @param _contractAddress the contract address of the token
    * @param _tokenId the id of the token
    * @param _amount the amount of tokens
    */
    function withdrawTokens(address _contractAddress, uint256 _tokenId, uint256 _amount) external onlyOwner {
        IERC1155(_contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    /**
    * @notice pause claims
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice unpause claims
    */
    function unpause() external onlyOwner {
        _unpause();
    }   

    /**
    * @notice emergency function to force fulfillment
    * 
    * @param _giveawayId the id of the giveaway to fulfill
    */
    function forceFulfill(uint256 _giveawayId) external onlyOwner {
        giveaways[_giveawayId].isFulfilled = true;
    }       

    /**
    * @notice edit claim window for a specific giveaway
    * 
    * @param _giveawayId the id of the giveaway to edit
    * @param _claimOpen UNIX opening timestamp 
    * @param _claimClose UNIX closing timestamp 
    */
    function setClaimWindow(uint256 _giveawayId, uint256 _claimOpen, uint256 _claimClose) external onlyOwner {
        require(_giveawayId < counter.current(), "Draw id does not exist");

        giveaways[_giveawayId].claimOpen = _claimOpen;
        giveaways[_giveawayId].claimClose = _claimClose;
    }    

    /**
    * @notice return the number of tokens a given account 
    * has already claimed for a given draw
    * 
    * @param drawId the id of the draw
    * @param userAdress the address of the user
    */
    function getClaimedTokens(uint256 drawId, address userAdress) public view returns (uint256) {
        return giveaways[drawId].claimed[userAdress];
    }              

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        giveaways[counter.current()-1].randomNumber = randomness;
        giveaways[counter.current()-1].isFulfilled = true;
    }
   
}
