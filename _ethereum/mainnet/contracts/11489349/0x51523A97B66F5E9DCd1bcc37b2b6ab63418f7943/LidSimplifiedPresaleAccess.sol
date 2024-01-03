pragma solidity 0.5.16;

import "./Initializable.sol";
import "./SafeMath.sol";
//TODO: Replace with abstract sc or interface. mocks should only be for testing
import "./LidStaking.sol";

contract LidSimplifiedPresaleAccess is Initializable {
    using SafeMath for uint256;
    LidStaking private staking;

    uint256[5] private cutoffs;

    function initialize(LidStaking _staking) external initializer {
        staking = _staking;
        //Precalculated
        cutoffs = [
            500000 ether,
            100000 ether,
            50000 ether,
            25000 ether,
            1 ether
        ];
    }

    function getAccessTime(address account, uint256 startTime)
        external
        view
        returns (uint256 accessTime)
    {
        uint256 stakeValue = staking.stakeValue(account);
        if (stakeValue == 0) return startTime.add(15 minutes);
        if (stakeValue >= cutoffs[0]) return startTime;
        uint256 i = 0;
        uint256 stake2 = cutoffs[0];
        while (stake2 > stakeValue && i < cutoffs.length) {
            i++;
            stake2 = cutoffs[i];
        }
        return startTime.add(i.mul(3 minutes));
    }
}
