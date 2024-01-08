//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MiniStayPuft.sol";

/// @author Andrew Parker
/// @title GBA Viewer
/// @notice MiniStayPuft NFT periphery contract, for GBA website

contract GBAViewer {

    MiniStayPuft msp;                // MiniStayPuft main contract
    GBAWhitelist whitelist;          // GBA whitelist contract
    IGBATrapsPartial traps;              // GBA whitelist contract

    uint constant COOLDOWN = 10;    //Reserve cooldown block interval
    uint constant PRESALE_LIMIT = 2000;
    uint8 constant WHITELIST_RESERVE_LIMIT = 2;
    uint16 constant TOTAL_MOB_COUNT = 500;  //total number of mobs that can exist


    /// Constructor
    /// @param _msp Address of MiniStayPuft contract
    /// @param _whitelist Address of Whitelist contract
    /// @param _traps Address of GBATraps contract
    constructor(address _msp, address _traps, address _whitelist){
        msp = MiniStayPuft(_msp);
        whitelist = GBAWhitelist(_whitelist);
        traps = IGBATrapsPartial(_traps);
    }



    /// Can Reserve
    /// @notice Is a given address out of cooldown
    /// @param reservist Address to check
    /// @return Cooldown is over
    function canReserve(address reservist) public view returns(bool){
        (uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds) = msp.mintReserveState(reservist);
            _whitelistReserveCount;
            tokenIds;
        return blockNumber == 0 || block.number > uint(blockNumber) + COOLDOWN;
    }

    /// Reserved Count
    /// @notice Number of tokens that have been reserved
    function reservedCount() public view returns(uint){
        (uint _tokenCount, MiniStayPuft.Phase _phase, uint mobMax) = msp.contractState();
        _phase;


        //_tokenCount doesnt include caught mobs
        uint _reserved = _tokenCount;

        if( mobMax == 0){
            //all mobs caught
            _reserved += TOTAL_MOB_COUNT;
        }else if(mobMax > TOTAL_MOB_COUNT){
            //only a few left
            _reserved += TOTAL_MOB_COUNT;
        }else{
            //3 in motion
            _reserved += mobMax;
        }


        return _reserved - msp.totalSupply();

    }

    /// Can PreReserve
    /// @notice Can an address with given proof mint in PreReserve phase. Returns number remaining they can mint. (0 if not whitelisted)
    /// @param proof Merkle proof
    /// @param listee address to check
    /// @return Number tht can be minted
    function canPreReserve(bytes32[] memory proof, address listee) public view returns(uint){
        if (!whitelist.isWhitelisted(proof,listee) || reservedCount() >= PRESALE_LIMIT )return 0;

        (uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds) = msp.mintReserveState(listee);
        blockNumber;tokenIds;

        return WHITELIST_RESERVE_LIMIT - _whitelistReserveCount;
    }

    /// Can TrapMintWhitelisted
    /// @notice Can an address with given proof mint a trap. Returns false if not whitelisted or minted
    /// @param proof Merkle proof
    /// @param listee address to check
    /// @return Number tht can be minted
    function canTrapMintWhitelisted(bytes32[] memory proof, address listee) public view returns(bool){
        if (!whitelist.isWhitelisted(proof,listee)) return false;

        return !traps.hasMinted(listee);
    }

    /// Can TrapMintPublic
    /// @notice Can an address with given proof mint a trap. Returns false if not public  or has minted
    /// @param minter address to check
    /// @return Number tht can be minted
    function canTrapMintPublic(address minter) public view returns(bool){
        if(
            !traps.saleStarted() ||
            traps.whitelistEndTime() > block.timestamp
        ){
            return false;
        }

        return !traps.hasMinted(minter);
    }





    /// Countdown
    /// @notice Gets current countdown state, and also inferred pause state.
    /// @return counting False if paused, or if not a phase with a countdown
    /// @return time Time in secs until countdown ends (always 0 if not counting)
    function countdown() public view returns(bool counting, uint time){
        (uint _tokenCount, MiniStayPuft.Phase _phase, uint mobMax) = msp.contractState();
        _tokenCount; mobMax;

       (bool _paused,uint _startTime,uint _pauseTime) = msp.pauseState();
        _startTime;_pauseTime;

        if(_paused){
            return (false,0);
        }
        if(_phase == MiniStayPuft.Phase.Init){
            return(false,0);
        }else if(_phase == MiniStayPuft.Phase.PreReserve){
            return(true,_startTime + 2 hours - block.timestamp);
        }else if(_phase == MiniStayPuft.Phase.Reserve){
            return(true,_startTime + 1 days + 2 hours - block.timestamp);
        }else{
            return(false,0);
        }
    }

    /// Contract Sub State
    /// @dev just a way of getting some vars for Contract State and not hitting stack too deep
    function contractSubState() public view returns (MiniStayPuft.Phase _phase, bool _paused){
        uint _tokenCount; uint mobMax;
        (_tokenCount, _phase, mobMax) = msp.contractState();
        _tokenCount;mobMax;
        uint _startTime;
        uint _pauseTime;
        (_paused, _startTime, _pauseTime) = msp.pauseState();
        _startTime;_pauseTime;

        return (_phase,_paused);
    }

    /// Contract State
    /// @notice Gets current contract state, for initial page load.
    /// @return _totalSupply Total supply of minted MSPs
    /// @return reserved Number of reserved, unclaimed MSPs
    /// @return _phase current phase
    /// @return _counting False if paused, or if not a phase with a countdown
    /// @return _time Time in secs until countdown ends (always 0 if not counting)
    /// @return _paused Is currently paused
    /// @return trapsSupply Number of traps that exist
    /// @return trapsMintState Current mint state for traps contract
    /// @return blockNumber current block number
    function contractState() public view returns(uint _totalSupply, uint reserved, MiniStayPuft.Phase _phase, bool _counting, uint _time, bool _paused, uint trapsSupply, IGBATrapsPartial.State trapsMintState, uint blockNumber){
        (_counting, _time) = countdown();
        (_phase,_paused) = contractSubState();

        return (
            msp.totalSupply(),

            reservedCount(),
            _phase,

            _counting, _time,_paused,
            traps.totalSupply(),
            traps.mintState(),
        block.number);
    }

    /// My State
    /// @notice Gets current contract state, specific to msg.sender
    /// @param merkleProof Merkle proof for msg.sender if listee
    /// @return myBalance Number of Ronins owned
    /// @return myReserved number of reserved, unclaimed MSP
    /// @return cooldown Block number of last reservation
    /// @return _canPreReserve Can PreReserve
    /// @return _canReserve Can Reserve
    /// @return myMobs Array of mobs currently in msg.sender's wallet
    /// @return blockNumber current block number
    function myState(bytes32[] memory merkleProof) public view returns(uint myBalance, uint myReserved, uint cooldown, uint _canPreReserve, bool _canReserve, uint[3] memory myMobs, uint blockNumber){
        (uint8 _whitelistReserveCount, uint24 _cooldown, uint16[] memory _tokenIds) = msp.mintReserveState(msg.sender);
        _whitelistReserveCount;

        myMobs;
        for(uint i = 0; i < 3; i++){
            try msp.getMobTokenId(i) returns (uint _tokenId) {
                try msp.ownerOf(_tokenId) returns (address owner) {
                    if(owner == msg.sender){
                        myMobs[i] = _tokenId;
                    }
                }catch{
                    myMobs[i] = 0;
                }
            } catch {
                myMobs[i] = 0;
            }
        }


        return (msp.balanceOf(msg.sender),
        _tokenIds.length,
        _cooldown,
        canPreReserve(merkleProof,msg.sender),
        canReserve(msg.sender),
        myMobs,
        block.number);
    }

    /// My Trap State
    /// @notice Gets current trap contract state, specific to msg.sender
    /// @param merkleProof Merkle proof for msg.sender if listee
    /// @return myBalance Number of Ronins owned
    /// @return _canTrapMintWhitelisted Can Trap Mint whitelisted
    /// @return _canTrapMintPublic Can Trap mint public
    /// @return blockNumber current block number
    function myTrapState(bytes32[] memory merkleProof) public view returns(uint myBalance, bool _canTrapMintWhitelisted,bool _canTrapMintPublic, uint blockNumber){

        return (traps.balanceOf(msg.sender),
        canTrapMintWhitelisted(merkleProof,msg.sender),
        canTrapMintPublic(msg.sender),
        block.number);
    }
}