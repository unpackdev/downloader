// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./PartLib.sol";

library RoyaltiesLib {
    bytes4 constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96 constant _WEIGHT_VALUE = 1000000;

    function calculateRoyalties(address to, uint256 amount) internal view returns (PartLib.PartData[] memory) {
        PartLib.PartData[] memory result;
        if (amount == 0) {
            return result;
        }
        uint256 percent = (amount * 100 / _WEIGHT_VALUE) * 100;
        require(percent < 10000, "Royalties 2981, than 100%");
        result = new PartLib.PartData[](1);
        result[0].account = payable(to);
        result[0].value = uint96(percent);
        return result;
    }
}