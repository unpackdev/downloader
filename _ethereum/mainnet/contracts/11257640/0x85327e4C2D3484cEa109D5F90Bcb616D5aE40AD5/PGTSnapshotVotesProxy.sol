pragma solidity 0.5.16;

import "./WhitelistAdminRole.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";

contract PGTSnapshotVotesProxy is WhitelistAdminRole {
    using SafeMath for uint256;

    string public constant NAME_SYMBOL = "PGT";
    bytes32 public constant LP_TOKEN_RATIO_KEY = "LpTokenRatio";
    bytes32 public constant TOKEN_RATIO_KEY = "TokenRatio";
    uint8 public constant RATIO_MULTIPLIER = 100;

    /**
        @notice This event is emitted when the lp token addresses are updated.
        @param sender the account which initialized the transaction.
        @param oldLpTokens the old lp token addresses.
        @param newLpTokens the new lp token addresses.
     */
    event LpTokensUpdated(
        address indexed sender,
        address[] indexed oldLpTokens,
        address[] indexed newLpTokens
    );

    /**
        @notice This event is emitted when a ratio is updated.
        @param sender the account which initialized the transaction.
        @param oldRatio the old ratio.
        @param newRatio the new ratio
        @param key the field ratio key.
     */
    event RatioUpdated(
        address indexed sender,
        uint256 indexed oldRatio,
        uint256 indexed newRatio,
        bytes32 key
    );

    /**
        @notice This event is emitted when the StakeToken reference is updated.
        @param sender The account which initialized the transaction.
        @param oldStakeToken the old stake token address.
        @param newStakeToken the new stake token address.
     */
    event StakeTokenUpdated(
        address indexed sender,
        address indexed oldStakeToken,
        address indexed newStakeToken
    );

    IERC20 public token;
    address[] public lpTokens;

    uint256 public tokenRatio;
    uint256 public lpTokenRatio;

    constructor(
        address _tokenAddress,
        address[] memory _lpAddresses,
        uint256 _tokenRatio,
        uint256 _lpTokenRatio
    ) public {
        token = IERC20(_tokenAddress);
        lpTokens = _lpAddresses;
        tokenRatio = _tokenRatio;
        lpTokenRatio = _lpTokenRatio;
    }

    /**
        @notice Gets the current LP tokens list.
        @return the current LP tokens list.
     */
    function getLpTokens() external view returns (address[] memory) {
        return lpTokens;
    }

    /**
        @notice Sets the token ratio
        @param newTokenRatio the new token ratio.
     */
    function setTokenRatio(uint256 newTokenRatio) external onlyWhitelistAdmin() {
        require(tokenRatio != newTokenRatio, "NEW_TOKEN_RATIO_REQUIRED");
        uint256 oldTokenRatio = tokenRatio;

        tokenRatio = newTokenRatio;

        emit RatioUpdated(
            msg.sender,
            oldTokenRatio,
            newTokenRatio,
            TOKEN_RATIO_KEY
        );
    }

    /**
        @notice Sets the LpToken ratio
        @param newLpTokenRatio the new lp token ratio.
     */
    function setLpTokenRatio(uint256 newLpTokenRatio) external onlyWhitelistAdmin() {
        require(lpTokenRatio != newLpTokenRatio, "NEW_LP_TOKEN_RATIO_REQUIRED");
        uint256 oldLpTokenRatio = lpTokenRatio;

        lpTokenRatio = newLpTokenRatio;

        emit RatioUpdated(
            msg.sender,
            oldLpTokenRatio,
            newLpTokenRatio,
            LP_TOKEN_RATIO_KEY
        );
    }

    /**
        @notice Replaces the current lp token addresses with a new list of lp token addresses.
        @notice If you only need to add a new lp token address to the list, you need to:
            - Get the current list (calling the lpTokens() function).
            - Add the new lp address to your list.
            - And call this function again using the updated list.
        @param newLpTokens the new list of lp token addresses.
     */
    function setLpTokens(address[] calldata newLpTokens) external onlyWhitelistAdmin() {
        address[] memory oldLpTokens = newLpTokens;

        lpTokens = newLpTokens;

        emit LpTokensUpdated(
            msg.sender,
            oldLpTokens,
            newLpTokens
        );
    }

    function decimals() external view returns (uint8) {
        return token.decimals();
    }

    function name() external pure returns (string memory) {
        return NAME_SYMBOL;
    }

    function symbol() external pure returns (string memory) {
        return NAME_SYMBOL;
    }

    function totalSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    /**
        @notice Gets the current ratios for the token and lp token.
        @return the current ratios for the token and lp token.
     */
    function getRatios() external view returns (uint256 currentTokenRatio, uint256 currentLpTokenRatio) {
        return (
            tokenRatio,
            lpTokenRatio
        );
    }

    /**
        @notice Get the current balance (votes) for a given account.
        @dev Total Balance = Token Balance + Token Balance from Provided Liquidity
        @return the total token balance for a given account.
     */
    function balanceOf(address _voter) external view returns (uint256) {
        uint256 _votes = 0;
        // Count the balanceOf the TOKEN.
        _votes = token
                    .balanceOf(_voter)
                    .mul(tokenRatio)
                    .div(RATIO_MULTIPLIER);

        // Counting the TOKEN balances from the provided liquidity.
        for(uint256 index = 0; index < lpTokens.length; index = index.add(1)) {
            address lpToken = lpTokens[index];
            _votes = _votes.add(
                    _getTokenBalanceFromProvidedLiquidity(lpToken, _voter)
                    .mul(lpTokenRatio)
                    .div(RATIO_MULTIPLIER)
                );
        }

        return _votes;
    }

    /**
        @notice Gets the token balances for a given account based on the LP token balance.
        @param lpToken address in order to calculate the token balances.
        @param account address to get the balances.
        @return token0 token 0 address.
        @return balance0 token 0 balance for the given account.
        @return token1 token 1 address.
        @return balance1 token 1 balance for the given account.
     */
    function getTokenBalancesFromProvidedLiquidity(address lpToken,  address account) external view returns (address token0, uint256 balance0, address token1, uint256 balance1) {
        return _getTokenBalancesFromProvidedLiquidity(IUniswapV2Pair(lpToken), account);
    }

    /**
        @notice It gets the token balance based on the provided liquidity (LP tokens) for a given account.
        @param account address to get the token balance.
        @return the current token balance based on the LP tokens on the market/pair.
     */
    function _getTokenBalanceFromProvidedLiquidity(address lpToken, address account) internal view returns (uint256) {
        (
            address token0,
            uint256 balance0,
            address token1,
            uint256 balance1
        ) = _getTokenBalancesFromProvidedLiquidity(
            IUniswapV2Pair(lpToken),
            account
        );

        if(address(token) == token0) {
            return balance0;
        }
        if(address(token) == token1) {
            return balance1;
        }
        return 0;
    }

    /**
        @notice Gets the token balances for a given account based on the LP token balance.
        @param account address to get the balances.
        @return token0 token 0 address.
        @return balance0 token 0 balance for the given account.
        @return token1 token 1 address.
        @return balance1 token 1 balance for the given account.
     */
    function _getTokenBalancesFromProvidedLiquidity(IUniswapV2Pair lpToken, address account) internal view returns (address token0, uint256 balance0, address token1, uint256 balance1) {
        uint256 lpTotalSupply = lpToken.totalSupply();
        (uint112 reserve0, uint112 reserve1,) = lpToken.getReserves();
        uint256 accountLpBalance = lpToken.balanceOf(account);

        token0 = lpToken.token0();
        token1 = lpToken.token1();
        if(lpTotalSupply == 0) {
            balance0 = 0;
            balance1 = 0;
        } else {
            balance0 = accountLpBalance
                .mul(uint256(reserve0))
                .div(lpTotalSupply);
            balance1 = accountLpBalance
                .mul(uint256(reserve1))
                .div(lpTotalSupply);
        }
    }
}