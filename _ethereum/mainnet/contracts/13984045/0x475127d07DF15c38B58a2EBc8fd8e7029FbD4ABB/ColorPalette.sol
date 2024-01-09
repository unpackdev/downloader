// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Color.sol";
import "./IColorProvider.sol";
import "./Base64.sol";

abstract contract ColorPalette {
    struct ColorDependency {
        IColorProvider provider;
        uint96 accumulateAmount;
    }

    ColorDependency[] public _colorProviders;

    function _setColorProviders(IColorProvider[] memory colorProviders) internal {
        delete _colorProviders;

        uint96 accAmount = 0;
        for (uint i = 0; i < colorProviders.length; i++) {
            IColorProvider p = colorProviders[i];

            accAmount += uint96(p.totalAmount());
            _colorProviders.push(ColorDependency(p, accAmount));
        }
    }

    function getColor(uint16 id) public view returns (Color memory) {
        uint256 providerCount = _colorProviders.length;
        uint96 lastAccAmount = 0;

        for (uint i = 0; i < providerCount; i++) {
            ColorDependency memory dep = _colorProviders[i];

            if (id < dep.accumulateAmount) return dep.provider.getColor(id - lastAccAmount);
            lastAccAmount = dep.accumulateAmount;
        }

        revert("ColorPalette: id of color cannot exceed 16,000");
    }
}