//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

contract InfoReader {
    function getTokenBalances(IERC20 _token, address[] memory _accounts) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = _token.balanceOf(_accounts[i]);
        }

        return balances;
    }

    function getContractInfo(address[] memory _accounts) public view returns (bool[] memory) {
        bool[] memory info = new bool[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            info[i] = isContract(_accounts[i]);
        }

        return info;
    }

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
