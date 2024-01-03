pragma solidity 0.5.16;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IUniswapV2Router01.sol";
import "./BasisPoints.sol";
import "./LidSimplifiedPresaleTimer.sol";

contract LidSimplifiedPresaleRedeemer is Initializable, Ownable {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public redeemBP;
    uint256 public redeemInterval;

    uint256 public totalShares;
    uint256 public totalDepositors;
    mapping(address => uint256) public accountDeposits;
    mapping(address => uint256) public accountShares;
    mapping(address => uint256) public accountClaimedTokens;

    address private presale;

    modifier onlyPresaleContract {
        require(msg.sender == presale, "Only callable by presale contract.");
        _;
    }

    function initialize(
        uint256 _redeemBP,
        uint256 _redeemInterval,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(owner);

        redeemBP = _redeemBP;
        redeemInterval = _redeemInterval;
        presale = _presale;
    }

    function setClaimed(address account, uint256 amount)
        external
        onlyPresaleContract
    {
        accountClaimedTokens[account] = accountClaimedTokens[account].add(
            amount
        );
    }

    function setDeposit(address account, uint256 deposit)
        external
        onlyPresaleContract
    {
        if (accountDeposits[account] == 0)
            totalDepositors = totalDepositors.add(1);
        accountDeposits[account] = accountDeposits[account].add(deposit);
        uint256 sharesToAdd = deposit;
        accountShares[account] = accountShares[account].add(sharesToAdd);
        totalShares = totalShares.add(sharesToAdd);
    }

    function calculateRatePerEth(uint256 totalPresaleTokens, uint256 hardCap)
        external
        pure
        returns (uint256)
    {
        return totalPresaleTokens.mul(1 ether).div(getMaxShares(hardCap));
    }

    function calculateReedemable(
        address account,
        uint256 finalEndTime,
        uint256 totalPresaleTokens
    ) external view returns (uint256) {
        if (finalEndTime == 0) return 0;
        if (finalEndTime >= now) return 0;
        uint256 earnedTokens = accountShares[account]
            .mul(totalPresaleTokens)
            .div(totalShares);
        uint256 claimedTokens = accountClaimedTokens[account];
        uint256 cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint256 totalRedeemable = earnedTokens.mulBP(redeemBP).mul(cycles);
        uint256 claimable;
        if (totalRedeemable >= earnedTokens) {
            claimable = earnedTokens.sub(claimedTokens);
        } else {
            claimable = totalRedeemable.sub(claimedTokens);
        }
        return claimable;
    }

    function getMaxShares(uint256 hardCap) public pure returns (uint256) {
        return hardCap;
    }
}
