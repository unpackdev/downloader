// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the EarlyBird.
 */
interface IEarlyBird {
    function isEarlyBird(address addr_) external view returns (bool);
}

abstract contract EarlyBird is IEarlyBird {

    bool public earlyBirdRound = true;

    mapping(address => bool) public earlyBirds;

    /**
     * @dev Set the early bird addresses.
     * @param _addrs The early bird addresses.
     */
    function setEarlyBirds(address[] memory _addrs) virtual public {
        require(_addrs.length > 0, "EarlyBird: no early birds");
        for (uint256 i = 0; i < _addrs.length; i++) {
            earlyBirds[_addrs[i]] = true;
        }
    }

    /**
     * @dev Set the early bird round.
     * @param round_ The early bird round.
     */
    function setEarlyBirdRound(bool round_) virtual public {
        earlyBirdRound = round_;
    }

    /**
     * @dev Check if the address is the early bird or it is not early bird round.
     * @param addr_ The address to check.
     */
    function isEarlyBird(address addr_) public view returns (bool) {
        return (!earlyBirdRound || (earlyBirdRound && earlyBirds[addr_]));
    }
    // 10000000
    // 10000000

}
