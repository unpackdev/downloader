// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICSSRAdapter.sol";
import "./ICSSRRouter.sol";
import "./IWSOHM.sol";

contract wsOHMAdapter is ICSSRAdapter {
    ICSSRRouter public immutable cssrRouter;
    address public immutable ohm;
    IWSOHM public immutable wsOHM;

    constructor(address _cssr, address _ohm, address _wsOHM) {
        cssrRouter = ICSSRRouter(_cssr);
        ohm = _ohm;
        wsOHM = IWSOHM(_wsOHM);
    }

    function update(address _asset, bytes calldata _data)
        external
        override
        returns (float memory)
    {
        return getPrice(_asset);
    }
    
    function support(address _asset) external view override returns (bool) {
        return _asset == address(wsOHM);
    }

    function getPrice(address _asset) public view override returns(float memory) {
        require(_asset == address(wsOHM), "!support");
        float memory ohmPrice = cssrRouter.getPrice(ohm);
        return float({
            numerator: wsOHM.wOHMTosOHM(ohmPrice.numerator),
            denominator: ohmPrice.denominator
        });
    }

    function getLiquidity(address _asset)
        external
        view
        override
        returns (uint256)
    {
        revert("chainlink adapter does not support liquidity");
    }
}
