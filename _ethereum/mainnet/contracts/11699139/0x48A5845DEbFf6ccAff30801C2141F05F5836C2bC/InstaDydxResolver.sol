pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ERC20Interface {
    function allowance(address, address) external view returns (uint);
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}


interface SoloMarginContract {

    struct Info {
        address owner;
        uint256 number;
    }


    struct Wei {
        bool sign;
        uint256 value;
    }

    struct Price {
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    function getMarketPrice(uint256 marketId) external view returns (Price memory);
    function getAccountWei(Info calldata account, uint256 marketId) external view returns (Wei memory);
    function getMarketTotalPar(uint256 marketId) external view returns (TotalPar memory);
    function getMarketCurrentIndex(uint256 marketId) external view returns (Index memory);
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract Helpers is DSMath{

    /**
     * @dev get Dydx Solo Address
    */
    function getSoloAddress() public pure returns (address addr) {
        addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    }

    /**
    * @dev Get Dydx Account Arg
    */
    function getAccountArgs(address owner) internal pure returns (SoloMarginContract.Info memory) {
        SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
        accounts[0] = (SoloMarginContract.Info(owner, 0));
        return accounts[0];
    }

    struct DydxData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
        uint supplyBalance;
        uint borrowBalance;
        uint availableLiquidity;
        uint tokenUtil;
        // uint collateralFactor;
    }

    struct TokenData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
        uint balance;
    }

    function getTokenPrice(SoloMarginContract solo, uint[] memory marketId) internal view returns(TokenData[] memory tokenData) {
        uint ethPrice = solo.getMarketPrice(0).value;
        tokenData = new TokenData[](marketId.length);
        for (uint i = 0; i < marketId.length; i++) {
            uint decimals = marketId[i] == 0 ? 18 : ERC20Interface(solo.getMarketTokenAddress(marketId[i])).decimals();
            tokenData[i].balance = marketId[i] == 0 ? address(solo).balance : ERC20Interface(solo.getMarketTokenAddress(marketId[i])).balanceOf(address(solo));
            uint price = marketId[i] == 1 ? 10 ** 18 : solo.getMarketPrice(marketId[i]).value;
            tokenData[i].tokenPriceInUsd = price / 10 ** (18 - decimals);
            tokenData[i].tokenPriceInEth = wdiv(tokenData[i].tokenPriceInUsd, ethPrice); 
        }
    }
}


contract Resolver is Helpers {
    function getPosition(address user, uint[] memory marketId) public view returns(DydxData[] memory) {
        SoloMarginContract solo = SoloMarginContract(getSoloAddress());
        DydxData[] memory tokensData = new DydxData[](marketId.length);
        TokenData[] memory tokenData = getTokenPrice(solo, marketId);
        for (uint i = 0; i < marketId.length; i++) {
            uint id = marketId[i];
            SoloMarginContract.Wei memory tokenBal = solo.getAccountWei(getAccountArgs(user), id);
            SoloMarginContract.TotalPar memory totalPar = solo.getMarketTotalPar(id);
            SoloMarginContract.Index memory rateIndex = solo.getMarketCurrentIndex(id);

            tokensData[i] = DydxData(
                tokenData[i].tokenPriceInUsd,
                tokenData[i].tokenPriceInEth,
                tokenBal.sign ? tokenBal.value : 0,
                !tokenBal.sign ? tokenBal.value : 0,
                tokenData[i].balance,
                wdiv(wmul(totalPar.borrow, rateIndex.borrow), wmul(totalPar.supply, rateIndex.supply))
            );
        }
        return tokensData;
    }
}

contract InstaDydxResolver is Resolver {
    string public constant name = "Dydx-Resolver-v1.1";
}