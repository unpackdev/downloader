pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";

import "./IUniswapV2Router02.sol";

import "./ITreasury.sol";
import "./IRewardsDistributionRecipient.sol";

/// @title Treasury
/// @notice Realisation of ITreasury for channeling managing fees from strategies to gov and governance address
contract Treasury is Initializable, Ownable, ITreasury {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event FundsConverted(
        address indexed from,
        address indexed to,
        uint256 indexed amountOfTo
    );

    IUniswapV2Router02 public uniswapRouter;

    address public rewardsDistributionRecipientContract;
    address public rewardsToken;
    uint256 public constant MAX_BPS = 10000;

    uint256 public slippageTolerance; // in bps, ex. 9500 equals 5% slippage tolerance
    uint256 public swapDeadline; // in seconds

    EnumerableSet.AddressSet internal _tokensToConvert;

    mapping(address => bool) public authorized;

    modifier authorizedOnly() {
        require(authorized[_msgSender()], "!authorized");
        _;
    }

    function configure(
        address _governance,
        address _rewardsDistributionRecipientContract,
        address _rewardsToken,
        address _uniswapRouter,
        uint256 _slippageTolerance,
        uint256 _swapDeadline
    ) external onlyOwner initializer {
        rewardsDistributionRecipientContract = _rewardsDistributionRecipientContract;
        rewardsToken = _rewardsToken;
        setAuthorized(_governance, true);
        setAuthorized(address(this), true);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        slippageTolerance = _slippageTolerance;
        swapDeadline = _swapDeadline;
        transferOwnership(_governance);
    }

    function setRewardsToken(address _rewardsToken) external onlyOwner {
        rewardsToken = _rewardsToken;
    }

    function setSlippageTolerance(uint256 _slippageTolerance)
        external
        onlyOwner
    {
        require(_slippageTolerance <= 10000, "slippageToleranceTooLarge");
        slippageTolerance = _slippageTolerance;
    }

    function setRewardsDistributionRecipientContract(
        address _rewardsDistributionRecipientContract
    ) external onlyOwner {
        rewardsDistributionRecipientContract = _rewardsDistributionRecipientContract;
    }

    function setAuthorized(address _authorized, bool _status) public onlyOwner {
        authorized[_authorized] = _status;
    }

    function addTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.add(_tokenAddress), "alreadyExists");
    }

    function removeTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.remove(_tokenAddress), "doesntExist");
    }

    function isAllowTokenToConvert(address _tokenAddress)
        external
        view
        returns (bool)
    {
        return _tokensToConvert.contains(_tokenAddress);
    }

    function convertToRewardsToken(address _tokenAddress, uint256 amount)
        public
        override
        authorizedOnly
    {
        require(_tokensToConvert.contains(_tokenAddress), "tokenIsNotAllowed");

        address[] memory path = new address[](3);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();
        path[2] = rewardsToken;

        uint256 amountOutMin = uniswapRouter.getAmountsOut(amount, path)[0];
        amountOutMin = amountOutMin.mul(slippageTolerance).div(MAX_BPS);

        IERC20 token = IERC20(_tokenAddress);
        if (token.allowance(address(this), address(uniswapRouter)) == 0) {
            token.approve(address(uniswapRouter), uint256(-1));
        }
        uniswapRouter.swapExactTokensForTokens(
            amount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + swapDeadline
        );
        emit FundsConverted(_tokenAddress, rewardsToken, amountOutMin);
    }

    function toGovernance(address _tokenAddress, uint256 _amount)
        external
        override
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
    }

    function toVoters() external override {
        uint256 _balance = IERC20(rewardsToken).balanceOf(address(this));
        IERC20(rewardsToken).safeTransfer(
            rewardsDistributionRecipientContract,
            _balance
        );
        IRewardsDistributionRecipient(rewardsDistributionRecipientContract)
            .notifyRewardAmount(_balance);
    }
}
