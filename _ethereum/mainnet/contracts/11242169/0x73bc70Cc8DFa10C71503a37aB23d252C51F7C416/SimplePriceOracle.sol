pragma solidity ^0.6.0;

import "./PERC20.sol";
import "./IPriceOracle.sol";
import "./PToken.sol";
import "./Ownable.sol";
import "./Initializable.sol";

contract SimplePriceOracle is IPriceOracle, OwnableUpgradeSafe {

    struct Datum {
        uint timestamp;
        uint price;
    }

    mapping(address => Datum) private data;

    address private _pETHUnderlying;

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa, uint timestamp);

    function initialize() public initializer {
        _pETHUnderlying = address(0x0000000000000000000000000000000000000000);
        OwnableUpgradeSafe.__Ownable_init();
    }


    function getUnderlyingPrice(PToken pToken) public override view returns (uint) {
        if (compareStrings(pToken.symbol(), "pETH") || compareStrings(pToken.symbol(), "cETH")) {
            return data[_pETHUnderlying].price;
        } else {
            return data[address(PERC20(address(pToken)).underlying())].price;
        }
    }

    function setUnderlyingPrice(PToken pToken, uint price) public onlyOwner {
        address asset = _pETHUnderlying;
        if (!compareStrings(pToken.symbol(), "pETH") || !compareStrings(pToken.symbol(), "cETH")) {
            asset = address(PERC20(address(pToken)).underlying());
        }
        uint bt = block.timestamp;
        data[asset] = Datum(bt, price);
        emit PricePosted(asset, data[asset].price, price, price, bt);
    }

    function setPrice(address asset, uint price) public onlyOwner {
        uint bt = block.timestamp;
        emit PricePosted(asset, data[asset].price, price, price, bt);
        data[asset] = Datum(bt, price);
    }

    function getPrice(address asset) external view returns (uint) {
        return data[asset].price;
    }

    function get(address asset) external view returns (uint256, uint)  {
        return (data[asset].timestamp, data[asset].price);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
