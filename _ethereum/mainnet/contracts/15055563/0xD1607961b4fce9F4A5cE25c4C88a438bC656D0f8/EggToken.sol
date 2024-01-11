// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./DragonInfo.sol";
import "./EggInfo.sol";
import "./GenesLib.sol";
import "./BaseAccessControl.sol";
import "./DragonCreator.sol";

contract EggToken is ERC721, BaseAccessControl {

    using Counters for Counters.Counter;

    string public constant BAD_ARGS_ERROR = "EggToken: inconsistent constructor arguments";
    string public constant NOT_ENOUGH_PRIVILEGES_ERROR = "EggToken: not enough privileges to call the method";
    string public constant EGG_EXISTS_ERROR = "EggToken: an egg with such ID already exists";
    string public constant BAD_CID_ERROR = "EggToken: bad CID";
    string public constant CIDS_SET_ERROR = "EggToken: CIDs are already set";
    string public constant NONEXISTENT_TOKEN_ERROR = "EggToken: nonexistent token";
    string public constant SUPPLY_EXCEEDED_ERROR = "EggToken: supply is exceeded";
    string public constant TOTAL_SUPPLY_EXCEEDED_ERROR = "EggToken: total supply for the given dragon type is exceeded";
    string public constant BAD_ADDRESS_ERROR = "EggToken: wrong address";
    string public constant BAD_DRAGON_TYPE_ERROR = "EggToken: wrong dragon type";

    Counters.Counter private _tokenIds;

    mapping(uint => uint) private _info;
    mapping(uint => string) private _cids;
    mapping(uint => string) private _hatchCids;

    mapping(DragonInfo.Types => uint) private _randomDragonSupply;
    mapping(DragonInfo.Types => uint) private _totalEggSupply;
    mapping(DragonInfo.Types => uint) private _eggCounts;

    mapping(bytes32 => uint) private _requestData;

    uint internal _totalSupply;
    
    uint internal _hatchTime;
    address internal _eggHatcherAddress;
    address internal _dragonCreatorAddress;
    address internal _eggMarketAddress;
    address internal _eggReplicatorAddress;

    string private _defaultMetadataCid;
    
    GenesLib.GenesRange private COMMON_RANGE;
    GenesLib.GenesRange private RARE_RANGE;
    GenesLib.GenesRange private EPIC_RANGE;

    event EggHatched(address indexed operator, uint eggId, uint dragonId);
    
    constructor(
        uint totalEggSply,
        uint totalEpic20EggSply,
        uint totalLegendaryEggSply,
        uint randomLegendaryDragonSply, 
        uint randomEpic20DragonSply, 
        uint randomCommonDragonSply, 
        uint htchTime,
        string memory defaultCid,
        address accessControl,
        address dragonCreator)
        ERC721("CryptoDragons Eggs", "CDE") 
        BaseAccessControl(accessControl) {
        
        uint totalRandomEggSupply = 
            randomLegendaryDragonSply + randomEpic20DragonSply + randomCommonDragonSply;
        require(totalEggSply == totalEpic20EggSply + totalLegendaryEggSply + totalRandomEggSupply, 
            BAD_ARGS_ERROR);
        
        _totalSupply = totalEggSply;

        _totalEggSupply[DragonInfo.Types.Unknown] = totalRandomEggSupply;
        _totalEggSupply[DragonInfo.Types.Epic20] = totalEpic20EggSply;
        _totalEggSupply[DragonInfo.Types.Legendary] = totalLegendaryEggSply;
        
        _randomDragonSupply[DragonInfo.Types.Legendary] = randomLegendaryDragonSply;
        _randomDragonSupply[DragonInfo.Types.Epic20] = randomEpic20DragonSply;
        _randomDragonSupply[DragonInfo.Types.Common] = randomCommonDragonSply;

        _hatchTime = htchTime; 
        _defaultMetadataCid = defaultCid;

        _dragonCreatorAddress = dragonCreator;

        COMMON_RANGE = GenesLib.GenesRange({from: 0, to: 15});
        RARE_RANGE = GenesLib.GenesRange({from: 15, to: 20});
        EPIC_RANGE = GenesLib.GenesRange({from: 20, to: 25});
    }

    function initialize(
        uint eggSeed,
        uint uknownEggCnt,
        uint epic20EggCnt,
        uint legendaryEggCnt) external onlyRole(COO_ROLE) {
        _tokenIds = Counters.Counter({ _value: eggSeed });
        
        _eggCounts[DragonInfo.Types.Unknown] = uknownEggCnt;
        _eggCounts[DragonInfo.Types.Epic20] = epic20EggCnt;
        _eggCounts[DragonInfo.Types.Legendary] = legendaryEggCnt;
    }

    function approveAndCall(address spender, uint256 tokenId, bytes calldata extraData) 
    external 
    returns (bool success) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        _approve(spender, tokenId);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                tokenId, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert("EggToken: spender internal error"); 
        }
        return true;
    }

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function totalEggSupply(DragonInfo.Types drgType) public view returns(uint) {
        return _totalEggSupply[drgType];
    }

    function randomDragonSupply(DragonInfo.Types drgType) external view returns(uint) {
        return _randomDragonSupply[drgType];
    }

    function currentEggCount(DragonInfo.Types drgType) public view returns(uint) {
        return _eggCounts[drgType];
    }

    function defaultMetadataCid() public view returns (string memory) {
        return _defaultMetadataCid;
    }

    function setDefaultMetadataCid(string calldata newDefaultCid) external onlyRole(COO_ROLE) {
        _defaultMetadataCid = newDefaultCid;
    }

    function setMetadataCids(uint tokenId, string calldata cid, string calldata hatchCid) 
    external onlyRole(COO_ROLE) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        require(bytes(cid).length >= 46 && bytes(hatchCid).length >= 46, BAD_CID_ERROR);
        require(bytes(_hatchCids[tokenId]).length == 0, CIDS_SET_ERROR);

        _cids[tokenId] = cid;
        _hatchCids[tokenId] = hatchCid;
    }

    function hasMetadataCids(uint tokenId) public view returns(bool) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        return bytes(_hatchCids[tokenId]).length > 0;
    }

    function hatchTime() public view returns(uint) {
        return _hatchTime;
    }

    function setHatchTime(uint newValue) external onlyRole(COO_ROLE) {
        uint previousValue = _hatchTime;
        _hatchTime = newValue;
        emit ValueChanged("hatchTime", previousValue, newValue);
    }

    function eggHatcherAddress() public view returns(address) {
        return _eggHatcherAddress;
    }

    function setEggHatcherAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _eggHatcherAddress;
        _eggHatcherAddress = newAddress;
        emit AddressChanged("eggHatcher", previousAddress, newAddress);
    }

    function dragonCreatorAddress() public view returns(address) {
        return _dragonCreatorAddress;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _dragonCreatorAddress;
        _dragonCreatorAddress = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function eggMarketAddress() public view returns(address) {
        return _eggMarketAddress;
    }

    function setEggMarketAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _eggMarketAddress;
        _eggMarketAddress = newAddress;
        emit AddressChanged("eggMarket", previousAddress, newAddress);
    }

    function eggReplicatorAddress() public view returns(address) {
        return _eggReplicatorAddress;
    }

    function setEggReplicatorAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _eggReplicatorAddress;
        _eggReplicatorAddress = newAddress;
        emit AddressChanged("eggReplicator", previousAddress, newAddress);
    }

    function canHatch(uint tokenId) external view returns(bool) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return _canHatch(info);
    }

    function isHatched(uint tokenId) external view returns(bool) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return info.hatchedAt > 0;
    }

    function eggInfo(uint tokenId) public view returns(EggInfo.Details memory) {
        require(_exists(tokenId), NONEXISTENT_TOKEN_ERROR);
        return EggInfo.getDetails(_info[tokenId]);
    }

    function _canHatch(EggInfo.Details memory info) internal view returns(bool) {
        return info.hatchedAt == 0 && block.timestamp >= hatchTime();
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        EggInfo.Details memory info = eggInfo(tokenId);
        return string(abi.encodePacked("ipfs://", (info.hatchedAt > 0) ? _hatchCids[tokenId] : _cids[tokenId]));
    }

    function mint(address to, DragonInfo.Types _dragonType) external returns (uint) {
        require(_tokenIds.current() < totalSupply(), SUPPLY_EXCEEDED_ERROR);
        require(hasRole(CEO_ROLE, _msgSender()) || _msgSender() == eggMarketAddress(), 
            NOT_ENOUGH_PRIVILEGES_ERROR);
        require(to != address(0), BAD_ADDRESS_ERROR);

        require(_dragonType == DragonInfo.Types.Epic20 
            || _dragonType == DragonInfo.Types.Legendary 
            || _dragonType == DragonInfo.Types.Unknown, BAD_DRAGON_TYPE_ERROR);
        
        require(currentEggCount(_dragonType) < totalEggSupply(_dragonType), 
            TOTAL_SUPPLY_EXCEEDED_ERROR);
        
        _eggCounts[_dragonType]++;
        _tokenIds.increment();
        
        uint newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        
        _info[newTokenId] = EggInfo.getValue(EggInfo.Details({
            mintedAt: block.timestamp,
            dragonType: _dragonType,
            hatchedAt: 0,
            dragonId: 0
        }));
        _cids[newTokenId] = defaultMetadataCid();

        return newTokenId;
    }

    function mintReplica(
        address to, uint eggId, uint value, string memory cid, string memory hatchCid) 
        external returns (uint) {
        require(_msgSender() == eggReplicatorAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        require(_info[eggId] == 0, EGG_EXISTS_ERROR);

        _mint(to, eggId);

        _info[eggId] = value;
        _cids[eggId] = cid;
        _hatchCids[eggId] = hatchCid;

        return eggId;
    }

    function hatch(uint tokenId, DragonInfo.Types dragonType, uint genes, address to) external {
        require(_msgSender() == eggHatcherAddress(), NOT_ENOUGH_PRIVILEGES_ERROR);
        
        EggInfo.Details memory info = eggInfo(tokenId);
        if (info.dragonType == DragonInfo.Types.Unknown) {
            _randomDragonSupply[dragonType]--;
        }

        uint newDragonId = DragonCreator(dragonCreatorAddress())
            .giveBirth(tokenId, genes, to);

        info.hatchedAt = block.timestamp;
        info.dragonId = newDragonId;
        _info[tokenId] = EggInfo.getValue(info);

        emit EggHatched(to, tokenId, newDragonId);
    }
}