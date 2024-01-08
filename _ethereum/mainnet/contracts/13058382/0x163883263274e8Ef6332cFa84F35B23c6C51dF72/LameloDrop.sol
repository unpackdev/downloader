//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IRNG.sol";

contract LameloDrop is Ownable {

    uint8 constant PoolIds_RED_MARS = 1;
    uint8 constant PoolIds_BLUE_NEPTUNE = 2;
    uint8 constant PoolIds_SILVER = 3;

    mapping(uint8 => mapping(uint16 => uint16)) public participantingIdsPerPool;
    mapping(uint8 => uint16) public poolCount;

    mapping(uint16 => uint8) internal tokenData;

    bytes32 public requestHash;
    bool    public canResolve = false;
    bool    public resolved = false;
    uint256 public random = 0;
    bool    public hasPrizes = false;

    // contracts
    IERC721 public lameloContract;
    IRNG    public rnd;
    uint256 public startTime;
    uint256 public endTime;

    address public winner_address_RED_MARS;
    address public winner_address_BLUE_NEPTUNE;
    address public winner_address_SILVER;

    constructor(
        address _LBCAddress,
        address _rndContractAddress,
        uint256 _startTime,
        uint256 _endTime
    ) {
        lameloContract = IERC721(_LBCAddress);
        rnd = IRNG(_rndContractAddress);
        startTime = _startTime;
        endTime = _endTime;
    }

    function onERC721Received(
        address, // operator
        address, // from,
        uint256 receivedTokenId,
        bytes calldata // data
    ) external returns (bytes4) {
        require(
            msg.sender == address(lameloContract),
            "Must be lameloContract address"
        );

        if (
            receivedTokenId == 498 ||
            receivedTokenId == 499 ||
            receivedTokenId == 500
        ) {
            if (
                lameloContract.ownerOf(498) == address(this) &&
                lameloContract.ownerOf(499) == address(this) &&
                lameloContract.ownerOf(500) == address(this)
            ) {
                hasPrizes = true;
            }

            return this.onERC721Received.selector;
        }

        revert("bad token received");
    }

    // 1 - receive token id array uint16[]
    function registerForDrop(uint16[] calldata tokenIds) public {
        require(hasPrizes, "Does not have prize tokens");
        require(getTimestamp() > startTime, "Not started");
        require(getTimestamp() < endTime, "Already ended");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            uint16 thisId = tokenIds[i];

            // 1 - check if token was previously used
            require(!isTokenUsed(thisId), "Already has a ticket");
            require(thisId > 500, "Token id must be over 500");

            // NO POINT in checking ownership now.. if someone wants to pay someone else's token participation, WHY NOT ?
            // 2 - check ownership
            // if (lameloContract.ownerOf(thisId) != msg.sender) {
            //     revert("not owner");
            // }

            // 3 get pool id from token id
            uint8 poolId = 0;
            if(500 < thisId && thisId <= 1500 ) {
                poolId = PoolIds_SILVER;
            } else if (1500 < thisId && thisId <= 3500 ) {
                poolId = PoolIds_BLUE_NEPTUNE;
            } else if (3500 < thisId ) {
                poolId = PoolIds_RED_MARS;
            }

            // 4 - register entry
            poolCount[poolId]++;
            participantingIdsPerPool[poolId][poolCount[poolId]] = thisId;

            // register as used
            setTokenUsed(thisId);
        }
    }

    function requestVRF() public onlyOwner {
        require(getTimestamp() > endTime, "Not ended");
        requestHash = rnd.requestRandomNumberWithCallback();
    }

    function process(uint256 _random, bytes32 _requestId) public {
        require(msg.sender == address(rnd), "Unauthorised");
        require(requestHash == _requestId, "Unauthorised");
        require(!canResolve, "VRF already received");
        require(!resolved, "Already resolved");

        canResolve = true;
        random = _random;
    }

    function resolveDrop() public onlyOwner {
        require(canResolve, "NO VRF YET");
        require(!resolved, "Already resolved");
        require(getTimestamp() > endTime, "Already ended");

        // take VRF
        // add 1 to index so everyone has a chance
        uint16 _index = uint16(random % poolCount[PoolIds_RED_MARS]) + 1;
        uint16 winingTokenId = participantingIdsPerPool[PoolIds_RED_MARS][_index];
        winner_address_RED_MARS = lameloContract.ownerOf(winingTokenId); 
        random = random >> 8;

        _index = uint16(random % poolCount[PoolIds_BLUE_NEPTUNE]) + 1;
        winingTokenId = participantingIdsPerPool[PoolIds_BLUE_NEPTUNE][_index];
        winner_address_BLUE_NEPTUNE = lameloContract.ownerOf(winingTokenId); 
        random = random >> 8;

        _index = uint16(random % poolCount[PoolIds_SILVER]) + 1;
        winingTokenId = participantingIdsPerPool[PoolIds_SILVER][_index];
        winner_address_SILVER = lameloContract.ownerOf(winingTokenId); 
        random = random >> 8;

        resolved = true;

        // transfer tokens to new owners
        lameloContract.transferFrom(address(this), winner_address_RED_MARS, 498);
        lameloContract.transferFrom(address(this), winner_address_BLUE_NEPTUNE, 499);
        lameloContract.transferFrom(address(this), winner_address_SILVER, 500);
    }

    function recoverTokens() external onlyOwner {
        require(hasPrizes, "Does not have prize tokens");
        require(!canResolve, "VRF already received");
        require(!resolved, "Already resolved");
        // if shit hits the fan recover stuff

        // transfer tokens to msg.sender // owner
        lameloContract.transferFrom(address(this), msg.sender, 500);
        lameloContract.transferFrom(address(this), msg.sender, 499);
        lameloContract.transferFrom(address(this), msg.sender, 498);
    }

    function isTokenUsed(uint16 _position) public view returns (bool result) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (tokenData[byteNum] == 0) return false;
        return tokenData[byteNum] & (0x01 * 2**bitPos) != 0;
    }

    function setTokenUsed(uint16 _position) public {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        tokenData[byteNum] = uint8(tokenData[byteNum] | (2**bitPos));
    }

    /// web3 Frontend - VIEW METHODS

    function getUsedTokenData(uint8 _page, uint16 _perPage)
        public
        view
        returns (uint8[] memory)
    {
        _perPage = _perPage / 8;
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues;

        assembly {
            mstore(retValues, _perPage)
        }

        while (i < max) {
            retValues[j] = tokenData[i];
            j++;
            i++;
        }

        assembly {
            // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize())
        }
        return retValues;
    }

    function getStats() public view returns (
        uint16[3] memory _poolCounts,
        address[3] memory _winners,
        uint8[] memory _tokenData
    ) {
        _tokenData = getUsedTokenData(0, 10000);

        _poolCounts = [
            poolCount[PoolIds_RED_MARS],
            poolCount[PoolIds_BLUE_NEPTUNE],
            poolCount[PoolIds_SILVER]
        ];

       _winners = [
           winner_address_RED_MARS,
           winner_address_BLUE_NEPTUNE,
           winner_address_SILVER
       ];
    }

    function getTimestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }

    /// blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

}
