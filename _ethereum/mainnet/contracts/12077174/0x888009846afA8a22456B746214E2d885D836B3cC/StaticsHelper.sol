pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./IVault.sol";

contract StaticsHelper is Ownable {
    using SafeMath for uint256;

    mapping(address => address) public priceFeeds;
    mapping(address => address) public lpSubTokens;
    mapping(address => address) public rewardPools;

    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = feed;
    }

    function setLpSubToken(address token, address subToken) external onlyOwner {
        lpSubTokens[token] = subToken;
    }

    function setRewardPool(address vault, address rewardPool)
        external
        onlyOwner
    {
        rewardPools[vault] = rewardPool;
    }

    function getBalances(address[] memory tokens, address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            if (tokens[i] == address(0)) {
                amounts[i] = user.balance;
            } else {
                amounts[i] = IERC20(tokens[i]).balanceOf(user);
            }
        }
        return amounts;
    }

    function getTotalSupplies(address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = IERC20(tokens[i]).totalSupply();
        }
        return amounts;
    }

    function getTokenAllowances(
        address[] memory tokens,
        address[] memory spenders,
        address user
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = IERC20(tokens[i]).allowance(user, spenders[i]);
        }
        return amounts;
    }

    function getTotalDeposits(address[] memory vaults)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory deposits = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            deposits[i] = IVault(vaults[i]).totalDeposits();
        }
        return deposits;
    }

    function underlyingBalanceWithInvestment(address[] memory vaults)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            amounts[i] = IVault(vaults[i]).underlyingBalanceWithInvestment();
        }
        return amounts;
    }

    function getChainlinkPrice(address token) public view returns (uint256) {
        if (priceFeeds[token] == address(0)) return 0;
        (, int256 price, , , ) =
            AggregatorV3Interface(priceFeeds[token]).latestRoundData();
        uint256 decimals =
            uint256(AggregatorV3Interface(priceFeeds[token]).decimals());
        uint256 uPrice = uint256(price);
        if (decimals < 18) {
            return uPrice.mul(10**(18 - decimals));
        } else if (decimals > 18) {
            return uPrice.div(10**(decimals - 18));
        }
        return uPrice;
    }

    function getLPPrice(address lp) public view returns (uint256) {
        if (lpSubTokens[lp] == address(0)) return 0;
        address subToken = lpSubTokens[lp];
        uint256 subTokenPrice = getChainlinkPrice(subToken);
        address _lp = lp;
        uint256 lpPrice =
            IERC20(subToken)
                .balanceOf(_lp)
                .mul(2)
                .mul(subTokenPrice)
                .mul(1e18)
                .div(IERC20(_lp).totalSupply())
                .div(10**uint256(ERC20Detailed(subToken).decimals()));
        return lpPrice;
    }

    function getPrices(address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            amounts[i] = getPrice(tokens[i]);
        }
        return amounts;
    }

    function getPrice(address token) public view returns (uint256) {
        if (priceFeeds[token] != address(0)) {
            return getChainlinkPrice(token);
        }
        if (lpSubTokens[token] != address(0)) {
            return getLPPrice(token);
        }
        return 0;
    }

    function getPortfolio(address[] memory tokens, address user)
        public
        view
        returns (uint256)
    {
        uint256 portfolio;
        uint256[] memory balances = getBalances(tokens, user);
        uint256[] memory prices = getPrices(tokens);
        for (uint256 i = 0; i < tokens.length; i += 1) {
            portfolio = portfolio.add(
                prices[i].mul(balances[i]).div(
                    10**uint256(ERC20Detailed(tokens[i]).decimals())
                )
            );
        }
        return portfolio;
    }

    function getTVL(address[] memory vaults) public view returns (uint256) {
        uint256 tvl;
        for (uint256 i = 0; i < vaults.length; i += 1) {
            uint256 price = getPrice(IVault(vaults[i]).underlying());
            uint256 investment =
                IVault(vaults[i]).underlyingBalanceWithInvestment();
            tvl = tvl.add(price.mul(investment));
        }
        return tvl;
    }

    function getVaultEarning(address vault)
        public
        view
        returns (uint256, uint256)
    {
        address underlying = IVault(vault).underlying();
        uint256 totalEarning =
            IVault(vault).underlyingBalanceWithInvestment().sub(
                IVault(vault).totalDeposits()
            );
        uint256 totalEarningInUSD =
            totalEarning.mul(getPrice(underlying)).div(
                10**uint256(ERC20Detailed(underlying).decimals())
            );
        return (totalEarning, totalEarningInUSD);
    }

    function getUserVaultEarning(address vault, address user)
        public
        view
        returns (uint256, uint256)
    {
        (uint256 totalEarning, uint256 totalEarningInUSD) =
            getVaultEarning(vault);
        uint256 position =
            IERC20(vault).balanceOf(user).add(
                IERC20(rewardPools[vault]).balanceOf(user)
            );
        uint256 vaultTotalSupply = IERC20(vault).totalSupply();
        uint256 userEarning = totalEarning.mul(position).div(vaultTotalSupply);
        uint256 userEarningInUSD =
            totalEarningInUSD.mul(position).div(vaultTotalSupply);
        return (userEarning, userEarningInUSD);
    }

    function getUserVaultEarning(address[] memory vaults, address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory earnings = new uint256[](vaults.length);
        uint256[] memory earningsInUSD = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i += 1) {
            (earnings[i], earningsInUSD[i]) = getUserVaultEarning(
                vaults[i],
                user
            );
        }
        return (earnings, earningsInUSD);
    }
}
