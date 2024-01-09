//SPDX-License-Identifier: A hedgehog wrote this contract
pragma solidity ^0.8.0;
import "./Doomsday.sol";

contract DoomsdayViewer{

    Doomsday doomsday;

    uint constant IMPACT_BLOCK_INTERVAL = 120;

    constructor(address _doomsday){
        doomsday = Doomsday(_doomsday);
    }

    function isEarlyAccess() public view returns(bool){
        return doomsday.stage() == Doomsday.Stage.PreApocalypse && block.timestamp < doomsday.startTime() + 1 days;
    }

    function nextImpactIn() public view returns(uint){
        uint nextEliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) - 5 + IMPACT_BLOCK_INTERVAL;
        return nextEliminationBlock - block.number;
    }


    function contractState() public view returns(
            uint totalSupply,
            uint destroyed,
            uint evacuatedFunds,
            Doomsday.Stage stage,
            uint currentPrize,
            bool _isEarlyAccess,
            uint countdown,
            uint _nextImpactIn,
            uint blockNumber
    ){
        stage = doomsday.stage();

        _isEarlyAccess = isEarlyAccess();

        if(_isEarlyAccess){
            countdown = doomsday.startTime() + 1 days - block.timestamp;
        }else if(stage == Doomsday.Stage.PreApocalypse){
            countdown = doomsday.startTime() + 7 days - block.timestamp;
        }

        return (
            doomsday.totalSupply(),
            doomsday.destroyed(),
            doomsday.evacuatedFunds(),
            stage,
            doomsday.currentPrize(),
            _isEarlyAccess,
            countdown,
            nextImpactIn(),
            block.number
        );
    }

    function vulnerableCities(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = doomsday.totalSupply();
        uint _maxId = _totalSupply + doomsday.destroyed();
        if(_totalSupply == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        uint _tokenId = startId;
        for(uint i = 0; i < sampleSize; i++){
            try doomsday.ownerOf(_tokenId) returns (address _owner) {
                _owner;
                try doomsday.isVulnerable(_tokenId) returns (bool _isVulnerable) {
                    if(_isVulnerable){
                        _tokenIds[i] = _tokenId;
                    }
                } catch {

                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }

    function cityData(uint startId, uint limit) public view returns(uint[] memory _tokenIds, uint[] memory _cityIds, uint[] memory _reinforcement, uint[] memory _damage, uint blockNumber ){
        uint _totalSupply = doomsday.totalSupply();
        uint _maxId = _totalSupply + doomsday.destroyed();
        if(_totalSupply == 0){
            uint[] memory _none;
            return (_none,_none,_none,_none, block.number);
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        _tokenIds     = new uint256[](sampleSize);
        _cityIds      = new uint256[](sampleSize);
        _reinforcement = new uint256[](sampleSize);
        _damage        = new uint256[](sampleSize);


        uint _tokenId = startId;
        uint8 reinforcement; uint8 damage; bytes32 lastImpact;

        for(uint i = 0; i < sampleSize; i++){
            try doomsday.ownerOf(_tokenId) returns (address owner) {
                owner;
                _tokenIds[i] = _tokenId;

                (reinforcement, damage, lastImpact) = doomsday.getStructuralData(_tokenId);

                _cityIds[i]         = doomsday.tokenToCity(_tokenId);
                _reinforcement[i]    = reinforcement;
                _damage[i]           = damage;

            } catch {

            }
            _tokenId++;
        }
        return (_tokenIds, _cityIds, _reinforcement, _damage, block.number);
    }

    function cities(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = doomsday.totalSupply();
        uint _maxId = _totalSupply + doomsday.destroyed();
        if(_totalSupply == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }
        uint[] memory _tokenIds = new uint256[](sampleSize);
        uint _tokenId = startId;
        for(uint i = 0; i < sampleSize; i++){
            try doomsday.ownerOf(_tokenId) returns (address owner) {
                owner;
                _tokenIds[i] = _tokenId;
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }

    function bunker(uint16 _cityId) public view returns(uint _tokenId, address _owner, uint8 _reinforcement, uint8 _damage, bool _isVulnerable, bool _isUninhabited){
        _tokenId = doomsday.cityToToken(_cityId);
        _isUninhabited = doomsday.isUninhabited(_cityId);

        if(_tokenId == 0){
            return (0,address(0),uint8(0),uint8(0),false,_isUninhabited);
        }else{
            try doomsday.ownerOf(_tokenId) returns ( address __owner) {
                _owner = __owner;
            } catch {

            }
            bytes32 _lastImpact;
            (_reinforcement, _damage, _lastImpact) = doomsday.getStructuralData(_tokenId);
            _isVulnerable = doomsday.isVulnerable(_tokenId);

            return (_tokenId,_owner,_reinforcement, _damage,_isVulnerable,false);
        }
    }

    function myCities(uint startId, uint limit)  public view returns(uint[] memory){
        uint _totalSupply = doomsday.totalSupply();
        uint _myBalance = doomsday.balanceOf(msg.sender);
        uint _maxId = _totalSupply + doomsday.destroyed();
        if(_totalSupply == 0 || _myBalance == 0){
            uint[] memory _none;
            return _none;
        }
        require(startId < _maxId + 1,"Invalid start ID");
        uint sampleSize = _maxId - startId + 1;

        if(limit != 0 && sampleSize > limit){
            sampleSize = limit;
        }

        uint[] memory _tokenIds = new uint256[](sampleSize);

        uint _tokenId = startId;
        uint found = 0;
        for(uint i = 0; i < sampleSize; i++){
            try doomsday.ownerOf(_tokenId) returns (address owner) {
                if(msg.sender == owner){
                    _tokenIds[found++] = _tokenId;
                }
            } catch {

            }
            _tokenId++;
        }
        return _tokenIds;
    }
}


// Like the food not the animal