// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IWrappedEth {
    function deposit() external payable;
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract Presale is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public ssloth; /// SSloth token address (presale token)
    /// Main exchange token (should be a stablecoin)
    /// If user purchase SSloth token with ETH, ETH should be change to exchangeToken
    address public exchangeToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable weth; /// WETH address
    /// ETH is converted to exchangeToken using Uniswap.
    /// Example: 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff (UniswapV2Router02 Polygon mainnet)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable uniswapRouter;

    address[] private stableCoins; /// Support stablecoins: USDC, USDT, FRAX, etc
    address[] private buyers; /// List of all token buyers

    uint256 public price; /// SSloth token price - USD (If price is $1, price = 100000000)
    uint256 public constant usd = 1e8; /// 1 USD amount - 1e8
    /// Total count of claims users can make - default is 6
    /// 1 means 1 month
    /// If 6, users can receive all tokens after 6 months
    /// Same value for all users
    uint256 public totalClaimableCount;
    /// Already claimed count
    /// Same value for all users
    uint256 public claimedCount;
    /// Total amount of SSloth tokens purchased by users
    /// This amount does not include additional bonus amount
    uint256 public totalPurchasedAmount;
    /// Vesting start timestamp
    /// This value is set to the timestamp when the owner executed startVesting()
    uint256 public vestingStartTime;
    /// Additional bonus percent
    /// If this value is 1000 (100%), the user can receive twice the amount of the purchase
    uint256 public bonusPercent; // permille value

    /// bool variable indicating whether the contract is enabled
    /// If this value is true, user can not purchase the token
    bool public paused;

    /// Mapping variable representing the amount of tokens purchased by individual users
    mapping (address => uint256) public purchasedAmount;

    event Purchase(
        address indexed buyer,
        address indexed token,
        uint256 tokenAmount,
        uint256 buyAmount,
        uint256 buyAt
    );

    event StartVesting(
        uint256 startAt
    );

    event Airdrop(
        uint256 count,
        uint256 totalClaimedCount,
        uint256 date
    );

    event ChangeBonusPercent(
        uint256 value,
        uint256 changedAt
    );

    event ChangeTokenPrice(
        uint256 value,
        uint256 changedAt
    );

    event ChangeClaimableCount(
        uint256 value,
        uint256 changedAt
    );

    event ChangeExchangeToken(
        address token,
        uint256 changeAt
    );

    event ChangeToken(
        address token,
        uint256 changeAt
    );

    modifier isPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    modifier isStartedVesting() {
        if (vestingStartTime > 0) {
            revert StartedVesting(vestingStartTime);
        }
        _;
    }

    modifier OnlySupportToken(address token) {
        if (!_checkSupportToken(token)) {
            revert UnsupportedToken(token);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _uniswapRouter) {
        if (_uniswapRouter == address(0)) {
            revert ZeroAddress();
        }
        uniswapRouter = _uniswapRouter;
        weth = IUniswapV2Router(_uniswapRouter).WETH();

        _disableInitializers();
    }

    function initialize(
        uint256 _price,
        uint256 _totalClaimableCount,
        address _ssloth,
        address _exchangeToken,
        address[] memory _stableCoins
    ) external initializer {
        __Ownable_init();

        price = _price;
        totalClaimableCount = _totalClaimableCount;

        if (_ssloth == address(0) || _exchangeToken == address(0)) {
            revert ZeroAddress();
        }
        ssloth = _ssloth;
        exchangeToken = _exchangeToken;
        stableCoins = _stableCoins;

        bonusPercent = 1000; // 100%
    }

    /// @notice Change stableCoins
    /// @dev Only owner can change the support stablecoin list when not started vesting yet
    /// Not available empty list and zero address
    /// @param _stableCoins address[] of new support stablecoins
    function changeStableCoins(address[] memory _stableCoins) external onlyOwner isStartedVesting {
        uint256 stableCoinsLength = _stableCoins.length;
        if (stableCoinsLength == 0) {
            revert EmptyArray();
        }
        for (uint256 i; i < stableCoinsLength; i++) {
            if (_stableCoins[i] == address(0)) {
                revert ZeroAddress();
            }
        }
        stableCoins = _stableCoins;
    }

    /// @notice Change totalClaimableCount
    /// @dev Only owner can change the total claimable count when not started vesting yet
    /// @param count new claimable count
    function changeClaimableCount(uint256 count) external onlyOwner isStartedVesting {
        totalClaimableCount = count;

        emit ChangeClaimableCount(count, block.timestamp);
    }

    /// @notice Change bonusPercent
    /// @dev Only owner can change the bonus percent
    /// This percentage must be between 0 and 2000
    /// @param percent new bonue percent
    function changeBonusPercent(uint256 percent) external onlyOwner {
        if (percent > 2000) {
            revert HigherValue(percent, 2000);
        }
        bonusPercent = percent;

        emit ChangeBonusPercent(percent, block.timestamp);
    }

    /// @notice Change exchangeToken
    /// @dev Only owner can change the exchange token address
    /// New exchange token address must be in support token list (stableCoins)
    /// @param token new exchange token address
    function changeExchangeToken(address token) external onlyOwner OnlySupportToken(token) {
        exchangeToken = token;

        emit ChangeExchangeToken(token, block.timestamp);
    }

    /// @notice Change SSloth token
    /// @dev Only owner can change the SSloth token address
    /// New SSloth token address must be not a zero address
    /// @param token new SSloth token address
    function changeToken(address token) external onlyOwner {
        if (token == address(0)) {
            revert ZeroAddress();
        }
        ssloth = token;

        emit ChangeToken(token, block.timestamp);
    }

    /// @notice Change price
    /// @dev Only owner can change the SSloth token price
    /// @param newPrice new bSSloth token price (If price is $1, this value should be 1 * 1e8)
    function changeTokenPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;

        emit ChangeTokenPrice(newPrice, block.timestamp);
    }

    /// @notice Change paused
    /// @dev Only owner can change the paused variable
    /// @param _paused bool variable indicating whether the contract is enabled
    function setPause(bool _paused) external onlyOwner {
        if (_paused == paused) {
            revert AlreadySet();
        }
        paused = _paused;
    }

    /// @notice Start vesting
    /// @dev Only owner can start vesting
    /// conditions: must Not paused, Not started vesting yet
    /// vestingStartTime value should be set to the timestamp when this function executed.
    /// When this function is called, the first month's airdrop will proceed
    /// and all users will be receive the token
    function startVesting() external nonReentrant onlyOwner isPaused isStartedVesting {
        // 1 airdrop after vesting starts
        _airdrop(1);

        vestingStartTime = block.timestamp;

        emit StartVesting(block.timestamp);
    }

    /// @notice purcahse token with ETH - payable function
    /// @dev Buyer can purchase SSloth token with ETH using this function
    /// conditions: must Not paused
    /// ETH amount coverted to exchangeToken and calculate the purchase amount using converted exchange token amount
    function purchaseWithETH() external payable isPaused {
        uint256 amount = msg.value;
        if (amount == 0) {
            revert ZeroAmount();
        }

        IWrappedEth(weth).deposit{value: amount}();

        IERC20Upgradeable(weth).safeApprove(uniswapRouter, amount);
        // Convert input token to DAI using Uniswap
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = exchangeToken;
        uint256[] memory amounts = IUniswapV2Router(uniswapRouter)
            .swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                type(uint256).max
            );

        _purchase(exchangeToken, amounts[amounts.length - 1]);
    }

    /// @notice purcahse token with stablecoin
    /// @dev Buyer can purchase SSloth token with support tokens (stableCoins) using this function
    /// conditions: must Not paused
    function purchaseWithStableCoin(address token, uint256 amount) external isPaused OnlySupportToken(token) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        _purchase(token, amount);
    }

    /// @notice withdraw funds to owner
    /// @dev Only owner can withdraw all funds obtained from the Pre-sale to their address anytime
    function withdrawFunds() external onlyOwner {
        uint256 stableCoinsLength = stableCoins.length;
        for (uint256 i; i < stableCoinsLength; i++) {
            uint256 balanceOf = IERC20Upgradeable(stableCoins[i]).balanceOf(address(this));
            if (balanceOf > 0) {
                IERC20Upgradeable(stableCoins[i]).safeTransfer(owner(), balanceOf);
            }
        }
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            (bool sent, ) = payable(owner()).call{value: ethAmount}("");
            if (!sent) {
                revert();
            }
        }
    }

    /// @notice withdraw SSloth token to owner
    /// @dev Only owner can withdraw all SSloth obtained from the Pre-sale to their address anytime
    function withdrawSSloth() external onlyOwner {
        uint256 balanceOf = IERC20Upgradeable(ssloth).balanceOf(address(this));
        if (balanceOf > 0) {
            IERC20Upgradeable(ssloth).safeTransfer(owner(), balanceOf);
        }
    }

    /// @notice Airdrop
    /// @dev Any user can receive a portion of the tokens purchased through the airdrop.
    /// conditions: must start vesting, Not claimed all token
    /// claim amount = purchased amount * claimable count / total claimable count + bonus amount
    /// Users can do the next airdrop after 1 month.
    function airdrop() external {
        if (vestingStartTime == 0) {
            revert NotStartedVesting();
        }
        uint256 leftClaimableCount = totalClaimableCount - claimedCount;
        if (leftClaimableCount == 0) {
            revert AlreadyAllClaimed();
        }
        // Round is 1 month
        uint256 count = (block.timestamp - vestingStartTime) / 2628000;
        if (count == 0 || claimedCount > count) {
            revert AlreadyClaimed();
        }

        // At the starting of vesting, the first claim takes place. So + 1
        uint256 claimableCount = count + 1 - claimedCount;
        if (claimableCount > leftClaimableCount) claimableCount = leftClaimableCount;

        _airdrop(claimableCount);
    }

    /// @notice Get support token list (stableCoins)
    /// @return address[] address array of all support tokens
    function supportCoinList() external view returns (address[] memory) {
        return stableCoins;
    }

    /// @notice The amount of SSloth tokens that can be purchased with the amount of ETH entered
    /// @param amountIn ETH amount
    /// @return amountOut SSloth token amount
    function getAmountsOutWithETH(uint256 amountIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = exchangeToken;
        // Get exchangeToken (USDC) amount
        uint[] memory amountsOut = IUniswapV2Router(uniswapRouter).getAmountsOut(amountIn, path);

        return _getTokenAmount(exchangeToken, amountsOut[amountsOut.length - 1]);
    }

    /// @notice The amount of SSloth tokens that can be purchased with the amount of coin and amount entered
    /// @param token token address
    /// @param amountIn ETH amount
    /// @return amountOut SSloth token amount
    function getAmountsOutWithStableCoin(address token, uint256 amountIn)
        external
        view
        OnlySupportToken(token)
        returns (uint256)
    {
        return _getTokenAmount(token, amountIn);
    }

    /// @notice Get claimable SSloth token amount for this month of user
    /// @param user user address
    /// @return amount claimable SSloth token amount
    function getClaimableAmountOf(address user) external view returns (uint256) {
        uint256 leftClaimableCount = totalClaimableCount - claimedCount;
        if (leftClaimableCount == 0) return 0;
        uint256 claimableCount = (block.timestamp - vestingStartTime) / 2628000 + 1 - claimedCount;
        if (claimableCount == 0) return 0;
        if (claimableCount > leftClaimableCount) claimableCount = leftClaimableCount;

        uint256 claimableAmount = purchasedAmount[user] * claimableCount / totalClaimableCount;
        return claimableAmount + claimableAmount * bonusPercent / 1000;
    }

    /// @notice SSloth token balance currently in this contract
    /// @return amount SSloth token balance
    function tokenBalance() external view returns (uint256) {
        return IERC20Upgradeable(ssloth).balanceOf(address(this));
    }

    /// @notice Remaining SSLoth token balance that the user can receive in future
    /// @param user User address that to check
    /// @return amount SSloth token balance
    function remainTokenAmountOf(address user) external view returns (uint256) {
        return purchasedAmount[user] * (totalClaimableCount - claimedCount) / totalClaimableCount;
    }

    receive() external payable {}

    /// @notice List of user addresses that purchased tokens
    /// @return address[] List of user addresses
    function buyersList() public view returns (address[] memory) {
        return buyers;
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert();
    }

    function _purchase(address token, uint256 amount) internal isStartedVesting {
        uint256 outputAmount = _getTokenAmount(token, amount);
        if (purchasedAmount[msg.sender] == 0) buyers.push(msg.sender);
        purchasedAmount[msg.sender] += outputAmount;
        totalPurchasedAmount += outputAmount;

        emit Purchase(msg.sender, token, amount, outputAmount, block.timestamp);
    }

    function _airdrop(uint256 count) internal {
        claimedCount += count;
        uint256 buyersLength = buyers.length;
        for (uint256 i; i < buyersLength; i++) {
            address buyer = buyers[i];
            uint256 airdropAmount = purchasedAmount[buyer] * count / totalClaimableCount;
            IERC20Upgradeable(ssloth).safeTransfer(buyer, airdropAmount + airdropAmount * bonusPercent / 1000);
        }

        emit Airdrop(count, claimedCount, block.timestamp);
    }

    function _checkSupportToken(address token) internal view returns (bool) {
        uint256 stableCoinsLength = stableCoins.length;
        for (uint256 i; i < stableCoinsLength; i++) {
            if (token == stableCoins[i]) return true;
        }
        return false;
    }

    function _getTokenAmount(address token, uint256 amount) internal view returns (uint256) {
        uint256 decimals = IERC20(token).decimals();
        return amount * usd * 1e18 / price / 10 ** decimals;
    }

    /** --------------------- Error --------------------- */
    error ZeroAddress();
    error Paused();
    error StartedVesting(uint256 startedTime);
    error NotStartedVesting();
    error EmptyArray();
    error HigherValue(uint256 value, uint256 max);
    error UnsupportedToken(address token);
    error AlreadySet();
    error AlreadyAllClaimed();
    error AlreadyClaimed();
    error ZeroAmount();
}
