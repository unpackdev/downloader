// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external returns (uint8);
}

contract WUTPublicPresale is ReentrancyGuard {
    // State
    uint256 public constant EXTRA_PRICE = 3;
    uint256 public immutable REL; // WUT / Sale Token decimals relation
    uint256 public immutable ONE_MILLION;
    uint256 public immutable firstStageStartBlock;
    uint256 public immutable secondStageStartBlock;
    uint256 public immutable presaleEndBlock;
    bool public allowClaimWUT;

    address public treasurer;
    IERC20 public saleToken;
    IERC20 public WUT;

    uint256 public totalDeposit;
    mapping(address => uint256) public depositOf;

    // Events
    event Deposit(address indexed investor, uint256 amount, uint256 investorDeposit, uint256 totalDeposit);
    event Withdraw(address indexed investor, uint256 amount, uint256 investorDeposit, uint256 totalDeposit);
    event Claim(address indexed investor, uint256 claimAmount, uint256 depositAmount);

    // Libraries
    using SafeERC20 for IERC20;

    constructor(
        uint256 _firstStageStartBlock,
        uint256 _secondStageStartBlock,
        uint256 _presaleEndBlock,
        address _saleToken,
        address _wut,
        address _treasurer
    ) {
        firstStageStartBlock = _firstStageStartBlock;
        secondStageStartBlock = _secondStageStartBlock;
        presaleEndBlock = _presaleEndBlock;
        treasurer = _treasurer;
        saleToken = IERC20(_saleToken);
        WUT = IERC20(_wut);
        ONE_MILLION = 1_000_000 * 10**IERC20Detailed(_saleToken).decimals();
        REL = 10**(18 - IERC20Detailed(_saleToken).decimals());
    }

    function deposit(uint256 amount) external nonReentrant {
        require(block.number >= firstStageStartBlock, "Public presale is not active yet");
        require(block.number < presaleEndBlock, "Presale has ended");
        saleToken.safeTransferFrom(msg.sender, address(this), amount);
        totalDeposit += amount;
        depositOf[msg.sender] += amount;
        emit Deposit(msg.sender, amount, depositOf[msg.sender], totalDeposit);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(block.number < secondStageStartBlock, "Unable to withdraw funds after second stage start");
        totalDeposit -= amount;
        depositOf[msg.sender] -= amount;
        saleToken.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, depositOf[msg.sender], totalDeposit);
    }

    function claim() external nonReentrant {
        require(allowClaimWUT, "Unable to claim WUT before presale ends");
        uint256 depositAmount = depositOf[msg.sender];
        depositOf[msg.sender] = 0;
        uint256 claimAmount = calcClaimAmount(depositAmount);
        WUT.safeTransfer(msg.sender, claimAmount);
        emit Claim(msg.sender, claimAmount, depositAmount);
    }

    function drawOut() external nonReentrant {
        require(block.number >= presaleEndBlock, "Unable to draw out funds before presale ends");
        saleToken.safeTransfer(treasurer, saleToken.balanceOf(address(this)));
        uint256 wutToBeDistributed = (1_000_000 * 10**18) +
            (totalDeposit > ONE_MILLION ? ((totalDeposit - ONE_MILLION) * REL) / EXTRA_PRICE : 0);
        uint256 wutBalance = WUT.balanceOf(address(this));
        if (wutBalance > wutToBeDistributed) {
            WUT.safeTransfer(treasurer, wutBalance - wutToBeDistributed);
        }
        if (!allowClaimWUT) {
            allowClaimWUT = true;
        }
    }

    function balanceOf(address investor) external view returns (uint256 depositAmount, uint256 claimAmount) {
        depositAmount = depositOf[investor];
        claimAmount = calcClaimAmount(depositAmount);
    }

    function calcClaimAmount(uint256 depositAmount) internal view returns (uint256) {
        uint256 baseClaimAmount = ((1_000_000 * 10**18) * depositAmount) / totalDeposit;
        return
            totalDeposit < ONE_MILLION
                ? baseClaimAmount
                : baseClaimAmount + ((totalDeposit - ONE_MILLION) * depositAmount * REL) / totalDeposit / EXTRA_PRICE;
    }
}
