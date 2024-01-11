// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

library Util {
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // Anti bots Implementation
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ensureOneHuman(address _to, address _from) internal view returns (address) {
        require(!isContract(_to) || !isContract(_from), "No bots allowed!");
        if (isContract(_to)) return _from;
        else return _to;
    }
}
