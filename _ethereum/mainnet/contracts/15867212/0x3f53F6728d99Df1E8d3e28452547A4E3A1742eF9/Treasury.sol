// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";

import "./IUniswapV2Router02.sol";

import "./ITreasury.sol";
import "./IRewardsDistributionRecipient.sol";

/// @title Treasury
/// @notice The contract stores some portion of reward tokens in the system (including XB3), 
/// converts them to XB3 if needed and transfer them to VSR to distribute it between stakers. 
/// Some authorized person or backend can call toVoters to convert specific reward tokens to 
/// XB3 (via purchase on uniswap or its equivalent), and immediately send them to VSR for 
/// further distribution
contract Treasury is Ownable, ITreasury {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IUniswapV2Router02 public uniswapRouter;    // Uniswap router address

    address public rewardsDistributionRecipientContract;    // The recepient of the reward token
    address public rewardToken;    // Reward token address 

    EnumerableSet.AddressSet internal _tokensToConvert;

    mapping(address => bool) public authorized; // Account address -> if the account authorized or not

    event FundsConverted(
        address indexed from,
        address indexed to,
        uint256 indexed amountOfTo
    );

    modifier authorizedOnly() {
        require(authorized[_msgSender()], "!authorized");
        _;
    }

    constructor(
        address _rewardToken,
        address _uniswapRouter
    ) {
        rewardToken = _rewardToken;
        setAuthorized(_msgSender(), true);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    /**
     * @notice Sets reward token address
     * @param _rewardToken New reward token address
     */
    function setRewardsToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    /**
     * @notice Sets router address
     * @param _routerAddress New router address
     */
    function setRouterAddress(IUniswapV2Router02 _routerAddress) external onlyOwner {
        uniswapRouter = _routerAddress;
    }

    /**
     * @notice Sets the recepient for reward tokens
     * @param _rewardsDistributionRecipientContract New recepient address
     */
    function setRewardsDistributionRecipientContract(
        address _rewardsDistributionRecipientContract
    ) external onlyOwner {
        rewardsDistributionRecipientContract = _rewardsDistributionRecipientContract;
    }

    /**
     * @notice Sets authorized address
     * @param _account Account address
     * @param _status New status for account
     */
    function setAuthorized(address _account, bool _status) public onlyOwner {
        authorized[_account] = _status;
    }

    /**
     * @notice Returns the number of convertable tokens
     */
    function tokensToConvertCount() public view returns(uint256){
        return _tokensToConvert.length();
    }

    /**
     * @notice Returns token from the list of convertable tokens at specified index
     * @param _index Token index
     */
    function tokensToConvertAt(uint256 _index) public view returns(address) {
        return _tokensToConvert.at(_index);
    }

    /**
     * @notice Adds token to the list of convertable tokens
     * @param _tokenAddress Token address
     */
    function addTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.add(_tokenAddress), "alreadyExists");
    }

    /**
     * @notice Removes token from the list of convertable tokens
     * @param _tokenAddress Token address
     */
    function removeTokenToConvert(address _tokenAddress) external onlyOwner {
        require(_tokensToConvert.remove(_tokenAddress), "doesntExist");
    }

    /**
     * @notice Checks of token is allowed to be converted
     * @param _tokenAddress Token address
     */
    function isTokenAllowedToConvert(address _tokenAddress)
        external
        view
        returns (bool)
    {
        return _tokensToConvert.contains(_tokenAddress);
    }

    /**
     * @notice Allows to transfer any token stuck on the contract to owner
     * @param _tokenAddress Token address
     * @param _amount Token amount
     */
    function toGovernance(address _tokenAddress, uint256 _amount)
        external
        override
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(owner(), _amount);
    }

    /**
     * @notice Converts the specified token to reward token and send it to the recepient
     * @dev Only authorized address can call it
     * @param _tokenAddress Token address
     * @param _amount Token amount
     * @param _amountOutMin Minimum amount of tokens received after swap
     * @param _deadlineDuration Deadline for the swap transaction
     */
    function toVoters(
        address _tokenAddress,
        uint256 _amount,
        uint256 _amountOutMin,
        uint256 _deadlineDuration
    ) external override authorizedOnly {
        address rewardTokenAddress = rewardToken; 
        if (_tokenAddress != rewardTokenAddress) {
            _convertToRewardsToken(_tokenAddress, _amount, _amountOutMin, _deadlineDuration);
        }
        address recepient = rewardsDistributionRecipientContract;
        uint256 balance = IERC20(rewardTokenAddress).balanceOf(address(this));
        IERC20(rewardTokenAddress).safeTransfer(
            recepient,
            balance
        );
        IRewardsDistributionRecipient(recepient).notifyRewardAmount(balance);
    }

    function _convertToRewardsToken(
        address _tokenAddress, 
        uint256 _amount, 
        uint256 _amountOutMin, 
        uint256 _deadlineDuration
    ) internal {
        require(_tokensToConvert.contains(_tokenAddress), "tokenIsNotAllowed");
        address rewardTokenAddress = rewardToken; 
        address uniswapRouterAddress = address(uniswapRouter); 
        address[] memory path = new address[](3);
        path[0] = _tokenAddress;
        path[1] = uniswapRouter.WETH();
        path[2] = rewardTokenAddress;
        IERC20 token = IERC20(_tokenAddress);
        if (token.allowance(address(this), uniswapRouterAddress) == 0) {
            token.approve(uniswapRouterAddress, type(uint256).max);
        }
        uint256 amountOut = IERC20(rewardTokenAddress).balanceOf(address(this));
        IUniswapV2Router02(uniswapRouterAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _amountOutMin,
            path,
            address(this),
            _deadlineDuration
        );
        amountOut = IERC20(rewardTokenAddress).balanceOf(address(this)) - amountOut;
        emit FundsConverted(_tokenAddress, rewardTokenAddress, amountOut);
    }
}
