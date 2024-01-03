pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./DistributionLibrary.sol";
import "./ICAVO.sol";
import "./IExcavoERC20.sol";
import "./IxCAVO.sol";
import "./ITeamDistribution.sol";

abstract contract TeamDistribution is ITeamDistribution, ICAVO, IExcavoERC20, ReentrancyGuard {
    using SafeMath for uint;
    using DistributionLibrary for DistributionLibrary.Data;

    event TeamDistributed(address indexed recipient, uint amount);

    uint public override totalTeamDistribution;
    DistributionLibrary.Data private distribution;

    constructor(uint32 _blocksInPeriod, address[] memory _team, uint[] memory _amounts) public {
        require(_team.length == _amounts.length, 'TeamDistribution: INVALID_PARAMS');
        uint total;
        for (uint i = 0; i < _team.length; ++i) {
            distribution.maxAmountOf[_team[i]] = _amounts[i];
            total = total.add(_amounts[i]);
        }
        totalTeamDistribution = total;
        distribution.blocksInPeriod = _blocksInPeriod;
    }

    function availableTeamMemberAmountOf(address account) external view override returns (uint) {
        return distribution.availableAmountOf(account);
    }

    function teamMemberClaim(uint amount) external override nonReentrant {
        distribution.claim(amount);
        emit TeamDistributed(msg.sender, amount);
    }

    function startTeamDistribution() external override nonReentrant {
        distribution.start();
    }
}