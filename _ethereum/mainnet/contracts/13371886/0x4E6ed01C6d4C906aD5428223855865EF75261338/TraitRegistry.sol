//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

/***
 *                                                                                               
 *    ████████ ██████   █████  ██ ████████     ██████  ███████  ██████  ██ ███████ ████████ ██████  ██    ██ 
 *       ██    ██   ██ ██   ██ ██    ██        ██   ██ ██      ██       ██ ██         ██    ██   ██  ██  ██  
 *       ██    ██████  ███████ ██    ██        ██████  █████   ██   ███ ██ ███████    ██    ██████    ████   
 *       ██    ██   ██ ██   ██ ██    ██        ██   ██ ██      ██    ██ ██      ██    ██    ██   ██    ██    
 *       ██    ██   ██ ██   ██ ██    ██        ██   ██ ███████  ██████  ██ ███████    ██    ██   ██    ██    
 *                                                                                                           
 *    DirtyRobot - Trait Registry                                                                            
 *                                                                                                           
 */

import "./Ownable.sol";
import "./EnumerableSet.sol"; 
 
contract TraitRegistry is Ownable {

    struct traitStruct {
        string  name;
        address implementer;     // address of the smart contract that will implement extra functionality
        uint8   traitType;       // 0 for normal, 1 for inverted, 2 for inverted range
        uint16  start;
        uint16  end;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;

    // token data
    mapping(uint16 => mapping(uint16 => uint8) ) public tokenData;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractController;

    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;

    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;


    /*
    *   Events
    */
    event contractControllerEvent(address _address, bool mode);
    event traitControllerEvent(address _address);
    
    // traits
    event newTraitEvent(string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end );
    event updateTraitEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitDataEvent(uint16 indexed _id);
    // tokens
    event tokenTraitChangeEvent(uint16 indexed _traitId, uint16 indexed _tokenId, bool mode);

    function addTrait(
        string[]    calldata _name,
        address[]   calldata _implementer,
        uint8[]     calldata _traitType,
        uint16[]    calldata _start,
        uint16[]    calldata _end
    ) public onlyAllowed {

        for (uint8 i = 0; i < _name.length; i++) {
            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.name = _name[i];
            newT.implementer = _implementer[i];
            newT.traitType = _traitType[i];
            newT.start = _start[i];
            newT.end = _end[i];

            emit newTraitEvent(_name[i], _implementer[i], _traitType[i], _start[i], _end[i] );
            if(_implementer[i] != address(0)) {
                setTraitControllerAccess(_implementer[i], newTraitId, true);
            }
            setTraitControllerAccess(owner(), newTraitId, true);
        }
    }

    function updateTrait(
        uint16 _traitId,
        string memory _name,
        address _implementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end
    ) public onlyAllowed {
        // set old to false
        setTraitControllerAccess(traits[_traitId].implementer, _traitId, false);

        traits[_traitId].name = _name;
        traits[_traitId].implementer = _implementer;
        traits[_traitId].traitType = _traitType;
        traits[_traitId].start = _start;
        traits[_traitId].end = _end;

        // set new to true
        setTraitControllerAccess(_implementer, _traitId, true);

        emit updateTraitEvent(_traitId, _name, _implementer, _traitType, _start, _end);
    }

    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) {
        _setTrait(traitID, tokenId, _value);
    }

    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) public onlyTraitController(traitID) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _setTrait(traitID, tokenIds[i], _value[i]);
        }
    }

    function _setTrait(uint16 traitID, uint16 tokenId, bool _value) internal {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
        } else {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
        }
        emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
    }

    // set trait data
    function setData(uint16 traitId, uint16[] calldata _ids, uint8[] calldata _data) public onlyAllowed {
        for (uint16 i = 0; i < _data.length; i++) {
            tokenData[traitId][_ids[i]] = _data[i];
        }
        updateTraitDataEvent(traitId);
    }

    /*
    *   View Methods
    */

    /*
    * _perPage = 1250 in order to load 10000 tokens ( 10000 / 8; starting from 0 )
    */
    function getData(uint16 traitId, uint8 _page, uint16 _perPage) public view returns (uint8[] memory) {
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues;
        assembly {
            mstore(retValues, _perPage)
        }
        while(i < max) {
            retValues[j] = tokenData[traitId][i];
            j++;
            i++;
        }
        
        assembly {
            // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize()) 
        }
        return retValues;
    }

    function getTokenData(uint16 tokenId) public view returns (uint8[] memory) {
        uint16 _traitCount = traitCount;
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < _traitCount) {
            _returnCount++;
        }

        uint16 i = 0;
        uint8[] memory retValues;
        assembly {
            // set dynamic memory array length
            mstore(retValues, _returnCount)
        }
        while(i < _returnCount) {
            retValues[i] = 0;
            i++;
        }
        assembly {
            // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize()) 
        }

        i = 0;
        
        // calculate positions for our token
        while(i < traitCount) {
            if(hasTrait(i, tokenId)) {
                uint8 byteNum = uint8(i / 8);
                uint8 bitPos = uint8(i - byteNum * 8);
                retValues[byteNum] = uint8(retValues[byteNum] | 2**bitPos);
            }
            i++;
        }
        return retValues;
    }


    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _traitCount = traitCount;
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < _traitCount) {
            _returnCount++;
        }
        uint8 i = 0;
        uint8[] memory retValues;
        assembly {
            // set dynamic memory array length
            mstore(retValues, _returnCount)
        }

        while(i < _returnCount) {
            retValues[i] = traitControllerAccess[_addr][i];
            i++;
        }
        
        assembly {
            // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize()) 
        }
        return retValues;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].implementer;
    }

    function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result)
    {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        bool _result = tokenData[traitID][byteNum] & (0x01 * 2**bitPos) != 0;
        bool _returnVal = (traits[traitID].traitType == 1) ? !_result: _result;
        if(traits[traitID].traitType == 2) {
            // range trait
            if(traits[traitID].start <= tokenId && tokenId <= traits[traitID].end) {
                _returnVal = !_result;
            }
        }
        return _returnVal;
    }

    /*
    *   Admin Stuff
    */

    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit contractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }
    
    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "Not Authorised"
        );
        _;
    }
}

