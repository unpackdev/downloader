pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";

import "./IUniswapV2Router02.sol";

/// @title FeeToTreasuryTransporter
/// @notice The contract if designed to accumulate tokens from fees on authority of
/// the protocol. When the admin of the contract converts all accumulated tokens
/// and sends them to the Treasury contract.
contract FeeToTreasuryTransporter is Initializable, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event FundsConverted(uint256[] amounts);

    IUniswapV2Router02 public uniswapRouter;
    address public treasury;
    address public rewardsToken;

    EnumerableSet.AddressSet internal _tokensToConvert;

    function configure(
        address _uniswapRouter,
        address _treasury,
        address _rewardsToken,
        address[] calldata __tokensToConvert
    ) external initializer {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        treasury = _treasury;
        rewardsToken = _rewardsToken;
        for (uint256 i = 0; i < __tokensToConvert.length; i = i.add(1)) {
            _tokensToConvert.add(__tokensToConvert[i]);
        }
    }

    function addTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.add(_tokenAddress), "alreadyExists");
    }

    function removeTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.remove(_tokenAddress), "doesntExist");
    }

    function getTokenToConvert(uint256 _idx) external view returns(address) {
        return _tokensToConvert.at(_idx);
    }

    function getTokensToConvertLength() external view returns(uint256) {
        return _tokensToConvert.length();
    }

    function setRewardsToken(address _rewardsToken) external onlyOwner {
        rewardsToken = _rewardsToken;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function sendRewardToTreasure() external onlyOwner {
        IERC20 token = IERC20(rewardsToken);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(treasury, balance);
    }

    function convertToRewardsToken(
        uint256[] calldata amountsOutMin, // amounts out for swaps to XBE
        uint256[] calldata deadlines // deadlines for swaps to XBE
    )
        external
        onlyOwner
    {
        uint256 _tokensToConvertLength = _tokensToConvert.length();
        require(
            amountsOutMin.length == _tokensToConvertLength,
            "invalidLengthOfAmountsOutMin"
        );
        require(
            deadlines.length == _tokensToConvertLength,
            "invalidLengthOfDeadlines"
        );

        address[] memory path = new address[](3);
        path[1] = uniswapRouter.WETH();
        path[2] = rewardsToken;

        uint256[] memory actualAmounts = new uint256[](_tokensToConvertLength);

        for (uint256 i = 0; i < _tokensToConvertLength; i = i.add(1)) {
            address _tokenAddress = _tokensToConvert.at(i);
            path[0] = _tokenAddress;

            IERC20 token = IERC20(_tokenAddress);
            if (token.allowance(address(this), address(uniswapRouter)) == 0) {
                token.approve(address(uniswapRouter), uint256(-1));
            }

            actualAmounts[i] = uniswapRouter.swapExactTokensForTokens(
                token.balanceOf(address(this)),
                amountsOutMin[i],
                path,
                treasury,
                deadlines[i]
            )[1];
        }

        emit FundsConverted(actualAmounts);
    }

}
