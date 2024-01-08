// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IERC20.sol";

import "./RoleAware.sol";
import "./Fund.sol";
import "./CrossMarginTrading.sol";
import "./IncentiveReporter.sol";

/** 
@title Here we support staking for MFI incentives as well as
staking to perform the maintenance role.
*/
contract Admin is RoleAware {
    /// Margenswap (MFI) token address
    address public immutable MFI;
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;

    uint256 public constant mfiStakeTranche = 1;

    uint256 public maintenanceStakePerBlock = 15 ether;
    mapping(address => address) public nextMaintenanceStaker;
    mapping(address => mapping(address => bool)) public maintenanceDelegateTo;
    address public currentMaintenanceStaker;
    address public prevMaintenanceStaker;
    uint256 public currentMaintenanceStakerStartBlock;
    address public immutable lockedMFI;

    constructor(
        address _MFI,
        address _lockedMFI,
        address lockedMFIDelegate,
        address _roles
    ) RoleAware(_roles) {
        MFI = _MFI;
        lockedMFI = _lockedMFI;

        // for initialization purposes and to ensure availability of service
        // the team's locked MFI participate in maintenance staking only
        // (not in the incentive staking part)
        // this implies some trust of the team to execute, which we deem reasonable
        // since the locked stake is temporary and diminishing as well as the fact
        // that the team is heavily invested in the protocol and incentivized
        // by fees like any other maintainer
        // furthermore others could step in to liquidate via the attacker route
        // and take away the team fees if they were delinquent
        nextMaintenanceStaker[_lockedMFI] = _lockedMFI;
        currentMaintenanceStaker = _lockedMFI;
        prevMaintenanceStaker = _lockedMFI;
        maintenanceDelegateTo[_lockedMFI][lockedMFIDelegate] = true;
        currentMaintenanceStakerStartBlock = block.number;
    }

    /// Maintence stake setter
    function setMaintenanceStakePerBlock(uint256 amount)
        external
        onlyOwnerExec
    {
        maintenanceStakePerBlock = amount;
    }

    function _stake(address holder, uint256 amount) internal {
        Fund(fund()).depositFor(holder, MFI, amount);

        stakes[holder] += amount;
        totalStakes += amount;

        IncentiveReporter.addToClaimAmount(MFI, holder, amount);
    }

    function _withdrawStake(
        address holder,
        uint256 amount,
        address recipient
    ) internal {
        // overflow failure desirable
        stakes[holder] -= amount;
        totalStakes -= amount;
        Fund(fund()).withdraw(MFI, recipient, amount);

        IncentiveReporter.subtractFromClaimAmount(MFI, holder, amount);
    }

    /// Withdraw stake for sender
    function withdrawStake(uint256 amount) external {
        require(
            !isAuthorizedStaker(msg.sender),
            "You can't withdraw while you're authorized staker"
        );
        _withdrawStake(msg.sender, amount, msg.sender);
    }

    /// Deposit maintenance stake
    function depositMaintenanceStake(uint256 amount) external {
        require(
            amount + stakes[msg.sender] >= maintenanceStakePerBlock,
            "Insufficient stake to call even one block"
        );
        _stake(msg.sender, amount);
        if (nextMaintenanceStaker[msg.sender] == address(0)) {
            nextMaintenanceStaker[msg.sender] = getUpdatedCurrentStaker();
            nextMaintenanceStaker[prevMaintenanceStaker] = msg.sender;
        }
    }

    function getMaintenanceStakerStake(address staker)
        public
        view
        returns (uint256)
    {
        if (staker == lockedMFI) {
            return IERC20(MFI).balanceOf(lockedMFI) / 2;
        } else {
            return stakes[staker];
        }
    }

    function getUpdatedCurrentStaker() public returns (address) {
        uint256 currentStake =
            getMaintenanceStakerStake(currentMaintenanceStaker);
        if (
            (block.number - currentMaintenanceStakerStartBlock) *
                maintenanceStakePerBlock >=
            currentStake
        ) {
            currentMaintenanceStakerStartBlock = block.number;

            prevMaintenanceStaker = currentMaintenanceStaker;
            currentMaintenanceStaker = nextMaintenanceStaker[
                currentMaintenanceStaker
            ];
            currentStake = getMaintenanceStakerStake(currentMaintenanceStaker);

            if (maintenanceStakePerBlock > currentStake) {
                // delete current from daisy chain
                address nextOne =
                    nextMaintenanceStaker[currentMaintenanceStaker];
                nextMaintenanceStaker[prevMaintenanceStaker] = nextOne;
                nextMaintenanceStaker[currentMaintenanceStaker] = address(0);

                currentMaintenanceStaker = nextOne;
                currentStake = getMaintenanceStakerStake(
                    currentMaintenanceStaker
                );
            }
        }

        return currentMaintenanceStaker;
    }

    function viewCurrentMaintenanceStaker()
        public
        view
        returns (address staker, uint256 startBlock)
    {
        staker = currentMaintenanceStaker;
        uint256 currentStake = getMaintenanceStakerStake(staker);
        startBlock = currentMaintenanceStakerStartBlock;
        if (
            (block.number - startBlock) * maintenanceStakePerBlock >=
            currentStake
        ) {
            staker = nextMaintenanceStaker[staker];
            currentStake = getMaintenanceStakerStake(staker);
            startBlock = block.number;

            if (maintenanceStakePerBlock > currentStake) {
                staker = nextMaintenanceStaker[staker];
            }
        }
    }

    /// Add a delegate for staker
    function addDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = true;
    }

    /// Remove a delegate for staker
    function removeDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = false;
    }

    function isAuthorizedStaker(address caller)
        public
        returns (bool isAuthorized)
    {
        address currentStaker = getUpdatedCurrentStaker();
        isAuthorized =
            currentStaker == caller ||
            maintenanceDelegateTo[currentStaker][caller];
    }

    /// Penalize a staker
    function penalizeMaintenanceStake(
        address maintainer,
        uint256 penalty,
        address recipient
    ) external returns (uint256 stakeTaken) {
        require(
            isStakePenalizer(msg.sender),
            "msg.sender not authorized to penalize stakers"
        );
        if (penalty > stakes[maintainer]) {
            stakeTaken = stakes[maintainer];
        } else {
            stakeTaken = penalty;
        }
        _withdrawStake(maintainer, stakeTaken, recipient);
    }
}
