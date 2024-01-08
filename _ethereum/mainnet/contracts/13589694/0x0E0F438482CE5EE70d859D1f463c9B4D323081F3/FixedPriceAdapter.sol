// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./Float.sol";
import "./IGovernanceOwned.sol";
import "./ICSSRAdapter.sol";

contract FixedPriceAdapter is ICSSRAdapter {
    IGovernanceOwned public immutable owned;

    mapping(address => uint256) public numerator;
    
    modifier onlyGov() {
        require(msg.sender == owned.governance(), "!gov");
        _;
    }

    constructor(address _owned) {
        owned = IGovernanceOwned(_owned);
    }

    function setPrice(address[] calldata _assets, uint256[] calldata _numerators) external onlyGov {
        for(uint256 i = 0; i<_assets.length; i++) {
            numerator[_assets[i]] = _numerators[i];
        }
    }

    function update(address _asset, bytes calldata _data)
        external
        override
        returns (float memory)
    {
        return getPrice(_asset);
    }
    
    function support(address _asset) external view override returns (bool) {
        return numerator[_asset] != 0;
    }

    function getPrice(address _asset)
        public
        view
        override
        returns (float memory)
    {
        require(numerator[_asset] != 0, "!supported");
        return float({
            numerator: numerator[_asset],
            denominator: 1e18
        });
    }

    function getLiquidity(address _asset)
        public
        view
        override
        returns(uint256)
    {
        revert("fixed price adapter does not support liquidity");
    }
}
