// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath112.sol";
import "./PrestigeClubv2.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library PrestigeClubCalculations {

    using SafeMath112 for uint112;

    function getPoolPayout(PrestigeClub.User storage user,  uint40 dayz, PrestigeClub.Pool[8] storage pools, PrestigeClub.PoolState[] storage states) public view returns (uint112){

        uint40 length = (uint40)(states.length);

        uint112 poolpayout = 0;

        if(user.qualifiedPools > 0){
            for(uint40 day = length - dayz ; day < length ; day++){


                uint112 numUsers = states[day].totalUsers;
                uint112 streamline = uint112(uint112(states[day].totalDeposits).mul(numUsers.sub(user.position))).div(numUsers);

                uint112 payout_day = 0;
                uint32 stateNumUsers = 0;
                for(uint8 j = 0 ; j < user.qualifiedPools ; j++){
                    uint112 pool_base = streamline.mul(pools[j].payoutQuote) / 1000000;

                    stateNumUsers = states[day].numUsers[j];

                    if(stateNumUsers != 0){
                        payout_day += pool_base.div(stateNumUsers);
                    }
                }

                poolpayout = poolpayout.add(payout_day);

            }
        }
        
        return poolpayout;
    }

    function getDownlinePayout(PrestigeClub.User storage user, PrestigeClub.DownlineBonusStage[4] storage downlineBonuses) public view returns (uint112){

        //Calculate Downline Bonus
        uint112 downlinePayout = 0;
        
        uint8 downlineBonus = user.downlineBonus;
        
        if(downlineBonus > 0){
            
            uint64 ownPercentage = downlineBonuses[downlineBonus - 1].payoutQuote;

            for(uint8 i = 0 ; i < downlineBonus; i++){

                uint64 quote = 0;
                if(i > 0){
                    quote = downlineBonuses[i - 1].payoutQuote;
                }

                uint64 percentage = ownPercentage - quote;
                if(percentage > 0){ //Requiring positivity and saving gas for 0, since that returns 0

                    downlinePayout = downlinePayout.add(user.downlineVolumes[i].mul(percentage) / 1000000);

                }

            }

            if(downlineBonus == 4){
                downlinePayout = downlinePayout.add(user.downlineVolumes[4].mul(50) / 1000000);
            }

        }
        return downlinePayout;
    }

    function getDownline(mapping(address => PrestigeClub.User) storage users, address adr) public view returns (uint112, uint128){
        uint112 sum;
        for(uint8 i = 0 ; i < users[adr].downlineVolumes.length ; i++){
            sum = sum.add(users[adr].downlineVolumes[i]);
        }

        return (sum, getDownlineUsers(users, adr));
    }

    function getDownlineUsers(mapping(address => PrestigeClub.User) storage users, address adr) private view returns (uint128){

        uint128 sum = 0;
        uint32 length = uint32(users[adr].referrals.length);
        sum += length;
        for(uint32 i = 0; i < length ; i++){
            sum += getDownlineUsers(users, users[adr].referrals[i]);
        }
        return sum;
    }

}