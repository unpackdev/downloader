//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Address.sol";
import "./ILPool.sol";
import "./IIceCream.sol";

contract CreamVotingPower {
    using Address for address payable;

    address public constant iceCream = 0x3986425b96F11972d31C78ff340908832C5c0043;

    address[] public lPool = [
        address(0x780F75ad0B02afeb6039672E6a6CEDe7447a8b45),
        address(0xBdc3372161dfd0361161e06083eE5D52a9cE7595),
        address(0xD5586C1804D2e1795f3FBbAfB1FBB9099ee20A6c),
        address(0xE618C25f580684770f2578FAca31fb7aCB2F5945)
    ];

    uint[] internal lPoolLockTime = [
        365 days, 730 days, 1095 days, 1461 days
    ];

    uint256 public MINIMUM_VOTING_POWER = 1e18;

    modifier isValidAddress(address wallet) {
        require(
            wallet != address(0),
            "VotingPower: Zero Address"
        );
        _;
    }

    function balanceOf(address _holder) public view isValidAddress(_holder) returns (uint256) {
        uint256 votingPower = _stakedInIceCream(_holder) + _stakedInLPool(_holder);

        return votingPower >= MINIMUM_VOTING_POWER ? votingPower : 0;
    }

    /**
     @notice CREAM staked in ice cream
     @param _holder Address of holder
     @return uint256 The cream token amount
    */
    function _stakedInIceCream(address _holder) internal view returns (uint256) {
        return IIceCream(iceCream).balanceOf(_holder);
    }

    /**
     @notice CREAM staked in long-term pools
     @param _holder Address of holder
     @return uint256 The cream token amount
    */
    function _stakedInLPool(address _holder) internal view returns (uint256) {
        uint256 totalStaked = 0;

        for (uint256 i = 0; i < 4; i++) {
            uint256 balance = ILPool(lPool[i]).balanceOf(_holder);

            // calculate voting power in proportion to remaining lock time
            uint256 releaseTime = ILPool(lPool[i]).releaseTime();
            uint256 currentTime = block.timestamp;
            if (currentTime >= releaseTime) {
                return 0;
            }
            uint balanceRemained = (balance * 1e18 / lPoolLockTime[i]) * (releaseTime - currentTime) / 1e18;

            totalStaked = totalStaked + balanceRemained;
        }

        return totalStaked;
    }
}
