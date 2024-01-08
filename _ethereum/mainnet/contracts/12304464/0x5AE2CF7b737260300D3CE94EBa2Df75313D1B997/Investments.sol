//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ILendingPool.sol";
import "./ISoloMargin.sol";
import "./ICToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

interface IAaveAddressProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);
}

interface IProtocolDataProvider {
    function getUserReserveData(address reserve, address user)
        external
        view
        returns (
            uint256 currentATokenBalance
        );
}

contract Investments is Ownable{
    using SafeMath for uint256;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    mapping(address => address) internal cTokens;
    mapping(address => uint256) internal dydxMarkets;

    IAaveAddressProvider aaveProvider = IAaveAddressProvider(
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
    );

    IProtocolDataProvider aaveDataProviderV2 = IProtocolDataProvider(
        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d
    );

    ISoloMargin solo = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    struct Balance {
        uint256 dydx;
        uint256 compound;
        uint256 aave;
        uint256 aaveV2;
    }

    constructor() {
        cTokens[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5; // ETH
        cTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC
        cTokens[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI
        cTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT

        dydxMarkets[ETH] = 1;
        dydxMarkets[WETH] = 1;
        dydxMarkets[USDC] = 3;
        dydxMarkets[DAI] = 4;    
    }

    function getCToken(address token) public view returns (address) {
        return cTokens[token];
    }

    function addCToken(address token, address _cToken) external onlyOwner{
        cTokens[token] = _cToken;
    }

    function getMarketId(address token) public view returns (uint256) {
        return dydxMarkets[token] -1;
    }

    function addDydxMarket(address token, uint marketId) external onlyOwner{
        dydxMarkets[token] = marketId;
    }

    function getDydxBalance(address token, address user)
        public
        view
        returns (uint256)
    {
        uint256 marketId = getMarketId(token);
        if (marketId == uint256(-1)) return 0;

        ISoloMargin.Wei memory accountWei = solo.getAccountWei(
            ISoloMargin.Info(user, 0),
            marketId
        );
        return accountWei.sign ? accountWei.value : 0;
    }

    function getCompoundBalance(address token, address user)
        public
        view
        returns (uint256)
    {
        (, uint256 balance, , uint256 rate) = CTokenInterface(getCToken(token)).getAccountSnapshot(user);

        return balance.mul(rate).div(1 ether);
    }

    function getAaveBalance(address token, address account)
        public
        view
        returns (uint256 balance)
    {
        (balance, , ) = ILendingPool(aaveProvider.getLendingPool())
            .getUserReserveData(token, account);
    }

    function getAaveBalanceV2(address token, address account)
        public
        view
        returns (uint256)
    {
        return aaveDataProviderV2.getUserReserveData(token == ETH ? WETH:token, account);
    }

    function getBalances(address[] calldata tokens, address user)
        external
        view
        returns (Balance[] memory)
    {
        Balance[] memory balances = new Balance[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i].compound = getCompoundBalance(tokens[i], user);
            balances[i].aave = getAaveBalance(tokens[i], user);
            balances[i].aaveV2 = getAaveBalanceV2(tokens[i], user);
            balances[i].dydx = getDydxBalance(tokens[i], user);
        }

        return balances;
    }
}
