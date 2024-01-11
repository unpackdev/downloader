// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";

import "./CmsnTreasury.sol";

contract CmsnTreasuryFactory is Ownable {
    event TreasuryCreated(address _tokenAddress, address _treasuryAddress);

    constructor() {}

    function createTreasury(address _tokenAddress, string memory _name)
        public
        onlyOwner
        returns (address)
    {
        CmsnTreasury treasury = new CmsnTreasury(IERC20(_tokenAddress), _name);

        treasury.setTreasuryManager(owner());
        treasury.setTreasuryManager(address(this));

        treasury.setVestingPeriod(4 weeks);

        emit TreasuryCreated(_tokenAddress, address(treasury));

        return address(treasury);
    }
}
