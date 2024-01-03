// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./BondlyToken.sol";

contract BondlyTokenStakingRewards is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public name = "StakingRewards";
    uint256 public maxCap = 400000000 ether;
    uint256 public sent;

    BondlyToken public bondToken;

    constructor (address _bondTokenAddress) public {
        bondToken = BondlyToken(_bondTokenAddress);
        transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }

    function getAvailableTokens() onlyOwner external view returns (uint256) {
        return maxCap.sub(sent);
    }

    function send(address to, uint256 amount) onlyOwner nonReentrant external {
        require(sent.add(amount) <= maxCap, "capitalization exceeded");
        sent = sent.add(amount);
        bondToken.transfer(to, amount);
    }

}