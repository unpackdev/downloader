// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./Swap.sol";
import "./TransferHelper.sol";

contract SwapFactoryExtended {
    address private mainFactory;
    
    modifier onlyMainFactory(){
        require(msg.sender == mainFactory, "Not admin");
        _;
    }

    constructor(address _mainFactory){
        require(_mainFactory != address(0x00), "Wrong address");
        mainFactory = _mainFactory;
    }



    function createLinkFeedWithApiSwap(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyMainFactory returns( address ) {
        Swap swap = new Swap(_commodityToken, _stableToken, _dexSettings, _apiInfo);
        //tranfer ownership to mainfactory
        swap.transferOwnership(msg.sender);
        return address(swap);
    }
}
