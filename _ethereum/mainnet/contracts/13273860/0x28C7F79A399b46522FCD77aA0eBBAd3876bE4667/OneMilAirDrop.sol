// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./1MIL.sol";

contract OneMilAirDrop is Ownable {

    uint256 constant PRIZE = 20000000000000000000;
    mapping(address => bool) winners;

    MIL1 oneMil;

    constructor(MIL1 _oneMil){
        oneMil = _oneMil;
    }

    function addWinners(address[] calldata _winners) public onlyOwner {
        for (uint i; i < _winners.length; i++) {
            winners[_winners[i]] = true;
        }
    }


    function lookup(address winner) public view returns (uint256) {
        if (winners[winner]) {
            return PRIZE;
        } else {
            return 0;
        }
    }

    function withdraw() public {
        require(winners[msg.sender], 'OneMilAirDrop: Already withdrew');
        oneMil.transfer(msg.sender, PRIZE);
        winners[msg.sender] = false;
    }

    function adminWithdraw(uint256 amount) public onlyOwner {
        oneMil.transfer(owner(), amount);
    }

}
