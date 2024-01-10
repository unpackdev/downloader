// SPDX-License-Identifier: GPL-3.0

import "./Clones.sol";
import "./Ownable.sol";
import "./TubbiesSweeper.sol";

pragma solidity ^0.8.0;

contract TubbiesSweeperFactory is Ownable {
    using Clones for address;
    address[] public cloneAddresses;

    function clone(uint256 numClones, address implementation) public onlyOwner {
        for (uint256 i=0; i < numClones; i++) {
            address c = implementation.clone();
            cloneAddresses.push(c);
        }
    }

    function fundClones() payable external {
        uint256 money = msg.value;
        for (uint256 i=0; i < cloneAddresses.length; i++) {
            TubbiesSweeper s = TubbiesSweeper(cloneAddresses[i]);
            s.getFunds{value: money/cloneAddresses.length}();
        }

    }

    function sweep(address tubbiesContract) external onlyOwner {
        for (uint256 i=0; i < cloneAddresses.length; i++) {
            TubbiesSweeper s = TubbiesSweeper(cloneAddresses[i]);
            s.sweep(tubbiesContract);
            
        }
    }

    function getBlockTimestamp() view external returns (uint256) {
        return block.timestamp;
    }

    function withdraw() public onlyOwner{
        for (uint256 i=0; i < cloneAddresses.length; i++) {
            TubbiesSweeper s = TubbiesSweeper(cloneAddresses[i]);
            s.withdraw();
        }
    }
}