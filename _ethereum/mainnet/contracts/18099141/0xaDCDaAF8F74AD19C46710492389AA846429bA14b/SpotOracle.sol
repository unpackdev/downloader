pragma solidity 0.8.19;

import "Ownable.sol";

interface IStableSwap {
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function fee() external view returns (uint256);
}

interface IEACAggregatorProxy {
    function latestAnswer() external view returns (int256);
}

interface ISpotOracle {
    function getPrice() external view returns (uint256);
}

contract SpotOracleAggregator is Ownable {
    ISpotOracle[] public oracles;

    constructor(ISpotOracle[] memory _oracles) {
        oracles = _oracles;
    }

    /**
        @notice Get the spot price of mkUSD, expressed as a whole number with a precision of 1e18
        @dev THIS ORACLE IS EASILY MANIPULATED! IT IS NOT ACCEPTABLE FOR ON-CHAIN USE!
     */
    function getPrice() external view returns (uint256) {
        uint total;
        for (uint i = 0; i < oracles.length; i++) {
            total += oracles[i].getPrice();
        }
        return total / oracles.length;
    }

    function oracleCount() external view returns (uint256) {
        return oracles.length;
    }

    function addOracle(ISpotOracle oracle) external onlyOwner {
        uint length = oracles.length;
        for (uint i = 0; i < length; i++) {
            if (oracles[i] == oracle) revert("Oracle already added");
        }
        oracles.push(oracle);
    }

    function removeOracle(ISpotOracle oracle) external onlyOwner {
        ISpotOracle last = oracles[oracles.length - 1];
        oracles.pop();
        if (last == oracle) return;
        uint length = oracles.length;
        for (uint i = 0; i < length; i++) {
            if (oracles[i] == oracle) {
                oracles[i] = last;
                return;
            }
        }
        revert("Oracle not found");
    }
}

contract SpotOracle {
    IStableSwap public constant MKUSD_FRAXP = IStableSwap(0x0CFe5C777A7438C9Dd8Add53ed671cEc7A5FAeE5);
    IEACAggregatorProxy public constant USDC_USD = IEACAggregatorProxy(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);

    /**
        @notice Get the spot price of mkUSD, expressed as a whole number with a precision of 1e18
        @dev THIS ORACLE IS EASILY MANIPULATED! IT IS NOT ACCEPTABLE FOR ON-CHAIN USE!
     */
    function getPrice() external view returns (uint256) {
        // amount received from swaping 1 mkUSD -> USDC, normalized to 1e18
        uint256 dy = MKUSD_FRAXP.get_dy_underlying(0, 2, 1e18) * 1e12;

        // mkusd/fraxbp fee, normalized to 1e18
        uint256 fee = (MKUSD_FRAXP.fee() + 1e10) * 1e8;

        // chainlink usdc/usd price, normalized to 1e18
        uint256 usdc = uint256(USDC_USD.latestAnswer()) * 1e10;

        return (dy * fee * usdc) / 1e36;
    }
}
