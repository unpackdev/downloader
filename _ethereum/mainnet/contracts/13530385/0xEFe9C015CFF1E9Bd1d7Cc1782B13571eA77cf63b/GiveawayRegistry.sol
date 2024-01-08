// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC721.sol";
import "./IRNG.sol";
import "./EnumerableBitSetAddOnly.sol";
import "./console.sol";

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface TokenSetGeneric {

    function name() external view returns (bytes32);
    function size(uint16 _permille) external view returns (uint256);
    function get(uint32 _pos, uint16 _permille) external view returns (uint16);

    function actualSize() external view returns (uint16);
    function start() external view returns (uint16);
    function end() external view returns (uint16);
    function setType() external view returns (uint8);    
}

interface GenericGiveawayDistributor {
    function fulfill(address receiver) external returns (uint256);
}

contract GiveawayRegistry is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableBitSetAddOnly for EnumerableBitSetAddOnly.Uint16BitSet;

    struct SelectionSetStruct {
        bytes32 _name;
        address _address;
        uint8   _state;
    }
    mapping(uint256 => SelectionSetStruct) public selectionSets;
                                   uint256 public selectionSetCount = 0;

    struct GiveawayStruct {
        bytes32     _name;
        address     _distributor;
        uint16      _winnerCount;
        bool        _started;
        bool        _processed;
        bytes32     _hash;
        uint8       _setLength;
        uint256     _random;
        uint256     _totalSize;
        uint256[]   _setSizes;
        uint256[]   _setOffsets;
    }

    mapping(uint16 => GiveawayStruct)              giveaways;
    mapping(uint16 => uint16[])                    giveawaySetIds;
    mapping(uint16 => uint16[])                    giveawaySetPermilles;
    mapping(bytes32 => uint16)              public hashToGiveawayId;
                                     uint16 public giveawayCount = 0;
                                       IRNG public rnd;
                                     ERC721 public nft;

    EnumerableSet.AddressSet                       contractController;

    mapping(uint16 => EnumerableBitSetAddOnly.Uint16BitSet) internal winnerData;
    mapping(uint16 => EnumerableBitSetAddOnly.Uint16BitSet) internal claimData;

    uint8 constant public MAX_SETS_PER_GIVEAWAY = 12;

    event contractControllerEvent(address _address, bool mode);
    event giveawayNew(uint16 id);
    event giveawayStart(uint16 id);
    event giveawayProcess(uint16 id);
    event giveawayWinners(uint16 id);
    event Claimed(uint16 _giveawayId, uint16 tokenId, uint256 resultId);

    constructor(
                address _rndContractAddress,
                address _ECNFT
    ) {
        rnd = IRNG(_rndContractAddress);
        nft = ERC721(_ECNFT);
    }

    /**
     * @notice Add a selection set that can be used by giveaways
     */
    function addSelectionSet(bytes32[] memory _name, address[] memory _addr) public onlyAllowed {

        for(uint8 i = 0; i < _name.length; i++) {
            require(_addr[i] != address(0), "GiveawayRegistry: SelectionSet address cannot be 0");
            SelectionSetStruct storage p = selectionSets[++selectionSetCount];
            p._name = _name[i];
            p._address = _addr[i];
            p._state = 1;
        }
    }

    /**
     * @notice Create a giveaway that uses some sets
     */
    function createGiveaway(
            bytes32 _name, 
            uint16[] calldata _setIds,
            uint16 _winnerCount,
            address _distributor,
            uint16[] calldata _permilles
        ) 
            public
            onlyAllowed
        {

        uint8 set_length = uint8(_setIds.length);
        require(set_length > 0, "GiveawayRegistry: At least 1 set required.");
        require(set_length <= MAX_SETS_PER_GIVEAWAY, "GiveawayRegistry: too many sets.");
        
        for(uint8 i = 0; i < _setIds.length; i++) {
            require(selectionSets[_setIds[i]]._address != address(0), "GiveawayRegistry: supplied selection set not found.");
        }

        GiveawayStruct storage g = giveaways[++giveawayCount];
        g._name = _name;
        g._winnerCount = _winnerCount;
        g._distributor = _distributor;

        giveawaySetIds[giveawayCount] = _setIds;
        giveawaySetPermilles[giveawayCount] = _permilles;

        // Cache set sizes;
        uint256[] memory setSizes = new uint256[](set_length);
        uint256[] memory setOffsets = new uint256[](set_length);
        uint256 totalSize;        
        uint256 currentSize = 0;

        for(uint8 i = 0; i < set_length; i++) {

            address setAddress = selectionSets[ _setIds[i] ]._address;
            uint256 size = TokenSetGeneric(setAddress).size(_permilles[i]);
            setSizes[i] = size;
            totalSize+= size;

            if(i > 0) {
                currentSize+= setSizes[i-1];
            }
            setOffsets[i] = currentSize;
        }
        
        g._setSizes = setSizes;
        g._setOffsets = setOffsets;
        g._totalSize = totalSize;
        g._setLength = uint8(_setIds.length);

        emit giveawayNew(giveawayCount);
    }

    function start(uint16 _giveawayId) public onlyAllowed {
        GiveawayStruct storage g = giveaways[_giveawayId];
        require(g._started == false, "GiveawayRegistry: Already started.");

        // Request a random number
        g._hash = rnd.requestRandomNumberWithCallback();
        hashToGiveawayId[g._hash] = _giveawayId;
        g._started = true;

        emit giveawayStart(_giveawayId);
    }

    function process(uint256 _random, bytes32 _requestHash) public {
        require(msg.sender == address(rnd), "GiveawayRegistry: Unauthorised");
        giveaways[hashToGiveawayId[_requestHash]]._random = _random;

        emit giveawayProcess(hashToGiveawayId[_requestHash]);
    }

    function assignWinners(uint16 _giveawayId) public {
        GiveawayStruct storage g = giveaways[_giveawayId];
        require(g._random > 0, "GiveawayRegistry: random not processed!");
        require(g._processed == false, "GiveawayRegistry: already processed!");

        uint256 randomDiv = 3;
        uint256 random = g._random;

        for(uint8 z = 0; z < g._winnerCount; z++) {
            uint256 _index = random % g._totalSize;
            uint256 currentSize = 0;
            uint16 setIndex = 0;
            for(uint8 i = 0; i < g._setLength; i++) {
                currentSize+= g._setSizes[i];
                if(_index < currentSize) {
                    setIndex = i;
                    i = g._setLength;
                }
            }

            address setAddress = selectionSets[ giveawaySetIds[_giveawayId][setIndex] ]._address;
            uint16 tokenId = TokenSetGeneric(setAddress).get(
                uint32(_index - g._setOffsets[setIndex]),
                giveawaySetPermilles[_giveawayId][setIndex]
            );

            if( isWinner( _giveawayId, tokenId) ) {
                z--;
                random = g._random / randomDiv;
                randomDiv++;            
            } else {
                winnerData[_giveawayId].add(tokenId);
                random = random >> 8;

                if(random < 1) {
                    random = g._random / randomDiv;
                    randomDiv++; 
                }
            }
        }

        g._processed = true;
        emit giveawayWinners(_giveawayId);
    }

    function claim(uint16[] calldata _giveawayIds, uint16[][] calldata tokenIds) public {

        for(uint8 z = 0; z < _giveawayIds.length; z++) {
            uint16 _giveawayId = _giveawayIds[z];

            GiveawayStruct storage g = giveaways[_giveawayId];
            require(g._processed == true, "GiveawayRegistry: already processed!");

            for(uint8 i = 0; i < tokenIds[z].length; i++) {
                
                uint16 tokenId = tokenIds[z][i];
                require(winnerData[_giveawayId].contains(tokenId), "GiveawayRegistry: not winner in selected giveaway!");
                require(!claimData[_giveawayId].contains(tokenId), "GiveawayRegistry: already claimed in selected giveaway!");

                // set claimed
                claimData[_giveawayId].add(tokenId);
                
                // call giveaway distributor
                uint256 resultId = GenericGiveawayDistributor(g._distributor).fulfill(
                    nft.ownerOf(tokenId)
                );

                emit Claimed(_giveawayId, tokenId, resultId);
            }
        }

    }

    function isWinner(uint16 _giveawayId, uint16 _tokenId) public view returns (bool result) {
        return winnerData[_giveawayId].contains(_tokenId);
    }

    function getWinners(uint16 _giveawayId) public view returns (uint16[] memory) {
        return winnerData[_giveawayId].getValues();
    }

    function isClaimed(uint16 _giveawayId, uint16 _tokenId) public view returns (bool result) {
        return claimData[_giveawayId].contains(_tokenId);
    }

    function getClaimers(uint16 _giveawayId) public view returns (uint16[] memory) {
        return claimData[_giveawayId].getValues();
    }
   

    struct GiveawaySetInfo {
        uint16  id;
        bytes32 name;
        address implementer;
        uint256 size;
        uint8   setType;
        uint16  actualSize;
        uint16  start;
        uint16  end;
        uint16  permille;
    }
    struct GiveawayInfo {
        GiveawayStruct giveaway;
        GiveawaySetInfo[] setInfo;
        uint16[] setIds;
        uint16[] setPermilles;
        uint16[] winningTokens;
        uint16[] claimedTokens;
    }

    function getGiveawayInfo(uint16 _giveawayId) public view returns (GiveawayInfo memory info) {
        uint16[] memory giveawaySets = giveawaySetIds[_giveawayId];
        uint8 setLength = uint8(giveawaySets.length);

        info = GiveawayInfo(
            giveaways[_giveawayId],
            new GiveawaySetInfo[](setLength),
            giveawaySetIds[_giveawayId],
            giveawaySetPermilles[_giveawayId],
            winnerData[_giveawayId].getValues(),
            claimData[_giveawayId].getValues()
        );

        for(uint8 i = 0; i < setLength; i++) {
            uint16 setId = giveawaySetIds[_giveawayId][i];
            uint16 setPermille = giveawaySetPermilles[_giveawayId][i];
            address setAddress = selectionSets[ setId ]._address;

            uint8 setType = TokenSetGeneric(setAddress).setType();
            uint16 _start = 0;
            uint16 _end = 0;

            // ranged sets
            if(setType == 2 || setType == 3) {
                _start = TokenSetGeneric(setAddress).start();
                _end = TokenSetGeneric(setAddress).end();
            }

            info.setInfo[i] = GiveawaySetInfo( 
                setId,
                TokenSetGeneric(setAddress).name(),
                setAddress,
                TokenSetGeneric(setAddress).size(setPermille),
                setType,
                TokenSetGeneric(setAddress).actualSize(),
                _start,
                _end,
                setPermille
            );
        }
    }


    struct TokenInfo {
        uint16  id;
        bool hasPrizes;
        uint16[] giveawayIds;
        bytes32[] giveawayNames;
    }

    function getGiveawayIdsWhereTokenIsWinner(uint16[] memory tokenIds, uint16 _start, uint16 _length) public view returns (TokenInfo[] memory results) {
        if(_length > giveawayCount) {
            _length = giveawayCount;
        }
        uint16 tokenCount = 0;

        results = new TokenInfo[](tokenIds.length);

        for(uint16 z = 0; z < tokenIds.length; z++ ) {
            bool hasPrizes = false;
            uint16 tokenId = tokenIds[z];
            uint16[] memory giveawayIds = new uint16[](_length);
            bytes32[] memory giveawayNames = new bytes32[](_length);
            uint16 resultCount = 0;

            for(uint16 i = _start + 1; i <= _length; i++ ) {
                if(winnerData[i].contains(tokenId) && !claimData[i].contains(tokenId)) {
                    giveawayIds[resultCount] = i;
                    giveawayNames[resultCount] = giveaways[i]._name;
                    resultCount++;
                    hasPrizes = true;
                }
            }
            results[tokenCount++] = (TokenInfo(tokenId, hasPrizes, giveawayIds, giveawayNames));
        }
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

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "GiveawayRegistry: Not Authorised"
        );
        _;
    }
}
