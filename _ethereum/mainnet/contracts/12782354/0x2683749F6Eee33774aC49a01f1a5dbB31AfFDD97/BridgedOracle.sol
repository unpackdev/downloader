// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "./ChainlinkOracle.sol";

contract BridgedOracle is PriceOracle {
    address public admin;
    ChainlinkOracle public chainlink;
    PriceOracle public uniswap;

    mapping(address => bool) chainlinkAssets;

    constructor(address _chainlink, address _uniswap) public {
        admin = msg.sender;
        chainlink = ChainlinkOracle(_chainlink);
        uniswap = PriceOracle(_uniswap);
    }

    modifier onlyAdmin() {
      require(msg.sender == admin, "only admin may call");
      _;
    }

    function getUnderlyingPriceView(CToken cToken) public view override returns (uint) {
        if (chainlinkAssets[address(cToken)]) {
            return chainlink.getUnderlyingPriceView(cToken);
        } else {
            return uniswap.getUnderlyingPriceView(cToken);
        }
    }

    function getUnderlyingPrice(CToken cToken) public override returns (uint) {
        if (chainlinkAssets[address(cToken)]) {
            return chainlink.getUnderlyingPrice(cToken);
        } else {
            return uniswap.getUnderlyingPrice(cToken);
        }
    }

    function registerChainlinkAsset(address token, string calldata symbol, address feed, bool base) public onlyAdmin() {
        require(!chainlinkAssets[token], "Already registered");
        chainlinkAssets[token] = true;
        chainlink.setFeed(symbol, feed, base);
    }

    function deregisterChainlinkAsset(address token) public onlyAdmin() {
        require(chainlinkAssets[token], "Already deregistered");
        chainlinkAssets[token] = false;
    }

    function getChainlinkAsset(address token) public view returns(bool) {
        return chainlinkAssets[token];
    }

    function releaseChainlink(address newAdmin) public onlyAdmin() {
        chainlink.setAdmin(newAdmin);
    }

    function updateUniswap(address newUniswap) public onlyAdmin() {
        uniswap = PriceOracle(newUniswap);
    }
}
