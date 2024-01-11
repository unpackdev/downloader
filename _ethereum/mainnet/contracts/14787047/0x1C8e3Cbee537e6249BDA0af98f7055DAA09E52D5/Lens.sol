pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ApeErc20.sol";
import "./Comptroller.sol";
import "./ApeToken.sol";
import "./PriceOracle.sol";
import "./EIP20Interface.sol";
import "./Exponential.sol";

contract Lens is Exponential {
    struct ApeTokenMetadata {
        address apeToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        uint256 totalCollateralTokens;
        bool isListed;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 apeTokenDecimals;
        uint256 underlyingDecimals;
        ApeToken.Version version;
        uint256 collateralCap;
        uint256 underlyingPrice;
        bool supplyPaused;
        bool borrowPaused;
        uint256 supplyCap;
        uint256 borrowCap;
    }

    function apeTokenMetadataInternal(
        ApeToken apeToken,
        Comptroller comptroller,
        PriceOracle priceOracle
    ) internal returns (ApeTokenMetadata memory) {
        uint256 exchangeRateCurrent = apeToken.exchangeRateCurrent();
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(address(apeToken));
        address underlyingAssetAddress;
        uint256 underlyingDecimals;
        uint256 collateralCap;
        uint256 totalCollateralTokens;

        if (compareStrings(apeToken.symbol(), "crETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            ApeErc20 apeErc20 = ApeErc20(address(apeToken));
            underlyingAssetAddress = apeErc20.underlying();
            underlyingDecimals = EIP20Interface(apeErc20.underlying()).decimals();
        }

        if (apeToken.version() == ApeTokenStorage.Version.COLLATERALCAP) {
            collateralCap = ApeCollateralCapErc20Interface(address(apeToken)).collateralCap();
            totalCollateralTokens = ApeCollateralCapErc20Interface(address(apeToken)).totalCollateralTokens();
        } else if (apeToken.version() == ApeTokenStorage.Version.WRAPPEDNATIVE) {
            collateralCap = ApeWrappedNativeInterface(address(apeToken)).collateralCap();
            totalCollateralTokens = ApeWrappedNativeInterface(address(apeToken)).totalCollateralTokens();
        }

        return
            ApeTokenMetadata({
                apeToken: address(apeToken),
                exchangeRateCurrent: exchangeRateCurrent,
                supplyRatePerBlock: apeToken.supplyRatePerBlock(),
                borrowRatePerBlock: apeToken.borrowRatePerBlock(),
                reserveFactorMantissa: apeToken.reserveFactorMantissa(),
                totalBorrows: apeToken.totalBorrows(),
                totalReserves: apeToken.totalReserves(),
                totalSupply: apeToken.totalSupply(),
                totalCash: apeToken.getCash(),
                totalCollateralTokens: totalCollateralTokens,
                isListed: isListed,
                collateralFactorMantissa: collateralFactorMantissa,
                underlyingAssetAddress: underlyingAssetAddress,
                apeTokenDecimals: apeToken.decimals(),
                underlyingDecimals: underlyingDecimals,
                version: apeToken.version(),
                collateralCap: collateralCap,
                underlyingPrice: priceOracle.getUnderlyingPrice(apeToken),
                supplyPaused: comptroller.mintGuardianPaused(address(apeToken)),
                borrowPaused: comptroller.borrowGuardianPaused(address(apeToken)),
                supplyCap: comptroller.supplyCaps(address(apeToken)),
                borrowCap: comptroller.borrowCaps(address(apeToken))
            });
    }

    function apeTokenMetadata(ApeToken apeToken) public returns (ApeTokenMetadata memory) {
        Comptroller comptroller = Comptroller(address(apeToken.comptroller()));
        PriceOracle priceOracle = comptroller.oracle();
        return apeTokenMetadataInternal(apeToken, comptroller, priceOracle);
    }

    function apeTokenMetadataAll(ApeToken[] calldata apeTokens) external returns (ApeTokenMetadata[] memory) {
        uint256 apeTokenCount = apeTokens.length;
        require(apeTokenCount > 0, "invalid input");
        ApeTokenMetadata[] memory res = new ApeTokenMetadata[](apeTokenCount);
        Comptroller comptroller = Comptroller(address(apeTokens[0].comptroller()));
        PriceOracle priceOracle = comptroller.oracle();
        for (uint256 i = 0; i < apeTokenCount; i++) {
            require(address(comptroller) == address(apeTokens[i].comptroller()), "mismatch comptroller");
            res[i] = apeTokenMetadataInternal(apeTokens[i], comptroller, priceOracle);
        }
        return res;
    }

    struct ApeTokenBalances {
        address apeToken;
        uint256 balanceOf;
        uint256 borrowBalanceCurrent;
        uint256 balanceOfUnderlying;
        uint256 tokenBalance;
        uint256 tokenAllowance;
        bool collateralEnabled;
        uint256 collateralBalance;
        uint256 nativeTokenBalance;
    }

    function apeTokenBalances(ApeToken apeToken, address payable account) public returns (ApeTokenBalances memory) {
        address comptroller = address(apeToken.comptroller());
        bool collateralEnabled = Comptroller(comptroller).checkMembership(account, apeToken);
        uint256 tokenBalance;
        uint256 tokenAllowance;
        uint256 collateralBalance;

        if (compareStrings(apeToken.symbol(), "crETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            ApeErc20 apeErc20 = ApeErc20(address(apeToken));
            EIP20Interface underlying = EIP20Interface(apeErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(apeToken));
        }

        if (collateralEnabled) {
            (, collateralBalance, , ) = apeToken.getAccountSnapshot(account);
        }

        return
            ApeTokenBalances({
                apeToken: address(apeToken),
                balanceOf: apeToken.balanceOf(account),
                borrowBalanceCurrent: apeToken.borrowBalanceCurrent(account),
                balanceOfUnderlying: apeToken.balanceOfUnderlying(account),
                tokenBalance: tokenBalance,
                tokenAllowance: tokenAllowance,
                collateralEnabled: collateralEnabled,
                collateralBalance: collateralBalance,
                nativeTokenBalance: account.balance
            });
    }

    function apeTokenBalancesAll(ApeToken[] calldata apeTokens, address payable account)
        external
        returns (ApeTokenBalances[] memory)
    {
        uint256 apeTokenCount = apeTokens.length;
        ApeTokenBalances[] memory res = new ApeTokenBalances[](apeTokenCount);
        for (uint256 i = 0; i < apeTokenCount; i++) {
            res[i] = apeTokenBalances(apeTokens[i], account);
        }
        return res;
    }

    struct AccountLimits {
        ApeToken[] markets;
        uint256 liquidity;
        uint256 shortfall;
    }

    function getAccountLimits(Comptroller comptroller, address account) public returns (AccountLimits memory) {
        (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall});
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
