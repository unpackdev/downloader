// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";

interface ITuna {
  function balanceOf(address owner) external view returns (uint);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
}

interface IToken {
  function ownerOf(uint id) external view returns (address);
}

contract Manager is Ownable {
    ITuna public tuna;
    IToken public token;

    uint public startDate = 1635714000; // (GMT): Sunday, 31 October 2021, 21:00:00, start date for the early supporters
    uint public startDateNewTokens = 1637013600; // GMT: Monday, 15 November 2021, 22:00:00, start date if there are new mints
    uint public genericCollectionId = 1200;

    uint public refreshRate = 86400; // 1 Day
    uint public basePrice = 100 ether; 
    uint public changeNamePrice = 500 ether; 
    uint public changeDescriptionPrice = 1000 ether; 
    bool public isRewardAvailable = true;

    mapping(uint => uint) public tokenIdLastUpdate;

    function setPricePerToken(uint _price) external onlyOwner {
        basePrice = _price;
    }
    
    function changeGenericCollectionId(uint _id) external onlyOwner {
        genericCollectionId = _id;
    }

    function setStartDate(uint _timestamp) external onlyOwner {
        startDate = _timestamp;
    }

    function setNewTokensStartDate(uint _timestamp) external onlyOwner {
        startDateNewTokens = _timestamp;
    }

    function setChangeNamePrice(uint _price) external onlyOwner {
        changeNamePrice = _price;
    }

    function setRefreshRate(uint _rate) external onlyOwner {
        refreshRate = _rate;
    }

    function setChangeDescriptionPrice(uint _price) external onlyOwner {
        changeDescriptionPrice = _price;
    }

    function setIsRewardAvailable(bool state) external onlyOwner {
        isRewardAvailable = state;
    }

    function setTuna(address _tuna) external onlyOwner {
        tuna = ITuna(_tuna);
    }

    function setToken(address _token) external onlyOwner {
        token = IToken(_token);
    }

    function sendReward(uint[] calldata _ids) external {
        require(isRewardAvailable, "Rewards are disabled");
        require(checkIfUserHasTokens(msg.sender, _ids) == true, "Some of Token Ids do not belong to this address");
        uint reward = calculateReward(_ids);

        if (reward > 0) {
            tuna.mint(msg.sender, reward);
            for (uint i = 0; i < _ids.length; i++) {
                tokenIdLastUpdate[_ids[i]] = block.timestamp;
            }
        }
    }

    function calculateReward(uint[] calldata _ids) public view returns (uint) {
        uint time = block.timestamp;
        uint reward = 0;

        for (uint i = 0; i < _ids.length; i++) {
            uint tokenUpdateTimestamp = tokenIdLastUpdate[_ids[i]];

            if (tokenUpdateTimestamp == 0) {
                // For freshly minted tokens start date is different
                tokenUpdateTimestamp = _ids[i] > genericCollectionId ? startDateNewTokens : startDate;
            }
            reward += (time - tokenUpdateTimestamp) / refreshRate * basePrice;
        }

        return reward;
    }

    function checkIfUserHasTokens(address _user, uint[] calldata _ids) public view returns (bool) {
        for (uint i = 0; i < _ids.length; i++) {
            if (token.ownerOf(_ids[i]) != _user) {
                return false;
            }
        }

        // Every token belongs to this user
        return true;
    }

    // Utility methods

    // Burn erc20 tokens to have a TX
    function changeTokenName() public {
        tuna.burn(msg.sender, changeNamePrice);
    }

    // Burn erc20 tokens to have a TX
    function changeTokenDescription() public {
        tuna.burn(msg.sender, changeDescriptionPrice);
    }
}
