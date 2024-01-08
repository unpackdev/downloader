// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./CryptoFoxes.sol";
import "./CryptoFoxesOrigins.sol";
import "./ICryptoFoxesSteakBurnable.sol";
import "./CryptoFoxesAllowed.sol";

// @author: miinded.com

/////////////////////////////////////////////////////////////////////////////////////                                                                                                                                                          
//                                                                                 //
//                                                                                 //
//                    ((((((((.                (((((                               //
//                    @@@@@@@@.                @@@@@                               //
//                    @@@&&&%%@@@              @@@&&@@@                            //
//                    @@@%%%@@#((@@@        @@@&&&&&%%%@@@                         //
//                    @@@(((%%,..(((@@&     @@@&&&%%///@@@                         //
//                 %@@(((@@@..   ...@@&     @@@%%%/////(((@@%                      //
//                 %@@///@@&        ///@@@@@%%%%%%((//////@@%                      //
//                 (%%///@@&        @@@/////(((@@@%%%%%///@@%                      //
//                 (%%///@@&     %%%(((///////////((@@@(((%%#                      //
//                 (%%///...  #%%/////////////////////////%%#                      //
//                 %@@///@@@@@#((/////////////////////////@@%                      //
//                 %@@///%%%%%(((////////((((((/////((((((%%#//                    //
//                 %@@///(((/////////////((((((/////((((((((#@@                    //
//               @@#((//////////////////////////////////////(%%                    //
//               @@#((//////////////&&&&&&&&&&&////////&&&&&&%%                    //
//               @@(/////////////&&&     (((   ////////(((  ,&&                    //
//            @@@((///////////(((&&&     ###   ///(((((###  ,&&%%%                 //
//            @@@/////......     (((///////////((#&&&&&&&&..,((%%%                 //
//            @@@((.                ..,//,.....     &&&     .//@@@                 //
//               @@#((...                      &&&&&...&&&     @@@                 //
//    @@@@@      @@#((                                       ..@@@                 //
// @@@..(%%        %@@%%%%%%.....                         ..*%%                    //
// (((../((***     /((///////////*************************/////                    //
//      ...%%%              @@&%%%%%%%%%%%%%%%%%%%%%@@@@@@%%#                      //
//         ...%%%        &&%##(((.................**@@@                            //
//            ...@@,     %%%/////...              ..(((@@@                         //
// ...        ///((&@@@@@////////%%%             .%%(((@@@              Miinded    //
// ...     ////////(((@@@/////(((%%%             .%%((((((%%#                      //
/////////////////////////////////////////////////////////////////////////////////////

contract CryptoFoxesSteak is Ownable, ERC20, ERC20Burnable, CryptoFoxesAllowed, ICryptoFoxesSteakBurnable {
    using SafeMath for uint256;

    event RewardPaid(address indexed user, uint256 reward);

    mapping (address => uint256) private _rewards;
    uint256 public pause = 0;
    uint256 public endRewards = 0;

    constructor() ERC20("CryptoFoxesSteak", "$STEAK") {
        endRewards = block.timestamp + (365 days * 10);
    }

    modifier isNotPaused() {
        require(isPaused() == false, "Contract Pause");
        _;
    }
  
    function addRewards(address _to, uint _count) public override isFoxContract isNotPaused {
       _rewards[_to] = _rewards[_to].add(_count);
    }

    function burnSteaks( address _to, uint _count) public override isFoxContract isNotPaused {
        require (balanceOf(_to) >= _count, "Not enough");
        burnFrom(_to, _count);
    }

    function setPause(uint256 _pause) public onlyOwner{
        pause = _pause;
    }
    function isPaused() public override view returns(bool) {
        return pause > 0;
    }

    function dateEndRewards() external override view returns(uint256) {
        return endRewards;
    }
    function getRewards(address _owner) public view returns(uint256){
        return _rewards[_owner];
    }
    function withdrawRewards(address _to) public override isFoxContract isNotPaused{
        _withdraw(_to);
    }
    function withdrawRewardsFrom() public isNotPaused{
        _withdraw(_msgSender());
    }
    function _withdraw(address _to) private{
        require(_rewards[_to] > 0, "Collect your reward before");

        uint256 reward = _rewards[_to];

        _rewards[_to] = 0;

        _mint(_to, reward);

        emit RewardPaid(_to, reward);
    }

    function addEndRewards(uint256 _time) external isFoxContract {
        endRewards = endRewards.add(_time);
    }
    function burnEndRewards(uint256 _time) external isFoxContract {
        endRewards = endRewards.sub(_time);
    }
}
