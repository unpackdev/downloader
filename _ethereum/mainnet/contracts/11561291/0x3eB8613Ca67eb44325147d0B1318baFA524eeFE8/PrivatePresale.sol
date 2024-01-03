pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./DistributionLibrary.sol";
import "./ICAVO.sol";
import "./IExcavoERC20.sol";
import "./IxCAVO.sol";
import "./IPrivatePresale.sol";

abstract contract PrivatePresale is IPrivatePresale, ICAVO, IExcavoERC20, ReentrancyGuard {
    using SafeMath for uint;
    using DistributionLibrary for DistributionLibrary.Data;

    event PrivateDistributionInitialized(address indexed recipient, uint amount);
    event PrivateDistributed(address indexed recipient, uint amount);

    DistributionLibrary.Data private distribution;
    uint public override totalPrivatePresaleDistribution;
    uint public override privatePresaleDistributed;

    constructor(uint32 _blocksInPeriod, uint _totalPrivatePresaleDistribution) public {
        distribution.blocksInPeriod = _blocksInPeriod;
        totalPrivatePresaleDistribution = _totalPrivatePresaleDistribution;
    }

    function distribute(address[] calldata _accounts, uint[] calldata _amounts) external override nonReentrant {
        require(msg.sender == ICAVO(address(this)).creator(), 'PrivatePresale: FORBIDDEN');
        require(_accounts.length == _amounts.length, 'PrivatePresale: INVALID_LENGTH');
        uint _distributed = privatePresaleDistributed;
        for (uint i = 0; i < _accounts.length; ++i) {
            uint max = distribution.maxAmountOf[_accounts[i]].add(_amounts[i]);
            distribution.maxAmountOf[_accounts[i]] = max;
            _distributed = _distributed.add(_amounts[i]);
            emit PrivateDistributionInitialized(_accounts[i], max);
        }
        require(_distributed <= totalPrivatePresaleDistribution, 'PrivatePresale: LIMIT_EXCEEDED');
        privatePresaleDistributed = _distributed;
    }

    function editDistributed(address _account, uint _amount) external override nonReentrant {
        // disabled if admin has started the private presale distribution
        require(distribution.unlockBlock == 0 && msg.sender == ICAVO(address(this)).creator(), 'PrivatePresale: FORBIDDEN');
        uint _distributed = privatePresaleDistributed.sub(distribution.maxAmountOf[_account]).add(_amount);
        distribution.maxAmountOf[_account] = _amount;
        require(_distributed <= totalPrivatePresaleDistribution, 'PrivatePresale: LIMIT_EXCEEDED');
        privatePresaleDistributed = _distributed;
        emit PrivateDistributionInitialized(_account, _amount);
    }

    function availablePrivatePresaleAmountOf(address account) external view override returns (uint) {
        return distribution.availableAmountOf(account);
    }

    function privatePresaleClaim(uint amount) external override nonReentrant {
        distribution.claim(amount);
        emit PrivateDistributed(msg.sender, amount);
    }

    function startPrivatePresaleDistribution() external override nonReentrant {
        // called, once admin has distributed all of the presale tokens
        require(privatePresaleDistributed == totalPrivatePresaleDistribution, 'PrivatePresale: DISTRIBUTION_UNFINISHED');
        distribution.start();
    }
}