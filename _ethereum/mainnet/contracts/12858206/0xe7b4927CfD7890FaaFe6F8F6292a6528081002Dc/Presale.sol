//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PresaleToken is ERC20{

    uint lockEnd;
    uint presaleCount = 0;
    address[] investors;
    mapping (address => uint) public presaleOwedPerPeriod;
    uint private constant ONE_WEEK = 604800;

    constructor(string memory _name, string memory _symbol, address[] memory _investors, uint[] memory _amounts)ERC20(_name, _symbol){
        require(_investors.length == _amounts.length, "The arrays size must match");
        uint subFromTotal = 0;
        investors = _investors;
        for(uint i = 0; i < _investors.length; i++){
            presaleOwedPerPeriod[_investors[i]] = _amounts[i]/10;
            subFromTotal += _amounts[i];
        }
        
        lockEnd = block.timestamp + ONE_WEEK;
        _mint(msg.sender, 10000000000 * 10 ** 9);
    }

    //override decimals since _setupDecimals() is deprecated

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /// @dev function to send out 10% of presale funds to investors each week (max of 10 times)
    function sendPresaleTokens()external{
        require(lockEnd <= block.timestamp, "Can only withdrawl 10% each week since launch");
        require(presaleCount < 10, "Can only send presale funds 10 times");
        lockEnd += ONE_WEEK;
        presaleCount += 1;
        for(uint i = 0; i < investors.length; i++){
            _mint(investors[i],presaleOwedPerPeriod[investors[i]]);
        }
    }
}