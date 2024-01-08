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
* @title Contract for BlootDrip giveaways using Chainlink VRF 
*/
contract BlootDripGiveaway is VRFConsumerBase, ERC1155Holder, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    address contractAddress;

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(uint256 => Draw) public draws;

    event Claimed(uint indexed index, address indexed account, uint amount);

    struct Draw {
        uint256 amountOfWinners;        
        uint256 randomNumber;
        uint256 tokenId;
        bool isFulfilled;
        mapping(address => uint256) claimed;
        bytes32 merkleRoot;
        uint256 claimOpens;
        uint256 claimCloses;
    }

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        address _contractAddress
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;

        contractAddress = _contractAddress;
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
        require(draws[_drawId].isFulfilled, "setMerkleRoot: draw not fulfilled");

        draws[_drawId].merkleRoot = _merkleRoot;
    } 

    /**
    * @notice return all winning entries for a given draw
    * 
    * @param drawId the draw id to return winners for
    */
    function getWinners(uint256 drawId) external view returns (uint256[] memory) {
        require(draws[drawId].isFulfilled, "GetWinners: draw not fulfilled");        

        uint256[] memory expandedValues = new uint256[](draws[drawId].amountOfWinners);
        bool[] memory isNumberPicked = new bool[](8008);

        uint256 resultIndex;
        uint256 i;
        while (resultIndex < draws[drawId].amountOfWinners) {
            uint256 number = (uint256(keccak256(abi.encode(draws[drawId].randomNumber, i))) % 8008) + 1;
            
            if(!isNumberPicked[number-1]) {
                expandedValues[resultIndex] = number;
                isNumberPicked[number-1] = true;

                resultIndex++;
            }
            i++;
        }

        return expandedValues;
    } 

    /**
    * @notice initiate a new draw
    * 
    * @param _amountOfWinners the amount of winners to pick
    * @param _tokenId the token id which can be won
    * 
    */
    function draw(uint256 _amountOfWinners, uint256 _tokenId, uint256 _claimOpens, uint256 _claimCloses) external onlyOwner returns (bytes32 requestId) {
        require(counter.current() == 0 || draws[counter.current()-1].isFulfilled, "Draw: previous draw not fulfilled");    
        require(_amountOfWinners <= 8008, "Draw: amount of winners must be smaller than number of entries");    
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract"
        );

        Draw storage d = draws[counter.current()];
        d.amountOfWinners = _amountOfWinners;
        d.tokenId = _tokenId;    
        d.claimOpens = _claimOpens;
        d.claimCloses = _claimCloses; 

        counter.increment();

        return requestRandomness(keyHash, fee);
    }

    /**
    * @notice claim tokens
    * 
    * @param amount the amount of tokens to claim
    * @param drawId the id of the token to claim
    * @param index the index of the merkle proof
    * @param maxAmount the max amount of tokens sender is eligible to claim
    * @param merkleProof the valid merkle proof of sender for given token id
    */
    function claim(
        uint256 amount,
        uint256 drawId,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(draws[drawId].claimed[msg.sender] + amount <= maxAmount, "Claim: Not allowed to claim given amount");
        require (block.timestamp >= draws[drawId].claimOpens && block.timestamp <= draws[drawId].claimCloses, "Claim: window closed");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));
        require(
            MerkleProof.verify(merkleProof, draws[drawId].merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        draws[drawId].claimed[msg.sender] = draws[drawId].claimed[msg.sender] + amount;

        IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, draws[drawId].tokenId, amount, "");

        emit Claimed(draws[drawId].tokenId, msg.sender, amount);                
    }  

    /**
    * @notice withdraw ERC1155 tokens from contract
    * 
    * @param _tokenId the id of the token
    * @param _amount the amount of tokens
    */
    function withdrawTokens(uint256 _tokenId, uint256 _amount) external onlyOwner {
        IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }       

    function setClaimWindow(uint256 _drawId, uint256 _claimOpens, uint256 _claimCloses) external onlyOwner {
        require(_drawId < counter.current(), "Draw id does not exist");

        draws[_drawId].claimOpens = _claimOpens;
        draws[_drawId].claimCloses = _claimCloses;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }     

    function getClaimedTokens(uint256 drawId, address userAdress) public view returns (uint256) {
        return draws[drawId].claimed[userAdress];
    }      

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        draws[counter.current()-1].randomNumber = randomness;
        draws[counter.current()-1].isFulfilled = true;
    }
   
}
