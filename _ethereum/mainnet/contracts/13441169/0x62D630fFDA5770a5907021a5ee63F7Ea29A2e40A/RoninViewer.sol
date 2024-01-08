//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ronin.sol";

/// @author Andrew Parker
/// @title OniRonin Viewer
/// @notice OniRonin NFT periphery contract, for OniRonin website

contract RoninViewer {

    Ronin ronin;                // Ronin main contract
    RoninWhitelist whitelist;   // Ronin whitelist contract

    uint constant COOLDOWN = 10;    //Reserve cooldown block interval

    /// Constructor
    /// @param _ronin Address of Ronin contra
    /// @param _whitelist Address of Whitelist contract
    constructor(address _ronin, address _whitelist){
        ronin = Ronin(_ronin);
        whitelist = RoninWhitelist(_whitelist);
    }


    /// Can Reserve
    /// @notice Is a given address out of cooldown
    /// @param reservist Address to check
    /// @return Cooldown is over
    function canReserve(address reservist) public view returns(bool){
        (uint24 blockNumber, uint16[] memory tokens) = ronin.reservation(reservist);
        tokens;
        return blockNumber == 0 || block.number > uint(blockNumber) + COOLDOWN;
    }

    /// Can Cat Mint
    /// @notice Can an address with given proof mint in Cat phase. Returns false if they have already done it.
    /// @param proof Merkle proof
    /// @param catOwner address to check
    /// @return Can mint
    function canCatMint(bytes32[] memory proof, address catOwner) public view returns(bool){
        return (
            !ronin.catMinted(catOwner)
                &&
            whitelist.isWhitelisted(proof,catOwner)
        );
    }

    /// Countdown
    /// @notice Gets current countdown state, and also inferred pause state.
    /// @return counting False if paused, or if not a phase with a countdown
    /// @return time Time in secs until countdown ends (always 0 if not counting)
    function countdown() public view returns(bool counting, uint time){
        Ronin.Phase _phase = ronin.phase();
        (bool _paused,bool _unpausable,uint _startTime,uint _pauseTime) = ronin.pauseState();
        _unpausable;_startTime;_pauseTime;

        if(_paused){
            return (false,0);
        }
        if(_phase == Ronin.Phase.Init){
            return(false,0);
        }else if(_phase == Ronin.Phase.Cat){
            return(true,_startTime + 1 days - block.timestamp);
        }else if(_phase == Ronin.Phase.Reserve){
            return(true,_startTime + 2 days - block.timestamp);
        }else if(_phase == Ronin.Phase.Claim){
            return(false,0);
        }else{
            return(false,0);
        }
    }

    /// Contract State
    /// @notice Gets current contract state, for initial page load.
    /// @return roninCount Total supply of minted ronins
    /// @return reserved Number of reserved, unclaimed Ronins
    /// @return phase current phase
    /// @return counting False if paused, or if not a phase with a countdown
    /// @return time Time in secs until countdown ends (always 0 if not counting)
    /// @return paused Is currently paused
    /// @return blockNumber current block number
    function contractState() public view returns(uint roninCount, uint reserved, Ronin.Phase phase, bool counting, uint time, bool paused, uint blockNumber){
        uint _totalSupply = ronin.totalSupply();
        uint token_count = ronin.tokenCount();
        uint _reserved = token_count - _totalSupply;
        (bool _counting, uint _time) = countdown();
        (bool _paused,bool _unpausable,uint _startTime,uint _pauseTime) = ronin.pauseState();
        _unpausable;_startTime;_pauseTime;

        return (_totalSupply, _reserved,ronin.phase(),_counting, _time,_paused, block.number);
    }

    /// My State
    /// @notice Gets current contract state, specific to msg.sender
    /// @param merkleProof Merkle proof for msg.sender if cat owner
    /// @return myBalance Number of Ronins owned
    /// @return myReserved number of reserved, unclaimed Ronin
    /// @return cooldown Block number of last reservation
    /// @return _canCatMint Can Cat Mint
    /// @return _canReserve Can Reserve
    /// @return blockNumber current block number
    function myState(bytes32[] memory merkleProof) public view returns(uint myBalance, uint myReserved, uint cooldown, bool _canCatMint, bool _canReserve, uint blockNumber){
        (uint _cooldown, uint16[] memory _tokens) = ronin.reservation(msg.sender);

        return (ronin.balanceOf(msg.sender),
            _tokens.length,
            _cooldown,
            canCatMint(merkleProof,msg.sender),
            canReserve(msg.sender),
            block.number);
    }

    /// Ronins
    /// @notice Paginated function for tokenIds of existing Ronin
    /// @param start_index Search start index
    /// @param limit Max number to return
    /// @return Array of Token IDs
    function ronins(uint start_index, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = ronin.totalSupply();
        if(_totalSupply == 0){
            uint[] memory _none;
            return _none;
        }
        require(start_index < _totalSupply,"Invalid start index");
        uint sampleSize = _totalSupply - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        for(uint i = 0; i < sampleSize; i++){
            _tokenIds[i] = ronin.tokenByIndex(i + start_index);
        }
        return _tokenIds;
    }

    /// My Ronins
    /// @notice Paginated function for tokenIds of existing Ronin owned by msg.sender
    /// @param start_index Search start index
    /// @param limit Max number to return
    /// @return Array of Token IDs
    function myRonins(uint start_index, uint limit)  public view returns(uint[] memory){
        uint _balance = ronin.balanceOf(msg.sender);
        if(_balance == 0){
            uint[] memory _none;
            return _none;
        }
        require(start_index < _balance,"Invalid start index");
        uint sampleSize = _balance - start_index;
        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        for(uint i = 0; i < sampleSize; i++){
            _tokenIds[i] = ronin.tokenOfOwnerByIndex(msg.sender,i + start_index);
        }
        return _tokenIds;
    }

}