// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "./BitPanda.sol";
import "./SafeMath.sol";

// An extension to BitPanda, add a feature called reAssign
// follow the spirit of blockchain, holders of BitPanda NFT can vote to ask for a panda reassignment, each token corresponds to one voting right
// then two random numbers will be generated, and are used to reassign pandas for the all token holder
// since MAX_TOKENS < MAX_PANDAS, a reassignment may lead to new pandas with new traits
// reassignment will be automatically triggered by the smart contract when votes get past 50% of MAX_TOKENS
// to prevent unlimited number of reassignments, a voting fee needs to be paid for each vote
// voting fee gets started with 0.01 ETH / token, and then follow the formula: 0.01 * (2**(r-1)), r is the number of reassignment rounds

contract BitPandaExt is BitPanda {
    using SafeMath for uint256;

    uint256 private rand_seed = 0; //source of randomness for re-assignment
    uint256 public numRounds;
    uint256 public votingFee;
    uint256 public numTotalVotes; // count the number of votes for the current round
    uint256 public blockNumberReassigned; // recored the block number when last assignment ocurred;
    uint256 public constant numThreshold = 741; // the threshold: a reassign will be triggered if numTotalVotes >= numThreshold
    bool[MAX_TOKENS] public hasVoted; // indicate if a tokenId has voted for the current round

    constructor(string memory baseURI) BitPanda(baseURI) {
        numTotalVotes = 0;
        numRounds = 1;
        votingFee = 0;
        blockNumberReassigned = 0;
    }

    function canVoteOfToken(uint256 tokenId) public view returns (bool){
        require(isInitialPhaseEnd(), "BitPandaExt: voting is allowed after the initial phase of sale!");
        require(_exists(tokenId), "BitPanda: invalid query for nonexistent token");
        return !hasVoted[tokenId];
    }
    
    // return tokens with valid voting right this address has
    function tokensCanVoteOfAddress(address addr) public view returns (uint256[] memory){
        require(isInitialPhaseEnd(), "BitPandaExt: voting is allowed after the initial phase of sale!");

        uint256[] memory tokens = tokensOfOwner(addr);
        uint256 numTokens = tokens.length;
        uint256 numVotes = 0;
        
        for(uint256 i=0;i<numTokens;i++){
            if(!hasVoted[tokens[i]]){
                numVotes ++;
            }
        }
        if(numVotes == 0) return new uint256[](0);
        else{ 
            uint256[] memory tokensCanVote = new uint256[](numVotes);
            uint256 cnt = 0;
            for(uint256 i=0;i<numTokens;i++){
                if(!hasVoted[tokens[i]]){
                    tokensCanVote[cnt] = tokens[i];
                    cnt ++;
                }
            }
            return tokensCanVote;
        }
    }

    function tokensCanVoteOfIds(uint256[] memory ids, address addr) public view returns (uint256[] memory) {
        require(isInitialPhaseEnd(), "BitPandaExt: voting is allowed after the initial phase of sale!");

        uint256 numVotes = 0;
        uint256 numTokens = ids.length;
        for(uint256 i=0;i<numTokens;i++){
            if(_exists(ids[i]) && ownerOf(ids[i]) == addr && !hasVoted[ids[i]] ){
                numVotes ++;
            }
        }
        if(numVotes == 0) return new uint256[](0);
        else{ 
            uint256[] memory tokensCanVote =new uint256[](numVotes);
            uint256 cnt;
            for(uint256 i=0;i<numTokens;i++){
                if(_exists(ids[i]) && ownerOf(ids[i]) == addr && !hasVoted[ids[i]] ){
                    tokensCanVote[cnt] = ids[i];
                    cnt ++;
                }
            }
            return tokensCanVote;
        }
    }

    function voteFromTokenIds(uint256[] memory ids) public payable {
        require(isInitialPhaseEnd(), "BitPandaExt: voting is allowed after the initial phase of sale!");
        uint256[] memory tokensCanVote = tokensCanVoteOfIds(ids, msg.sender);
        uint256 numVotes = tokensCanVote.length;
        require(numVotes > 0, "BitPandaExt: this address does not have available votes!");
        require(msg.value >= numVotes.mul(votingFee), "BitPandaExt: low voting fee sent");
        _vote(numVotes, tokensCanVote);

    }

    // only the owner of token can vote, and all voting rights under ths address will be counted by default
    function voteFromAddress() public payable{
        require(isInitialPhaseEnd(), "BitPandaExt: voting is allowed after the initial phase of sale!");
        uint256[] memory tokensCanVote = tokensCanVoteOfAddress(msg.sender);
        uint256 numVotes = tokensCanVote.length;
        require(numVotes > 0, "BitPandaExt: this address does not have available votes!");
        require(msg.value >= numVotes.mul(votingFee), "BitPandaExt: low voting fee sent");
        _vote(numVotes, tokensCanVote);
    }

    function _vote(uint256 numVotes, uint256[] memory tokensCanVote) private {
        for(uint256 i=0;i<numVotes;i++){
            hasVoted[tokensCanVote[i]] = true;
            randForReassign(tokensCanVote[i]);
        }
        numTotalVotes = numTotalVotes.add(numVotes);

        // reassignment is triggered
        if(numTotalVotes >= numThreshold){
            reAssign();
        }
    }

    function randForReassign(uint256 tokenId) private returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, rand_seed)));
        rand_seed = randomNumber;
        return rand_seed;
    }

    function reAssign() private {
        blockNumberReassigned = block.number;
        if(votingFee == 0){
            votingFee = 10000000000000000;
        }else{
            votingFee =  votingFee.mul(2);
        }
        numRounds = numRounds.add(1); // update round number
        numTotalVotes = 0;
        delete hasVoted;

        // set randomness
        multiplier = rand_seed % (MAX_PANDAS-1) + 1;
        summand = randForReassign(rand_seed) % (MAX_PANDAS);
    }

}
