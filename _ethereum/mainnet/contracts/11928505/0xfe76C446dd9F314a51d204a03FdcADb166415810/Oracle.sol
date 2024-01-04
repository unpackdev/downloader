// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IChainLinkOracle.sol";
import "./IKeeperOracle.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Oracle is Ownable {
    mapping(address => address) public chainlinkPriceUSD;
    mapping(address => address) public chainlinkPriceETH;

    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IKeeperOracle public keeperOracle = IKeeperOracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);

    constructor () {
        chainlinkPriceUSD[weth] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        chainlinkPriceUSD[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // wBTC
        chainlinkPriceUSD[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // renBTC
        chainlinkPriceUSD[0x4688a8b1F292FDaB17E9a90c8Bc379dC1DBd8713] = 0x0ad50393F11FfAc4dd0fe5F1056448ecb75226Cf; // COVER
        chainlinkPriceUSD[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9; // DAI
        chainlinkPriceUSD[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // USDC
        chainlinkPriceUSD[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D; // USDT

        chainlinkPriceETH[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = 0x7c5d4F8345e66f68099581Db340cd65B078C41f4; // YFI
        chainlinkPriceETH[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = 0xe572CeF69f43c2E488b33924AF04BDacE19079cf; // SUSHI
        chainlinkPriceETH[0x4E15361FD6b4BB609Fa63C81A2be19d873717870] = 0x2DE7E4a9488488e0058B95854CC2f7955B35dC9b; // FTM
        chainlinkPriceETH[0x2ba592F78dB6436527729929AAf6c908497cB200] = 0x82597CFE6af8baad7c0d441AA82cbC3b51759607; // CREAM
        chainlinkPriceETH[0x4688a8b1F292FDaB17E9a90c8Bc379dC1DBd8713] = 0x7B6230EF79D5E97C11049ab362c0b685faCBA0C2; // COVER
        initializeOwner();
    }

    /// @notice Returns price in USD multiplied by 1e8, chainlink.latestAnswer returns 1e8 for all answers, keeperOracle.current returns 1e18
    function getPriceUSD(address _asset) external view returns (uint256 _price) {
        if (chainlinkPriceUSD[_asset] != address(0)) {
            _price = IChainLinkOracle(chainlinkPriceUSD[_asset]).latestAnswer();
        } else if (chainlinkPriceETH[_asset] != address(0)) {
            // all price returned in ETH are 1e18
            uint256 _priceInETH = IChainLinkOracle(chainlinkPriceETH[_asset]).latestAnswer();
            // all price returned in USD are 1e8
            _price = _priceInETH * IChainLinkOracle(chainlinkPriceUSD[weth]).latestAnswer() / 1e18;
        } else {
            address pair = keeperOracle.pairFor(_asset, weth);
            if (keeperOracle.observationLength(pair) > 0) {
                uint256 _priceInETH = keeperOracle.current(_asset, 10 ** IERC20(_asset).decimals(), weth);
                _price = _priceInETH * IChainLinkOracle(chainlinkPriceUSD[weth]).latestAnswer() / 1e18;
            }
        }
    }

    function updateFeedETH(address _asset, address _feed) external onlyOwner {
        chainlinkPriceETH[_asset] = _feed; // 0x0 to remove feed
    }
    
    function updateFeedUSD(address _asset, address _feed) external onlyOwner {
        chainlinkPriceUSD[_asset] = _feed; // 0x0 to remove feed
    }

    function setKeeperOracle(IKeeperOracle _oracle) external onlyOwner {
        require(address(_oracle) != address(0), "Oracle: IKeeperOracle is 0");
        keeperOracle = _oracle;
    }
}