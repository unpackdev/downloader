// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

contract DVDDistBotUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public wallet;
    IERC20Upgradeable public dvd; 
    address public xdvd; 
    address public lpDvdEth;

    uint256 public period;
    uint256 public startTime;
    uint256 public endTime;

    uint256 public supply;
    uint256 public amountDistributed;
    uint256 public maxAmount;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public percentOfShareForXDVD; // If the value 3300, it means 33%.
    uint256 public percentOfShareForLP;

    event SetPeriod(uint256 newPeriod);
    event SetSupply(uint256 newSupply);
    event SetPercentOfShare(uint256 newPercentOfShareForXDVD, uint256 newPercentOfShareForLP);
    event SetMaxAmount(uint256 newMaxAmount);
    event SetWallet(address indexed newWallet);
    event DistDVD(address indexed user, uint256 dvdAmount);

    /// @dev Require that the caller must be an EOA account to avoid flash loans
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not EOA");
        _;
    }

    function initialize(
        IERC20Upgradeable _dvd, 
        address _xdvd, 
        IUniswapV2Router02 _router, 
        address _wallet
    ) external initializer {
        require(address(_dvd) != address(0), "DVD address is invalid");
        require(address(_xdvd) != address(0), "xDVD address is invalid");
        require(address(_router) != address(0), "UniswapV2Router address is invalid");
        require(address(_wallet) != address(0), "Wallet address is invalid");

        __Ownable_init();
        __ReentrancyGuard_init();

        wallet = _wallet;
        dvd = _dvd;
        xdvd = _xdvd;

        IUniswapV2Factory uniFactory = IUniswapV2Factory(_router.factory());
        lpDvdEth = uniFactory.getPair(address(dvd), address(_router.WETH()));
        require(lpDvdEth != address(0), "LP address is invalid");

        period = 720 days; // 24 months
        startTime = 1629849600;
        endTime = startTime.add(period);

        supply = 5500000e18; // 5.5M DVD
        maxAmount = 100000e18;

        percentOfShareForXDVD = 3333; // 33.33%
        percentOfShareForLP = DENOMINATOR.sub(percentOfShareForXDVD);
    }

    receive() external payable {}

    /**
     * @dev Set the period.
     *
     * @param _period     The distribution period in seconds
     */
    function setPeriod(uint256 _period) external onlyOwner {
        require(block.timestamp <= startTime.add(_period), "The calculated endTime should be greater than current time");
        period = _period;
        emit SetPeriod(period);
    }

    function setSupply(uint256 _supply) external onlyOwner {
        require(amountDistributed <= _supply, "New supply must be equal or greater than amountDistributed");
        supply = _supply;
        emit SetSupply(supply);
    }

    function setPercentOfShare(uint256 _percentOfShareForXDVD, uint256 _percentOfShareForLP) external onlyOwner {
        require(_percentOfShareForXDVD.add(_percentOfShareForLP) <= DENOMINATOR, "The value should be equal or less than 10000");
        percentOfShareForXDVD = _percentOfShareForXDVD;
        percentOfShareForLP = _percentOfShareForLP;
        emit SetPercentOfShare(percentOfShareForXDVD, percentOfShareForLP);
    }

    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount;
        emit SetMaxAmount(maxAmount);
    }

    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Wallet address is invalid");
        wallet = _wallet;
        emit SetWallet(wallet);
    }

    function getDistributableAmount() public view returns(
        uint256 distributable,
        uint256 curAmountOnXDVD,
        uint256 rewardForXDVD,
        uint256 curAmountOnUniLP,
        uint256 rewardForUniLP
    ) {
        distributable = _getDistributableAmount();
        curAmountOnXDVD = dvd.balanceOf(xdvd);
        rewardForXDVD = distributable.mul(percentOfShareForXDVD).div(DENOMINATOR);
        curAmountOnUniLP = dvd.balanceOf(lpDvdEth);
        rewardForUniLP = distributable.mul(percentOfShareForLP).div(DENOMINATOR);
    }

    function _getDistributableAmount() internal view returns(uint256) {
        uint256 lastTime = (block.timestamp < endTime) ? block.timestamp : endTime;
        uint256 amountAllowed = supply.mul(lastTime.sub(startTime)).div(period);
        return (amountAllowed <= amountDistributed) ? 0 : amountAllowed.sub(amountDistributed);
    }

    function distDVD() external onlyEOA nonReentrant {
        uint256 dvdAmount = _getDistributableAmount();
        require(0 < dvdAmount, "Nothing to be distributable");
        if (maxAmount < dvdAmount) {
            dvdAmount = maxAmount;
        }

        amountDistributed = amountDistributed.add(dvdAmount);
        dvd.safeTransferFrom(wallet, xdvd, dvdAmount.mul(percentOfShareForXDVD).div(DENOMINATOR));
        dvd.safeTransferFrom(wallet, lpDvdEth, dvdAmount.mul(percentOfShareForLP).div(DENOMINATOR));
        IUniswapV2Pair(lpDvdEth).sync();

        emit DistDVD(msg.sender, dvdAmount);
    }

    uint256[38] private __gap;
}