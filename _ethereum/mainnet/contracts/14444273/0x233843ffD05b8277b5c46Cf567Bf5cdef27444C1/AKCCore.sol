// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";

contract AKCCore is Ownable, AccessControl, IERC721Receiver {

    /** 
     * @dev ROLES 
     */
    bytes32 public constant CREATOR_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CLAIMER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MODIFIER_ROLE = keccak256("BURNER_ROLE");

    /** 
     * @dev CORE DATA STRUCTURES 
     */
    struct Tribe {
        uint256 createdAt;
        uint256 lastClaimedTimeStamp;
        uint256 spec;
    }

    struct TribeSpec {
        uint256 price;
        uint256 rps;
        string name;
    }    

    /** 
     * @dev TRACKING DATA 
     */
    mapping(address => uint256[]) public userToTribes;
    mapping(address => mapping(uint256 => uint256)) public userToEarnings;
    TribeSpec[] public tribeSpecs;

    /**
     * @dev CREATION LOGIC
     */
    uint256 maxBatchTribes = 50;

    /**
     * @dev AKC STAKING
     */
    IERC721 public akc;
    mapping(address => mapping(uint256 => uint256)) public userToAKC; // spec to akc id
    uint256 public akcStakeBoost = 8;
    uint256 public capsuleSpecId = 257;
    uint256 public capsuleEarnRate = 2 ether;

    /**
     * @dev AFFILIATE
     */
    uint256 public affiliatePercentage = 5;
    uint256 public affiliateKickback = 5;
    mapping(address => uint256) public userToAffiliateEarnings;
    

    /**
     * @dev EVENTS
     */
    event TribeCreated(address indexed owner, uint256 indexed tribeSpec);
    event ClaimedReward(address indexed owner, uint256 indexed reward);
    event StakeAKC(address indexed staker, uint256 indexed akc, uint256 indexed spec);
    event UnStakeAKC(address indexed staker, uint256 indexed akc, uint256 indexed spec);
    event CreateNewTribeSpecEvent(uint256 indexed price, uint256 indexed rps, string indexed name);
    event UpdateTribeSpecEvent(uint256 indexed price, uint256 indexed rps, string indexed name);
    event SuspendTribesOfUserEvent(address indexed user);

    event SetMaxBatchTribesEvent(uint256 indexed newBatch);
    event SetAkcStakeBoostEvent(uint256 indexed akcStakeBoost);

    constructor(
        uint256[] memory tribePrices,
        uint256[] memory tribeRPS,
        string[] memory names,
        address _akc
    ) {
        _setupRole(CREATOR_ROLE, msg.sender);
        _setupRole(CLAIMER_ROLE, msg.sender);
        _setupRole(MODIFIER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(tribePrices.length > 0, "HAVE TO SPECIFY INITIALIZER TRIBES");
        require(tribePrices.length == tribeRPS.length, "TRIBE PRICES MUST MATCH RPS");
        require(tribePrices.length == names.length, "TRIBE PRICES MUST MATCH NAMES");

        for (uint i = 0; i < tribePrices.length; i++) {
            uint256 price = tribePrices[i];
            uint256 rps = tribeRPS[i];
            string memory name = names[i];

            createNewTribeSpec(price, rps, name);          
        }

        akc = IERC721(_akc);
    }


    /** === CREATING === */


    function createSingleTribe(address newOwner, uint256 spec) 
        external 
        onlyRole(CREATOR_ROLE) {
            require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

            uint256 tribe = block.timestamp;
            tribe |= block.timestamp << 32;
            tribe |= spec << 64;

            userToTribes[newOwner].push(tribe);

            emit TribeCreated(newOwner, spec);
    }

    function createManyTribes(address[] calldata newOwners, uint256[] calldata specs)
        external 
        onlyRole(CREATOR_ROLE) {
            require(newOwners.length == specs.length, "NEWOWNERS MUST MATCH SPEC");
            require(newOwners.length < maxBatchTribes, "NEWOWNERS EXCEEDS MAX BATCH");

            for (uint i = 0; i < newOwners.length; i++) {
                address newOwner = newOwners[i];
                uint256 spec = specs[i];

                require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

                uint256 tribe = block.timestamp;
                tribe |= block.timestamp << 32;
                tribe |= spec << 64;

                userToTribes[newOwner].push(tribe);

                emit TribeCreated(newOwner, spec);
            }
        }


    /** === CLAIMING === */


    function claimRewardOfTribeByIndex(address tribeOwner, uint256 tribeIndex) 
        public
        onlyRole(CLAIMER_ROLE)
        returns(uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
            
            uint256 newTribe = getCreatedAtFromTribe(tribe);  
            newTribe |= block.timestamp << 32;
            newTribe |= spec << 64;
            userToTribes[tribeOwner][tribeIndex] = newTribe;

            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 90) {
                timeBoost = reward * 50 / 100;
            } else if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            userToEarnings[tribeOwner][spec] += reward;

            return reward;
        }
    
    function claimRewardFromCapsule(address tribeOwner)
        internal 
        returns (uint256) {
            uint256 capsuleData = userToAKC[tribeOwner][capsuleSpecId];
            if (capsuleData == 0) {
                return 0;
            }

            uint256 kongId = getAkcIdFromAKCData(capsuleData);
            uint256 lastClaimed = getAkcTimestampFromAKCData(capsuleData);
            uint256 interval = (block.timestamp - lastClaimed);
            uint256 reward = capsuleEarnRate * interval / 86400;

            uint256 newData = kongId;
            newData |= block.timestamp << 128;
            userToAKC[tribeOwner][capsuleSpecId] = newData;         

            return reward;
        }

    function claimAllRewards(address tribeOwner)
        external
        onlyRole(CLAIMER_ROLE)
        returns(uint256) {
            require(userToTribes[tribeOwner].length > 0 || userToAKC[tribeOwner][capsuleSpecId] != 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += claimRewardOfTribeByIndex(tribeOwner, i);
            }

            totalReward += claimRewardFromCapsule(tribeOwner);

            emit ClaimedReward(tribeOwner, totalReward);

            return totalReward;
        }


     /** === STAKING === */


     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function stakeAKC(address staker, uint256 akcId, uint256 spec)
        external
        onlyRole(CLAIMER_ROLE) {
            require(spec < tribeSpecs.length || spec == capsuleSpecId, "SPEC OUT OF BOUNDS");
            require(userToAKC[staker][spec] == 0, "ANOTHER KONG ALREADY STAKED IN SPEC");
            require(getTotalTribesByspec(staker, spec) > 0 || spec == capsuleSpecId, "USER DOES NOT OWN SPEC");
            require(akc.ownerOf(akcId) == address(this), "KONG NOT TRANSFERED TO CONTRACT");

            uint256 data = akcId;
            data |= block.timestamp << 128;
            userToAKC[staker][spec] = data;            

            emit StakeAKC(staker, akcId, spec);
        }

    function unstakeAKC(address staker, uint256 akcId, uint256 spec)
        external
        onlyRole(CLAIMER_ROLE) {
            require(userToAKC[staker][spec] != 0, "NO KONG STAKED IN SPEC");
            require(akc.ownerOf(akcId) != address(this), "KONG STILL IN CONTRACT");

            uint256 akcFromData = getAkcIdFromAKCData(userToAKC[staker][spec]);
            require(akcFromData == akcId, "CANNOT UNSTAKE AKC YOU DON'T OWN");

            delete userToAKC[staker][spec];

            emit UnStakeAKC(staker, akcId, spec);   
        }
    

    /** === AFFILIATE === */


    function registerAffiliate(address affiliate, uint256 earned)
        external
        onlyRole(CLAIMER_ROLE) {
            uint256 affData = userToAffiliateEarnings[affiliate];            
            uint amount = getAmountOfAffiliatesFromAffiliate(affData);
            uint256 totalEarned = getEarnedFromAffiliate(affData);

            uint256 newData = (totalEarned + earned) / (10**14);
            newData |= (amount + 1) << 128;
            userToAffiliateEarnings[affiliate] = newData;
        }


    /** === GETTERS === */


    function getCreatedAtFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint32(tribe));
        }
    
    function getLastClaimedTimeFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint32(tribe >> 32));
        }
    
    function getSpecFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint8(tribe >> 64));
        }

    function getAkcIdFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(akcData));
        }

    function getAkcTimestampFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(akcData >> 128));
        }
    
    function getEarnedFromAffiliate(uint256 affiliateData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(affiliateData)) * (10 ** 14);
        }
        
    function getAmountOfAffiliatesFromAffiliate(uint256 affiliateData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(affiliateData >> 128));
        }


    /** === VIEWING === */


    function getTribeAmount(address tribeOwner)
        external
        view
        returns(uint256) {
            return userToTribes[tribeOwner].length;
        }
    
    function getTribeSpecAmount()
        external
        view 
        returns(uint256) {
            return tribeSpecs.length;
        }

    function getTotalTribesByspec(address tribeOwner, uint256 spec)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            if (spec >= tribeSpecs.length) {
                return 0;
            }
            uint256 total = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                if (getSpecFromTribe(userToTribes[tribeOwner][i]) == spec) {
                    total++;
                }
            }

            return total;
        }
    
    function getTribeStructFromTribe(uint256 tribe) 
        public
        pure
        returns (Tribe memory _tribe) {
            _tribe.createdAt = getCreatedAtFromTribe(tribe);
            _tribe.lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);
            _tribe.spec = getSpecFromTribe(tribe);
        }
    
    function getLastClaimedOfUser(address tribeOwner)
        external
        view
        returns(uint256) {
            if (userToTribes[tribeOwner].length == 0) {
                return 0;
            } else {
                uint256 firstTribe = userToTribes[tribeOwner][0];
                return getLastClaimedTimeFromTribe(firstTribe);
            }
        }

    function getTribeAmountBySpec(address tribeOwner, uint256 spec) 
        external
        view
        returns(uint256) {
            require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");

            uint256 counter = 0;
            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                uint256 tribe = userToTribes[tribeOwner][i];
                uint256 tribeSpec = getSpecFromTribe(tribe);
                if (tribeSpec == spec) {
                    counter++;
                }
            }

            return counter;
        }

    function getTribeOfUserByIndexAndSpec(address tribeOwner, uint256 tribeIndex, uint256 spec)
        external
        view
        returns (Tribe memory) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");
            require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

            uint256 counter = 0;
            uint256 tribeInstance;
            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                uint256 tribe = userToTribes[tribeOwner][i];
                uint256 tribeSpec = getSpecFromTribe(tribe);
                if (tribeSpec == spec) {
                    if (counter == tribeIndex) {
                        tribeInstance = tribe;
                        break;
                    } else {
                        counter++;
                    }
                }
            }

            return getTribeStructFromTribe(tribeInstance);
        }

    function getTribeRewardByIndex(address tribeOwner, uint256 tribeIndex)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                        
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;         

            return reward;
        }

    function getTribeRewardByIndexAndSpec(address tribeOwner, uint256 tribeIndex, uint256 targetSpec)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            if (spec != targetSpec)
                return 0;

            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }
    
    function getTribeRewardByIndexAndTimestamp(address tribeOwner, uint256 tribeIndex, uint256 timestamp)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            uint256 lastClaimedTimeStamp = getCreatedAtFromTribe(tribe);
            lastClaimedTimeStamp = lastClaimedTimeStamp > timestamp ? lastClaimedTimeStamp : timestamp;

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;
            interval = block.timestamp - getLastClaimedTimeFromTribe(tribe);       
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }

    function getTribeRewardByIndexAndTimestampDisregardCreate(address tribeOwner, uint256 tribeIndex, uint256 timestamp)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);            

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - timestamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {                
                akcBoost = reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            interval = block.timestamp - lastClaimedTimeStamp;
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }

    function getTribeRewardByIndexAndTimestampAndSpec(address tribeOwner, uint256 tribeIndex, uint256 timestamp, uint256 targetSpec)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            if (spec != targetSpec)
                return 0;

            uint256 lastClaimedTimeStamp = getCreatedAtFromTribe(tribe);
            lastClaimedTimeStamp = lastClaimedTimeStamp > timestamp ? lastClaimedTimeStamp : timestamp;

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;     
            interval = block.timestamp - getLastClaimedTimeFromTribe(tribe);       
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }
    
    function getCapsuleRewards(address capsuleOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            uint256 capsuleData = userToAKC[capsuleOwner][capsuleSpecId];
            if (capsuleData == 0) {
                return 0;
            }
            
            uint256 lastClaimed = getAkcTimestampFromAKCData(capsuleData);
            if (timestamp != 0)
                lastClaimed = timestamp;
            uint256 interval = (block.timestamp - lastClaimed);
            uint256 reward = capsuleEarnRate * interval / 86400;               

            return reward;
        }
    
    function getAllRewards(address tribeOwner)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndex(tribeOwner, i);
            }

            totalReward += getCapsuleRewards(tribeOwner, 0);

            return totalReward;
        }

    function getAllRewardsBySpec(address tribeOwner, uint256 spec)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndSpec(tribeOwner, i, spec);
            }

            return totalReward;
        }
    
    function getAllRewardsByTimestamp(address tribeOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestamp(tribeOwner, i, timestamp);
            }

            totalReward += getCapsuleRewards(tribeOwner, timestamp);

            return totalReward;
        }

    function getAllRewardsByTimestampDisregardCreate(address tribeOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestampDisregardCreate(tribeOwner, i, timestamp);
            }

            totalReward += getCapsuleRewards(tribeOwner, timestamp);

            return totalReward;
        }
        
    function getAllRewardsByTimestampAndSpec(address tribeOwner, uint256 timestamp, uint256 spec)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestampAndSpec(tribeOwner, i, timestamp, spec);
            }

             return totalReward;
        }

    function getAllStakedKongsOfUser(address staker)
        external
        view
        returns(uint256[] memory) {
            uint256[] memory kongs = new uint256[](tribeSpecs.length);
            for (uint i = 0; i < tribeSpecs.length; i++) {
                uint data = userToAKC[staker][i];
                uint kong = getAkcIdFromAKCData(data);
                kongs[i] = kong;
            }
            return kongs;
        }
    
    function getAllRewardsOfUsersByTimestamp(address[] calldata wallets, uint256 timestamp)
        external
        view
        returns (uint256[] memory) {
            uint256[] memory rewards = new uint256[](wallets.length);
            for (uint i = 0; i < wallets.length; i++) {
                uint reward = getAllRewardsByTimestamp(wallets[i], timestamp);
                rewards[i] = reward;
            }
            return rewards;
        }

    function getDiscountFactor(address tribeOwner)
        external
        view
        returns(uint256) {
            uint256 discount;
            uint256 tribeAmount = userToTribes[tribeOwner].length;
            
            if (tribeAmount >= 50) {
                discount = 20;
            } else if (tribeAmount >= 20) {
                discount = 15;
            } else if (tribeAmount >= 15) {
                discount = 12;
            } else if (tribeAmount >= 10) {
                discount = 8;
            } else if (tribeAmount >= 5) {
                discount = 4;
            } else if (tribeAmount >= 2) {
                discount = 2;
            }
            
            return discount;
        }
    

    /** === MODIFIER ONLY === */


    function createNewTribeSpec(uint256 price, uint256 rps, string memory name)
        public
        onlyRole(MODIFIER_ROLE) {
            TribeSpec memory tribeSpec = TribeSpec({
                price: price,
                rps: rps,
                name: name
            });

            tribeSpecs.push(tribeSpec);

            emit CreateNewTribeSpecEvent(price, rps, name);
        }

    function updateTribeSpec(uint256 index, uint256 newPrice, uint256 newRps)
        external
        onlyRole(MODIFIER_ROLE) {
            require(index < tribeSpecs.length, "INDEX OUT OF BOUNDS");

            TribeSpec storage tribeSpec = tribeSpecs[index];
            tribeSpec.price = newPrice;
            tribeSpec.rps = newRps;

            emit UpdateTribeSpecEvent(newPrice, newRps, tribeSpec.name);
        }
    
    function suspendTribesOfUser(address tribeOwner) 
        external 
        onlyRole(MODIFIER_ROLE) {
            require(userToTribes[tribeOwner].length > 0, "USER HAS NO TRIBES");            
            delete userToTribes[tribeOwner];

            emit SuspendTribesOfUserEvent(tribeOwner);
        }
    
    function setMaxBatchTribes(uint256 newBatch)
        external 
        onlyRole(MODIFIER_ROLE) {
            maxBatchTribes = newBatch;

            emit SetMaxBatchTribesEvent(newBatch);
        }
    
    function setAKCStakingBoostPercentage(uint256 newPercentage)
        external
        onlyRole(MODIFIER_ROLE) {
            akcStakeBoost = newPercentage;

            emit SetAkcStakeBoostEvent(newPercentage);
        }
    
    function akcNFTApproveForAll(address approved, bool isApproved)
        external
        onlyRole(MODIFIER_ROLE) {
            akc.setApprovalForAll(approved, isApproved);
        }

    function setCapsuleEarnRate(uint256 newRate)
        external
        onlyRole(MODIFIER_ROLE) {
            capsuleEarnRate = newRate;
        }

    function setAffiliatePercentage(uint256 newPercentage)
        external
        onlyRole(MODIFIER_ROLE) {
            affiliatePercentage = newPercentage;
        }

    function setAffiliateKickBack(uint256 newKickback)
        external
        onlyRole(MODIFIER_ROLE) {
            affiliateKickback = newKickback;
        }
    
    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner
    {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = ERC20(_erc20Address).balanceOf(address(this));
        ERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }

    function withdrawStuckKong(uint256 kongId, address _to) external onlyOwner {
        require(akc.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        akc.transferFrom(address(this), _to, kongId);
    }
}