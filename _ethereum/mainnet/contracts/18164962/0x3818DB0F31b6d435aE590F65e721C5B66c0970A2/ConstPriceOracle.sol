pragma solidity 0.5.8;

contract ConstPriceOracle {

    address asset;
    uint256 price;

    constructor(
        address _asset,
        uint256 _price
    )
        public
    {
        asset = _asset;
        price = _price;
    }

    function getPrice(
        address _asset
    )
        external
        view
        returns (uint256)
    {
        require(asset == _asset, "ASSET_NOT_MATCH");
        return price;
    }
}