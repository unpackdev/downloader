// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./AggregatorV3Interface.sol";

contract AssetOracle {
    using SafeMath for uint256;
    using Address for address;

    address public owner;

    mapping(address => address) private assetTokenFeed;
    address[] public supportedAssets;

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized: owner only");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function isSupportedAsset(address _asset) external view returns (bool) {
        return assetTokenFeed[_asset] != address(0);
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function _addSupportedAsset(address _asset, address _priceFeed) internal {
        uint8 _decs = AggregatorV3Interface(_priceFeed).decimals();
        // If decimals is not 8, price calculation vuln will occur
        require(_decs == 8, "Not USD feed");

        uint8 _ercDecs = ERC20(_asset).decimals();
        require(_ercDecs <= 18, "Logic not implemented for assets with decimals > 18");
        assetTokenFeed[_asset] = _priceFeed;
        supportedAssets.push(_asset);
    }

    function addSupportedAssets(address[] memory _assets, address[] memory _priceFeeds) external onlyOwner {
        require(_assets.length == _priceFeeds.length, "Not equal arrays");
        uint256 _length = _assets.length;

        for(uint256 i = 0; i < _length; i++) {
            _addSupportedAsset(_assets[i], _priceFeeds[i]);
        }
    }

    // Returns USD value of asset with 8 decimals
    function _assetValue(address _asset, uint256 _amount) internal view returns (uint256) {
        if(assetTokenFeed[_asset] == address(0)) {
            // Safe fail for unknown assets
            return 0;
        }
        (, int price, , ,) = AggregatorV3Interface(assetTokenFeed[_asset]).latestRoundData();
        uint8 assetDecimals = ERC20(_asset).decimals();
        uint256 finalValue = uint256(price).mul(_amount).div(10**uint256(assetDecimals));
        return finalValue;
    }

    function assetValue(address _asset, uint256 _amount) external view returns (uint256) {
        return _assetValue(_asset, _amount);
    }

    function aum(address[] memory _assets, uint256[] memory _amounts) public view returns (uint256) {
        require(_assets.length == _amounts.length, "Not equal arrays");
        uint256 _length = _assets.length;

        uint256 _aum = 0;
        for(uint256 i = 0; i < _length; i++) {
            _aum = _aum.add(_assetValue(_assets[i], _amounts[i]));
        }

        return _aum;
    }

    function aumDepositAsset(address _depositAsset, address[] memory _assets, uint256[] memory _amounts) external view returns (uint256) {
        if(assetTokenFeed[_depositAsset] == address(0)) {
            // Safe fail for unknown assets
            return 0;
        }

        uint256 _aumUSD = aum(_assets, _amounts); // 8 decimals
        (, int price, , ,) = AggregatorV3Interface(assetTokenFeed[_depositAsset]).latestRoundData(); // 8 decimals
        uint8 _decimalsDepositAsset = ERC20(_depositAsset).decimals();
        uint256 _aumDepositAsset = _aumUSD.mul(10**uint256(_decimalsDepositAsset)).div(uint256(price));
        return _aumDepositAsset;
    }

    function getSupportedAssetsLength() external view returns (uint) {
        return supportedAssets.length;
    }
}