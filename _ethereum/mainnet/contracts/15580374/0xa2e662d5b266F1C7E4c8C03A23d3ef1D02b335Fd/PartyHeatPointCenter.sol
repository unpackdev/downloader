// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

interface IPartyHeatPoint {
    function mint(address _account, uint256 _amount) external;
}

contract PartyHeatPointCenter is Ownable {
    IPartyHeatPoint public php;
    address public clubStreet;
    mapping(string => uint256) public rewardRules;
    mapping(string => mapping(uint256 => uint256)) public customRewardRules;

    constructor(IPartyHeatPoint _php, address _clubStreet) {
        rewardRules["join"] = 100 * 1e18;
        rewardRules["sendBounty"] = 1000 * 1e18;
        rewardRules["getBounty"] = 50 * 1e18;
        php = _php;
        clubStreet = _clubStreet;
    }

    modifier onlyClubStreet() {
        require(msg.sender == clubStreet, "PartyHeatPointCenter: Only ClubStreet can call");
        _;
    }

    function setNewCustomRewardRules(string memory _desc, uint256 _amount, uint256 _targetClubNumber) public onlyOwner {
        customRewardRules[_desc][_targetClubNumber] = _amount;
    }

    function setNewRewardRules(string memory _desc, uint256 _amount) public onlyOwner {
        rewardRules[_desc] = _amount;
    }

    function claim(address _account, uint256 _targetClubNum, string memory actionType) external onlyClubStreet {
        uint256 _rewards;
        if (customRewardRules[actionType][_targetClubNum] > 0) {
            _rewards = customRewardRules[actionType][_targetClubNum];
        } else {
            _rewards = rewardRules[actionType];
        }
        php.mint(_account, _rewards);
    }
}