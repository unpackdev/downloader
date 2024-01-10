// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IAKCCore.sol";

contract AKCCoreMultiStakeExtension is Ownable {

    /**
     * @dev Interfaces
     */
    IAKCCore public akcCore;
    IERC721 public akc;

    /**
     * @dev Addresses
     */
    address public manager;

    /**
     * @dev Staking Logic
     */

    /// @dev Pack owner and spec in single uint256 to save gas
    /// - first 160 bits is address
    /// - last 96 bits is spec
    mapping(uint256 => uint256) public kongToStaker;
     
    /// @dev Save staking data in a single uint256
    /// - first 64 bits are the timestamp
    /// - second 64 bits are the amount
    /// - third 128 bits are the pending bonus
    mapping(address => mapping(uint256 => uint256)) public userToStakeData;

    /// @dev Denomination is in thousands
    mapping(uint256 => uint256) public stakeAmountToBonus;

    /// @dev Number to use for bonus when 
    /// staked amount is greater than this number.
    uint256 public stakeCap = 6;
    uint256 public capsuleRate = 2 ether;
    uint256 public maxCapsules = 20;

    mapping(address => mapping(uint256 => uint256)) public userToTotalBonus;

    /**
     * @dev Modifiers
     */
    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner(), "Sender not authorized");
        _;
    }

    constructor(
        address _akcCore,
        address _akc
    ) {
        akcCore = IAKCCore(_akcCore);
        akc = IERC721(_akc);

        stakeAmountToBonus[1] = 75;
        stakeAmountToBonus[2] = 100;
        stakeAmountToBonus[3] = 125;
        stakeAmountToBonus[4] = 150;
        stakeAmountToBonus[5] = 175;
        stakeAmountToBonus[6] = 200;
    }


    /** === Stake Logic === */

    function _getNakedRewardBySpec(address staker, uint256 targetSpec, uint256 timestamp)
        internal
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getLastClaimedTimeFromTribe(tribe);
                lastClaimedTimeStamp = lastClaimedTimeStamp >= timestamp ? lastClaimedTimeStamp : timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    /**
     * @dev Get bonus from last stake / claim
     * to block.timestamp for spec based on staked amount.
     */
    function _getBonus(address staker, uint256 spec)
        internal
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = _getStakeTimeStampFromStakeData(stakeData);
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = _getNakedRewardBySpec(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }

    function addToBonus(address staker, uint256 spec, uint256 bonus)
        external
        onlyManager {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 lastTimeStamp = _getStakeTimeStampFromStakeData(stakeData);
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            
            userToStakeData[staker][spec] = _getUpdatedStakeData(lastTimeStamp, currentAmount, accumulatedBonus + bonus);
        }

    /**
     * @dev Returns pending bonus
     * and resets stake data with current time
     * and zero bonus.
     */
    function liquidateBonus(address staker, uint256 spec)
        external
        onlyManager
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            if (stakeData == 0) {
                return 0;
            }
            
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            uint256 pendingBonus = _getBonus(staker, spec);
            
            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount, 0);
            userToTotalBonus[staker][spec] += accumulatedBonus + pendingBonus;
            
            return (accumulatedBonus + pendingBonus);
        }

    /**
     * @dev Stakes a new kong in a spec
     * gets pending bonus based on previous amount
     * and adds it to accumulated bonus
     */
    function stake(address staker, uint256 spec, uint256 kong)
        external
        onlyManager {
            require(spec < akcCore.getTribeSpecAmount() || spec == 257, "Invalid spec");
            require(kongToStaker[kong] == 0, "Kong already staked");
            require(akcCore.getTotalTribesByspec(staker, spec) > 0 || spec == 257, "User has no items in spec");
            require(akc.ownerOf(kong) == address(this), "Kong not in custody");

            kongToStaker[kong] = _getKongStakeData(staker, spec);

            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);            
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);

            if (spec == 257) {
                require(currentAmount < maxCapsules, "Max capsules staked");
            } 

            uint256 pendingBonus = stakeData == 0 ? 0 : _getBonus(staker, spec);

            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount + 1, accumulatedBonus + pendingBonus);
        }

     /**
      * @dev Unstakes a kong from a spec
      * gets pending bonus based on previous amount
      * and adds it to accumulated bonus
      */
    function unstake(address staker, uint256 spec, uint256 kong)
        external
        onlyManager {
            uint256 kongStakeData = kongToStaker[kong];
            address kongStakeStaker = _getAddressFromKongStakeData(kongStakeData);
            uint256 kongStakeSpec = _getSpecFromKongStakeData(kongStakeData);

            require(kongStakeStaker == staker, "Kong not owned by staker");
            require(kongStakeSpec == spec, "Kong is not staked in supplied spec");
            require(akc.ownerOf(kong) == staker, "Kong not transfered to staker");

            delete kongToStaker[kong];

            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);            
            uint256 accumulatedBonus = _getStakePendingBonusFromStakeData(stakeData);
            uint256 pendingBonus = _getBonus(staker, spec);

            userToStakeData[staker][spec] = _getUpdatedStakeData(block.timestamp, currentAmount - 1, accumulatedBonus + pendingBonus);
        }


    /** === Getters === */


    // get stake data internal
    function _getStakeTimeStampFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint64(stakeData));
        }
    
    function _getStakeAmountFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint64(stakeData >> 64));
        }
    
    function _getStakePendingBonusFromStakeData(uint256 stakeData)
        internal
        pure
        returns (uint256) {
            return  uint256(uint128(stakeData >> 128));
        }

    function _getUpdatedStakeData(uint256 newTimeStamp, uint256 newAmount, uint256 newBonus)
        internal
        pure
        returns (uint256) {
            uint256 stakeData = newTimeStamp;
            stakeData |= newAmount << 64;
            stakeData |= newBonus << 128;
            return stakeData;
        }

    // get kong stake data internal
    function _getAddressFromKongStakeData(uint256 kongStakeData)
        internal
        pure
        returns (address) {
            return address(uint160(kongStakeData));
        }

    function _getSpecFromKongStakeData(uint256 kongStakeData)
        internal
        pure
        returns (uint256) {
            return uint256(uint96(kongStakeData >> 160));
        }

    function _getKongStakeData(address staker, uint256 spec)
        internal
        pure
        returns (uint256) {
            uint256 kongStakeData = uint256(uint160(staker));
            kongStakeData |= spec << 160;
            return kongStakeData;
        }

    // get stake data external
    function getStakeTimeStampFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getStakeTimeStampFromStakeData(stakeData);
        }    
    
    function getStakeAmountFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return _getStakeAmountFromStakeData(stakeData);
        }
    
    function getStakePendingBonusFromStakeData(uint256 stakeData)
        external
        pure
        returns (uint256) {
            return  _getStakePendingBonusFromStakeData(stakeData);
        }

    // get kong stake data external
    function getAddressFromKongStakeData(uint256 kongStakeData)
        external
        pure
        returns (address) {
            return _getAddressFromKongStakeData(kongStakeData);
        }

    function getSpecFromKongStakeData(uint256 kongStakeData)
        external
        pure
        returns (uint256) {
            return _getSpecFromKongStakeData(kongStakeData);
        }  


    /** === View Bonus === */


    function getNakedRewardBySpecFromCreate(address staker, uint256 targetSpec, uint256 timestamp)
        public
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getCreatedAtFromTribe(tribe);
                lastClaimedTimeStamp = lastClaimedTimeStamp >= timestamp ? lastClaimedTimeStamp : timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    function getNakedRewardBySpecDisregardCreate(address staker, uint256 targetSpec, uint256 timestamp)
        public
        view
        returns (uint256) {
            uint256 totalReward;
            
            for (uint i = 0; i < akcCore.getTribeAmount(staker); i++) {               
                uint256 tribe = akcCore.userToTribes(staker, i);
                uint256 spec = akcCore.getSpecFromTribe(tribe);

                if (spec != targetSpec)
                    continue;

                uint256 lastClaimedTimeStamp = akcCore.getCreatedAtFromTribe(tribe);
                lastClaimedTimeStamp = timestamp;

                (,uint256 rps,) = akcCore.tribeSpecs(spec);
                        
                uint256 interval = (block.timestamp - lastClaimedTimeStamp);
                uint256 reward = rps * interval / 86400;

                totalReward += reward;
            }
            
            return totalReward;
        }

    function getBonusFromTimestamp(address staker, uint256 spec, uint256 timestamp)
        external
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = timestamp;
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = getNakedRewardBySpecFromCreate(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }

    function getBonusFromTimestampDisregardCreate(address staker, uint256 spec, uint256 timestamp)
        external
        view
        returns (uint256) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 currentAmount = _getStakeAmountFromStakeData(stakeData);
            uint256 lastTimeStamp = timestamp;
            uint256 bonusPercentage = currentAmount >= stakeCap ? stakeAmountToBonus[stakeCap] : stakeAmountToBonus[currentAmount];
            
            /// @dev Get reward for all tribes of spec from 
            /// last stake timestamp to block.timestamp. Create time is taken into account
            /// also we make sure the last time stamp is always greater than or
            /// equal to the the last claim time.
            uint256 pendingReward;
            if (spec == 257) {
                pendingReward = (block.timestamp - lastTimeStamp) * (currentAmount * capsuleRate) / 86400;
                return pendingReward;
            }

            pendingReward = getNakedRewardBySpecDisregardCreate(staker, spec, lastTimeStamp);
            return pendingReward * bonusPercentage / 1000;
        }


    /** === View === */

    function getBonus(address staker, uint256 spec)
        external
        view   
        returns(uint256) {
            return _getBonus(staker, spec);
        }

    function getNakedRewardBySpec(address staker, uint256 targetSpec, uint256 timestamp)
        external
        view
        returns (uint256) {
            return _getNakedRewardBySpec(staker, targetSpec, timestamp);
        }

    function getStakedKongsOfUserBySpec(address staker, uint256 spec)
        external
        view
        returns (uint256[] memory) {
            uint256 stakeData = userToStakeData[staker][spec];
            uint256 amountStaked = _getStakeAmountFromStakeData(stakeData);

            uint256[] memory kongs = new uint256[](amountStaked);
            uint256 counter;

            for (uint i = 1; i <= 8888; i++) {
                uint256 kongStakeData = kongToStaker[i];
                address kongStaker = _getAddressFromKongStakeData(kongStakeData);
                uint256 kongSpec = _getSpecFromKongStakeData(kongStakeData);

                if (kongStaker == staker && kongSpec == spec) {
                    kongs[counter] = i;
                    counter++;
                }        
            }
            return kongs;
        }


   /** === Owner === */


   function setAkcTribeManager(address newManager)
        external
        onlyOwner {
            manager = newManager;
        }

    function setStakeAmountToBonus(uint256 stakeAmount, uint256 bonus)
        external
        onlyOwner {
            stakeAmountToBonus[stakeAmount] = bonus;
        }

    function setStakeCap(uint256 newCap)
        external
        onlyOwner {
            stakeCap = newCap;
        }
    
    function setCapsuleRate(uint256 newRate)
        external
        onlyOwner {
            capsuleRate = newRate;
        }

    function akcNFTApproveForAll(address approved, bool isApproved)
        external
        onlyOwner {
            akc.setApprovalForAll(approved, isApproved);
        }
    
    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = IERC20(_erc20Address).balanceOf(address(this));
        IERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }

    function withdrawStuckKong(uint256 kongId, address _to) external onlyOwner {
        require(akc.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        akc.transferFrom(address(this), _to, kongId);
    }
}