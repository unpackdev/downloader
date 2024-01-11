// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
    function decimals() external returns (uint8);
}

contract WUTPublicPresale is ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    // Constants
    uint256 public constant EXTRA_PRICE = 3;
    uint256 public constant MAX_ALLOCATION = 3_000_000 * 10**18;

    uint256 public constant PIRANHA_ALLOCATION_FACTOR = 3000; // 30%
    uint256 public constant WHALE_ALLOCATION_FACTOR = 3000; // 30%

    uint256 public PIRANHA_BLOCKS_COUNT;
    uint256 public MIN_WHALE_DEPOSIT;
    uint256 public SOFT_CAP;
    uint256 public HARD_CAP;
    uint256 public MIN_TOTAL_DEPOSIT;

    uint256 public REL; // WUT / Sale Token decimals relation

    // Parameters
    uint256 public firstStageStartBlock;
    uint256 public secondStageStartBlock;
    uint256 public presaleEndBlock;

    address public treasurer;
    IERC20Upgradeable public saleToken;
    IERC20Upgradeable public WUT;

    // State
    bool public allowClaim;
    bool public successfulPresale;

    uint256 public totalDeposit;
    mapping(address => uint256) public depositOf;

    uint256 public piranhaTotalDeposit;
    mapping(address => uint256) public piranhaDepositOf;

    uint256 public whaleTotalDeposit;
    mapping(address => uint256) public whaleDepositOf;

    uint256 public sharkTotalDeposit;
    mapping(address => uint256) public sharkDepositOf;

    // Events
    event Deposit(address indexed investor, uint256 amount, uint256 investorDeposit, uint256 totalDeposit);
    event Withdraw(address indexed investor, uint256 amount, uint256 investorDeposit, uint256 totalDeposit);
    event Claim(address indexed investor, uint256 claimAmount, uint256 depositAmount);

    event WhaleDeposit(
        address indexed investor,
        uint256 amount,
        uint256 investorWhaleDeposit,
        uint256 whaleTotalDeposit
    );
    event PiranhaDeposit(
        address indexed investor,
        uint256 amount,
        uint256 investorPiranhaDeposit,
        uint256 piranhaTotalDeposit
    );
    event WhaleWithdraw(
        address indexed investor,
        uint256 amount,
        uint256 investorWhaleDeposit,
        uint256 whaleTotalDeposit
    );
    event PiranhaWithdraw(
        address indexed investor,
        uint256 amount,
        uint256 investorPiranhaDeposit,
        uint256 piranhaTotalDeposit
    );

    event CloseSale(bool successful, uint256 totalInvested, uint256 totalAllocation);

    // Libraries
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        uint256 _firstStageStartBlock,
        uint256 _secondStageStartBlock,
        uint256 _presaleEndBlock,
        uint256 _fastestBlocks,
        uint256 _minWhaleDeposit,
        address _saleToken,
        address _wut,
        address _treasurer
    ) external initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        firstStageStartBlock = _firstStageStartBlock;
        secondStageStartBlock = _secondStageStartBlock;
        presaleEndBlock = _presaleEndBlock;
        PIRANHA_BLOCKS_COUNT = _fastestBlocks;

        treasurer = _treasurer;
        saleToken = IERC20Upgradeable(_saleToken);
        WUT = IERC20Upgradeable(_wut);

        uint256 dec = IERC20Detailed(_saleToken).decimals();

        SOFT_CAP = 1_000_000 * 10**dec;
        HARD_CAP = 7_000_000 * 10**dec;
        REL = 10**(18 - dec);
        MIN_TOTAL_DEPOSIT = 100_000 * 10**dec;
        MIN_WHALE_DEPOSIT = _minWhaleDeposit;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(block.number >= firstStageStartBlock, "Public presale is not active yet");
        require(block.number < secondStageStartBlock, "Unable to deposit after second stage starts");
        saleToken.safeTransferFrom(_msgSender(), address(this), amount);

        if (depositOf[_msgSender()] >= MIN_WHALE_DEPOSIT) {
            whaleTotalDeposit += amount;
            whaleDepositOf[_msgSender()] += amount;
            emit WhaleDeposit(_msgSender(), amount, whaleDepositOf[_msgSender()], whaleTotalDeposit);
        } else if (depositOf[_msgSender()] + amount >= MIN_WHALE_DEPOSIT) {
            whaleTotalDeposit += depositOf[_msgSender()] + amount;
            whaleDepositOf[_msgSender()] += depositOf[_msgSender()] + amount;
            emit WhaleDeposit(_msgSender(), amount, whaleDepositOf[_msgSender()], whaleTotalDeposit);
        }

        if (block.number - firstStageStartBlock <= PIRANHA_BLOCKS_COUNT) {
            piranhaTotalDeposit += amount;
            piranhaDepositOf[_msgSender()] += amount;
            emit PiranhaDeposit(_msgSender(), amount, piranhaDepositOf[_msgSender()], piranhaTotalDeposit);
        }

        if (
            depositOf[_msgSender()] + amount >= MIN_WHALE_DEPOSIT &&
            sharkDepositOf[_msgSender()] != piranhaDepositOf[_msgSender()]
        ) {
            sharkTotalDeposit -= sharkDepositOf[_msgSender()];
            sharkTotalDeposit += piranhaDepositOf[_msgSender()];
            sharkDepositOf[_msgSender()] = piranhaDepositOf[_msgSender()];
        }

        totalDeposit += amount;
        depositOf[_msgSender()] += amount;

        emit Deposit(_msgSender(), amount, depositOf[_msgSender()], totalDeposit);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        require(block.number < presaleEndBlock, "Unable to withdraw funds after presale ends");
        require(amount > 0, "Unable to withdraw 0 amount");

        totalDeposit -= amount;
        depositOf[_msgSender()] -= amount;

        if (whaleDepositOf[_msgSender()] >= amount + MIN_WHALE_DEPOSIT) {
            whaleDepositOf[_msgSender()] -= amount;
            whaleTotalDeposit -= amount;
            emit WhaleWithdraw(_msgSender(), amount, whaleDepositOf[_msgSender()], whaleTotalDeposit);
        } else if (whaleDepositOf[_msgSender()] > 0) {
            whaleTotalDeposit -= whaleDepositOf[_msgSender()];
            whaleDepositOf[_msgSender()] = 0;
            if (sharkDepositOf[_msgSender()] > 0) {
                sharkTotalDeposit -= sharkDepositOf[_msgSender()];
                sharkDepositOf[_msgSender()] = 0;
            }
            emit WhaleWithdraw(_msgSender(), amount, whaleDepositOf[_msgSender()], whaleTotalDeposit);
        }

        if (piranhaDepositOf[_msgSender()] > amount) {
            piranhaDepositOf[_msgSender()] -= amount;
            piranhaTotalDeposit -= amount;
            emit PiranhaWithdraw(_msgSender(), amount, piranhaDepositOf[_msgSender()], piranhaTotalDeposit);
        } else if (piranhaDepositOf[_msgSender()] > 0) {
            piranhaTotalDeposit -= piranhaDepositOf[_msgSender()];
            piranhaDepositOf[_msgSender()] = 0;
            if (sharkDepositOf[_msgSender()] > 0) {
                sharkTotalDeposit -= sharkDepositOf[_msgSender()];
                sharkDepositOf[_msgSender()] = 0;
            }
            emit PiranhaWithdraw(_msgSender(), amount, piranhaDepositOf[_msgSender()], piranhaTotalDeposit);
        }

        if (sharkDepositOf[_msgSender()] >= amount) {
            sharkDepositOf[_msgSender()] -= amount;
            sharkTotalDeposit -= amount;
        } else {
            sharkTotalDeposit -= sharkDepositOf[_msgSender()];
            sharkDepositOf[_msgSender()] = 0;
        }

        saleToken.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount, depositOf[_msgSender()], totalDeposit);
    }

    function claim() external nonReentrant whenNotPaused {
        require(allowClaim, "Unable to claim WUT before presale ends");
        uint256 depositAmount = depositOf[_msgSender()];

        if (successfulPresale) {
            uint256 claimAmount = calcClaimAmount(_msgSender());
            uint256 usedDeposit = (claimAmount * min(totalDeposit, HARD_CAP)) / calcTotalAllocation();
            uint256 returnAmount = depositAmount > usedDeposit ? depositAmount - usedDeposit : 0;
            WUT.safeTransfer(_msgSender(), min(claimAmount, WUT.balanceOf(address(this))));
            if (returnAmount > 0) {
                saleToken.transfer(_msgSender(), min(returnAmount, saleToken.balanceOf(address(this))));
            }
            if (claimAmount > 0) {
                emit Claim(_msgSender(), claimAmount, depositAmount);
            }
        } else {
            saleToken.transfer(_msgSender(), depositAmount);
        }

        depositOf[_msgSender()] = 0;
        whaleDepositOf[_msgSender()] = 0;
        piranhaDepositOf[_msgSender()] = 0;
        sharkDepositOf[_msgSender()] = 0;
    }

    function drawOut() external nonReentrant {
        require(block.number >= presaleEndBlock, "Unable to draw out funds before presale ends");
        require(!allowClaim, "Unable to draw out funds twice");
        uint256 wutBalance = WUT.balanceOf(address(this));

        if (totalDeposit >= MIN_TOTAL_DEPOSIT) {
            saleToken.safeTransfer(treasurer, min(totalDeposit, HARD_CAP));
            uint256 totalAllocation = calcTotalAllocation();
            require(
                wutBalance >= totalAllocation,
                "Unable to draw out funds before depositing allocated amount of WUT"
            );
            if (wutBalance > totalAllocation) {
                WUT.safeTransfer(treasurer, wutBalance - totalAllocation);
            }
            successfulPresale = true;
            emit CloseSale(true, min(totalDeposit, HARD_CAP), totalAllocation);
        } else {
            WUT.safeTransfer(treasurer, wutBalance);
            emit CloseSale(false, totalDeposit, 0);
        }

        if (!allowClaim) {
            allowClaim = true;
        }
    }

    function balanceOf(address investor)
        external
        view
        returns (
            uint256 depositAmount,
            uint256 claimAmount,
            uint256 returnAmount
        )
    {
        depositAmount = depositOf[investor];
        claimAmount = calcClaimAmount(investor);
        uint256 totalAllocation = calcTotalAllocation();
        if (totalAllocation > 0) {
            uint256 usedDeposit = (claimAmount * min(totalDeposit, HARD_CAP)) / totalAllocation;
            returnAmount = depositAmount > usedDeposit ? depositAmount - usedDeposit : 0;
        }
    }

    struct Parts {
        uint256 piranha;
        uint256 whale;
        uint256 seal;
    }

    function calcClaimAmount(address investor) internal view returns (uint256) {
        if (totalDeposit == 0) {
            return 0;
        }

        uint256 totalInvested = min(totalDeposit, HARD_CAP);
        (
            uint256 totalAllocation,
            uint256 whaleAllocation,
            uint256 piranhaAllocation,
            uint256 sealAllocation
        ) = calcAllocations(totalInvested);

        uint256 piranhaSpent = (piranhaAllocation * totalInvested) / totalAllocation;

        Parts memory parts;
        parts.piranha = calcPiranhaPart(investor, piranhaAllocation);
        parts.whale = calcWhalePart(
            investor,
            piranhaSpent,
            parts.piranha,
            whaleAllocation,
            totalInvested,
            totalAllocation
        );
        uint256 a = (parts.piranha * totalInvested) / totalAllocation + (parts.whale * totalInvested) / totalAllocation;
        parts.seal = depositOf[investor] > a
            ? ((depositOf[investor] - a) * sealAllocation) /
                (totalDeposit -
                    (piranhaAllocation * totalInvested) /
                    totalAllocation -
                    (whaleAllocation * totalInvested) /
                    totalAllocation)
            : 0;

        return parts.seal + parts.piranha + parts.whale;
    }

    function calcPiranhaPart(address investor, uint256 piranhaAllocation) private view returns (uint256) {
        uint256 _piranhaTotalDeposit = piranhaTotalDeposit;
        return _piranhaTotalDeposit > 0 ? (piranhaDepositOf[investor] * piranhaAllocation) / _piranhaTotalDeposit : 0;
    }

    function calcWhalePart(
        address investor,
        uint256 piranhaSpent,
        uint256 piranhaPart,
        uint256 whaleAllocation,
        uint256 totalInvested,
        uint256 totalAllocation
    ) private view returns (uint256) {
        uint256 _piranhaTotalDeposit = piranhaTotalDeposit;
        uint256 whaleShare = whaleTotalDeposit -
            (_piranhaTotalDeposit > 0 ? (sharkTotalDeposit * piranhaSpent) / _piranhaTotalDeposit : 0);
        uint256 p = (piranhaPart * totalInvested) / totalAllocation;
        return
            whaleShare > 0
                ? (whaleDepositOf[investor] > p ? ((whaleDepositOf[investor] - p) * whaleAllocation) / whaleShare : 0)
                : 0;
    }

    function calcAllocations(uint256 totalInvested)
        public
        view
        returns (
            uint256 totalAllocation,
            uint256 whaleAllocation,
            uint256 piranhaAllocation,
            uint256 sealAllocation
        )
    {
        uint256 invested = min(HARD_CAP, totalInvested);
        totalAllocation = calcTotalAllocation();
        whaleAllocation = min(
            (whaleTotalDeposit * totalAllocation) / invested,
            (totalAllocation * WHALE_ALLOCATION_FACTOR) / 10_000
        );
        piranhaAllocation = min(
            (piranhaTotalDeposit * totalAllocation) / invested,
            (totalAllocation * PIRANHA_ALLOCATION_FACTOR) / 10_000
        );
        sealAllocation = totalAllocation - whaleAllocation - piranhaAllocation;
    }

    function calcTotalAllocation() private view returns (uint256) {
        uint256 totalAllocation = (1_000_000 * 10**18) +
            (totalDeposit > SOFT_CAP ? ((totalDeposit - SOFT_CAP) * REL) / EXTRA_PRICE : 0);
        return min(totalAllocation, MAX_ALLOCATION);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
