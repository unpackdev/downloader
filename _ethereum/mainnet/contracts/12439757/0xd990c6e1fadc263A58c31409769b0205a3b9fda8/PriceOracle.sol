// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./Initializable.sol";
import "./IUniswapPairsOracle.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract PriceOracle is Initializable {

    address public wethAddress;
    address public wethDaiPairAddress;
    IUniswapPairsOracle public UniswapPairsOracle;
    
    function initialize(IUniswapPairsOracle _UniswapPairsOracleAddress, address _wethAddress, address _daiAddress) public initializer {
        require(address(_UniswapPairsOracleAddress) != address(0), "PriceOracle: invalid _UniswapPairsOracleAddress");
        require(_wethAddress != address(0), "PriceOracle: invalid _wethAddress");
        require(_daiAddress != address(0), "PriceOracle: invalid _daiAddress");
        require(IERC20(_wethAddress).decimals() == 18, "PriceOracle: _wethAddress token should has 18 decimals");
        require(IERC20(_daiAddress).decimals() == 18, "PriceOracle: _daiAddress token should has 18 decimals");

        UniswapPairsOracle = _UniswapPairsOracleAddress;
        wethAddress = _wethAddress;
        UniswapPairsOracle.addPair(_wethAddress, _daiAddress);
        wethDaiPairAddress = UniswapPairsOracle.pairFor(_wethAddress, _daiAddress);
    }

    function addToken(address token) external returns (bool success) {
        return UniswapPairsOracle.addPair(wethAddress, token);
    }

    function update(address token) external {
        UniswapPairsOracle.update(wethDaiPairAddress);
        UniswapPairsOracle.update(UniswapPairsOracle.pairFor(wethAddress, token));
    }
    
    function priceOf(address token, uint256 amount) external view returns (uint256 daiAmount) {
        uint256 wethAmount = UniswapPairsOracle.consult(UniswapPairsOracle.pairFor(wethAddress, token), token, amount);
        if (wethAmount == 0) {
            return 0;
        }
        daiAmount = UniswapPairsOracle.consult(wethDaiPairAddress, wethAddress, wethAmount);
    }
}