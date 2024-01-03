// File: contracts/constants/ConstantAddressesMainnet.sol

pragma solidity ^0.5.16;


contract ConstantAddresses {
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant COMPOUND_ORACLE = 0x1D8aEdc9E924730DD3f9641CDb4D1B92B848b4bd;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant CUSDC_ADDRESS = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    address public constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant CWBTC_ADDRESS = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address public constant COMP_ADDRESS = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

// File: contracts/interfaces/IPriceOracle.sol

pragma solidity ^0.5.16;

interface IPriceOracle {
    function price(string calldata symbol) external view returns (uint);
}

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IDfTokenizedDeposit.sol

pragma solidity ^0.5.16;


interface IDfTokenizedDeposit {
    function token() external returns (IERC20);
    function dfWallet() external returns (address);

    function tokenETH() external returns (IERC20);
    function tokenUSDC() external returns (IERC20);

    function fundsUnwinded(address) external returns (uint256);
}

// File: contracts/compound/interfaces/ICToken.sol

pragma solidity ^0.5.16;

interface ICToken {
    function borrowIndex() view external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower) external payable;

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
        external
        returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function borrowRatePerBlock() external returns (uint256);

    function totalReserves() external returns (uint256);

    function reserveFactorMantissa() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function balanceOf(address owner) view external returns (uint256);

    function underlying() external returns (address);
}

// File: contracts/deposits/DfInfo.sol

pragma solidity ^0.5.16;






interface IComptroller {
    function oracle() external view returns (IPriceOracle);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

contract DfInfo is ConstantAddresses {
    function getInfo(IDfTokenizedDeposit dfTokenizedDepositAddress)
        public
        returns (
            uint256 liquidity,
            uint256 shortfall,
            uint256 land,
            uint256 cred,
            uint256 f,
            uint256[3] memory walletBalances,
            uint256[3] memory unwindedBalances,
            uint256[3] memory tokenBalances
        )
    {
        address walletAddress = dfTokenizedDepositAddress.dfWallet();
        uint256 err;
        (err, liquidity, shortfall) = IComptroller(COMPTROLLER)
            .getAccountLiquidity(walletAddress);

        IPriceOracle compOracle = IComptroller(COMPTROLLER).oracle();

        walletBalances[0] = ICToken(CDAI_ADDRESS).balanceOfUnderlying(
            walletAddress
        );
        walletBalances[1] = ICToken(CUSDC_ADDRESS).balanceOfUnderlying(
            walletAddress
        );
        walletBalances[2] = ICToken(CETH_ADDRESS).balanceOfUnderlying(
            walletAddress
        );
        land =
            (walletBalances[0] * compOracle.price("DAI")) /
            10**6 +
            (walletBalances[1] * compOracle.price("USDC")) /
            10**6 +
            (walletBalances[2] * compOracle.price("ETH")) /
            10**6;

        walletBalances[0] -= ICToken(CDAI_ADDRESS).borrowBalanceCurrent(
            walletAddress
        );
        walletBalances[1] -= ICToken(CUSDC_ADDRESS).borrowBalanceCurrent(
            walletAddress
        );
        walletBalances[2] -= ICToken(CETH_ADDRESS).borrowBalanceCurrent(
            walletAddress
        );
        cred +=
            (ICToken(CDAI_ADDRESS).borrowBalanceCurrent(walletAddress) *
                compOracle.price("DAI")) /
            10**6;
        cred +=
            (ICToken(CUSDC_ADDRESS).borrowBalanceCurrent(walletAddress) *
                compOracle.price("USDC")) /
            10**6;
        cred +=
            (ICToken(CETH_ADDRESS).borrowBalanceCurrent(walletAddress) *
                compOracle.price("ETH")) /
            10**6;

        unwindedBalances[0] = dfTokenizedDepositAddress.fundsUnwinded(
            DAI_ADDRESS
        );
        unwindedBalances[1] = dfTokenizedDepositAddress.fundsUnwinded(
            USDC_ADDRESS
        );
        unwindedBalances[2] = dfTokenizedDepositAddress.fundsUnwinded(
            WETH_ADDRESS
        );

        tokenBalances[0] = dfTokenizedDepositAddress.token().totalSupply();
        tokenBalances[1] = dfTokenizedDepositAddress.tokenUSDC().totalSupply();
        tokenBalances[2] = dfTokenizedDepositAddress.tokenETH().totalSupply();

        f = (cred * 100) / land;
    }
}