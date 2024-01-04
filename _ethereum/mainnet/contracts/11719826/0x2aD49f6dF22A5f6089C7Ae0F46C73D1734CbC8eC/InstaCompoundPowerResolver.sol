pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint);
    function borrowBalanceStored(address) external view returns (uint);

    function balanceOf(address) external view returns (uint);
    function underlying() external view returns (address);
}

interface TokenInterface {
    function decimals() external view returns (uint);
    function balanceOf(address) external view returns (uint);
}

interface OrcaleComp {
    function getUnderlyingPrice(address) external view returns (uint);
}

interface ComptrollerLensInterface {
    function oracle() external view returns (address);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}
contract Helpers is DSMath {
    /**
     * @dev get Compound Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    }

    /**
     * @dev get Compound Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

     /**
     * @dev get ETH Address
     */
    function getCETHAddress() public pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }


    struct CompData {
        uint balanceOfUser;
        uint borrowBalanceStoredUser;
    }
    struct data {
        address user;
        CompData[] tokensData;
    }
    
     struct datas {
        CompData[] tokensData;
    }

    struct CompoundTokensData {
        uint tokenPriceInEth;
        uint tokenPriceInUsd;
        uint exchangeRateStored;
    }
}


contract InstaCompoundPowerResolver is Helpers {
    function getPriceInEth(CTokenInterface cToken) public view returns (uint priceInETH, uint priceInUSD) {
        uint decimals = getCETHAddress() == address(cToken) ? 18 : TokenInterface(cToken.underlying()).decimals();
        uint price = OrcaleComp(getOracleAddress()).getUnderlyingPrice(address(cToken));
        uint ethPrice = OrcaleComp(getOracleAddress()).getUnderlyingPrice(getCETHAddress());
        priceInUSD = price / 10 ** (18 - decimals);
        priceInETH = wdiv(priceInUSD, ethPrice);
    }

    function getCompoundTokensData(address[] memory cAddress) public  view returns (CompoundTokensData[] memory) {
        CompoundTokensData[] memory compoundTokensData = new CompoundTokensData[](cAddress.length);
         for (uint i = 0; i < cAddress.length; i++) {
            (uint priceInETH, uint priceInUSD) = getPriceInEth(CTokenInterface(cAddress[i]));
            CTokenInterface cToken = CTokenInterface(cAddress[i]);
            compoundTokensData[i] = CompoundTokensData(
                priceInETH,
                priceInUSD,
                cToken.exchangeRateStored()
            );
        }

        return compoundTokensData;
    }

    function getCompoundData(address owner, address[] memory cAddress) public view returns (CompData[] memory) {
        CompData[] memory tokensData = new CompData[](cAddress.length);
        for (uint i = 0; i < cAddress.length; i++) {
            CTokenInterface cToken = CTokenInterface(cAddress[i]);
            tokensData[i] = CompData(
                cToken.balanceOf(owner),
                cToken.borrowBalanceStored(owner)
            );
        }

        return tokensData;
    }
    
    function getCompoundDataByToken(address[] memory owners, address cAddress) public view returns (CompData[] memory) {
        CompData[] memory tokensData = new CompData[](owners.length);
        CTokenInterface cToken = CTokenInterface(cAddress);
        for (uint i = 0; i < owners.length; i++) {
            tokensData[i] = CompData(
                cToken.balanceOf(owners[i]),
                cToken.borrowBalanceStored(owners[i])
            );
        }

        return tokensData;
    }

    function getPositionByAddress(
        address[] memory owners,
        address[] memory cAddress
    )
        public
        view
        returns (datas[] memory)
    {
        datas[] memory _data = new datas[](cAddress.length);
        for (uint i = 0; i < cAddress.length; i++) {
            _data[i] = datas(
                getCompoundDataByToken(owners, cAddress[i])
            );
        }
        return _data;
    }
}