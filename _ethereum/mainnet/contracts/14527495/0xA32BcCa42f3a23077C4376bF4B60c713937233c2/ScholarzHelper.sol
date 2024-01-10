// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";

interface IScholarz {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface ISkoolverse {
    function placedBy(uint) external view returns(address);
}

contract ScholarzHelper is Ownable {
    
    IScholarz public Scholarz = IScholarz(0xdd67892E722bE69909d7c285dB572852d5F8897C);
    ISkoolverse public Skoolverse = ISkoolverse(0x790d870C0D8443b56269bE283AB4023f6F069dB2);

    function setAddresses(address scholarz, address skoolverse) external onlyOwner {
        Scholarz = IScholarz(scholarz);
        Skoolverse = ISkoolverse(skoolverse);
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        uint sum;
        unchecked {
            for (uint i = 1; i <= 2500; ++i) {
                if (Skoolverse.placedBy(i) == owner) {
                    sum++;
                }
            }
        }
        return Scholarz.balanceOf(owner) + sum;
    }

}