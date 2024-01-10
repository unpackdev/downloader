// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./IVirtualBalanceWrapper.sol";
import "./IBaseReward.sol";
import "./ISupplyBooster.sol";

interface ILendFlareGauge {
    function updateReward(address addr) external returns (bool);
}

interface ILendFlareMinter {
    function mintFor(address gauge_addr, address _for) external;
}

interface ILendflareToken {
    function minter() external view returns (address);
}

interface ISupplyPoolGaugeFactory {
    function createGauge(
        address _virtualBalance,
        address _lendflareToken,
        address _lendflareVotingEscrow,
        address _lendflareGaugeModel,
        address _lendflareTokenMinter
    ) external returns (address);
}

interface ILendflareGaugeModel {
    function addGauge(address _gauge, uint256 _weight) external;

    function toggleGauge(address _gauge, bool _state) external;
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

contract SupplyPoolExtraRewardFactory is ReentrancyGuard, Initializable {
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public owner;

    address public supplyBooster;
    address public supplyRewardFactory;
    address public supplyPoolGaugeFactory;
    address public lendflareVotingEscrow;
    address public lendflareToken;
    address public lendflareGaugeModel;

    mapping(uint256 => address) public veLendFlarePool; // pid => extra rewards
    mapping(uint256 => address) public gaugePool; // pid => extra rewards

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(
        address _supplyBooster,
        address _supplyRewardFactory,
        address _supplyPoolGaugeFactory,
        address _lendflareGaugeModel,
        address _lendflareVotingEscrow,
        address _lendflareToken,
        address _owner
    ) public initializer {
        owner = _owner;
        supplyBooster = _supplyBooster;
        supplyRewardFactory = _supplyRewardFactory;
        supplyPoolGaugeFactory = _supplyPoolGaugeFactory;
        lendflareVotingEscrow = _lendflareVotingEscrow;
        lendflareToken = _lendflareToken;
        lendflareGaugeModel = _lendflareGaugeModel;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "SupplyPoolExtraRewardFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createPool(
        uint256 _pid,
        address _underlyToken,
        address _virtualBalance,
        bool _isErc20
    ) internal {
        address lendflareMinter = ILendflareToken(lendflareToken).minter();
        require(lendflareMinter != address(0), "!lendflareMinter");

        address poolGauge = ISupplyPoolGaugeFactory(supplyPoolGaugeFactory)
            .createGauge(
                _virtualBalance,
                lendflareToken,
                lendflareVotingEscrow,
                lendflareGaugeModel,
                lendflareMinter
            );

        // default weight = 100 * 1e18
        ILendflareGaugeModel(lendflareGaugeModel).addGauge(poolGauge, 100e18);

        address rewardVeLendFlarePool;

        if (_isErc20) {
            rewardVeLendFlarePool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(
                    _underlyToken,
                    lendflareVotingEscrow,
                    address(this)
                );
        } else {
            rewardVeLendFlarePool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(address(0), lendflareVotingEscrow, address(this));
        }

        IBaseReward(rewardVeLendFlarePool).addOwner(lendflareVotingEscrow);

        veLendFlarePool[_pid] = rewardVeLendFlarePool;
        gaugePool[_pid] = poolGauge;
    }

    function updateOldPool(uint256 _pid) public {
        require(
            msg.sender == owner,
            "SupplyPoolExtraRewardFactory: !authorized updateOldPool"
        );
        require(veLendFlarePool[_pid] == address(0), "!veLendFlarePool");
        require(gaugePool[_pid] == address(0), "!gaugePool");

        (
            address underlyToken,
            ,
            ,
            address virtualBalance,
            bool isErc20,

        ) = ISupplyBooster(supplyBooster).poolInfo(_pid);

        createPool(_pid, underlyToken, virtualBalance, isErc20);
    }

    function addExtraReward(
        uint256 _pid,
        address _lpToken,
        address _virtualBalance,
        bool _isErc20
    ) public {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized addExtraReward"
        );

        createPool(_pid, _lpToken, _virtualBalance, _isErc20);
    }

    function toggleShutdownPool(uint256 _pid, bool _state) public {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized toggleShutdownPool"
        );

        ILendflareGaugeModel(lendflareGaugeModel).toggleGauge(
            gaugePool[_pid],
            _state
        );
    }

    function getRewards(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized getRewards"
        );

        address lendflareMinter = ILendflareToken(lendflareToken).minter();

        if (lendflareMinter != address(0)) {
            ILendFlareMinter(lendflareMinter).mintFor(gaugePool[_pid], _for);
        }
    }

    function beforeStake(uint256 _pid, address _for) public nonReentrant {}

    function afterStake(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized afterStake"
        );

        ILendFlareGauge(gaugePool[_pid]).updateReward(_for);
    }

    function beforeWithdraw(uint256 _pid, address _for) public nonReentrant {}

    function afterWithdraw(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized afterWithdraw"
        );

        ILendFlareGauge(gaugePool[_pid]).updateReward(_for);
    }

    function getVeLFTUserRewards(uint256[] memory _pids) public nonReentrant {
        for (uint256 i = 0; i < _pids.length; i++) {
            if (IBaseReward(veLendFlarePool[_pids[i]]).earned(msg.sender) > 0) {
                IBaseReward(veLendFlarePool[_pids[i]]).getReward(msg.sender);
            }
        }
    }

    function notifyRewardAmount(
        uint256 _pid,
        address _underlyToken,
        uint256 _amount
    ) public payable nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized notifyRewardAmount"
        );

        if (_underlyToken == address(0)) {
            payable(veLendFlarePool[_pid]).sendValue(_amount);
        } else {
            IERC20(_underlyToken).safeTransfer(veLendFlarePool[_pid], _amount);
        }

        IBaseReward(veLendFlarePool[_pid]).notifyRewardAmount(_amount);
    }

    receive() external payable {}
}
