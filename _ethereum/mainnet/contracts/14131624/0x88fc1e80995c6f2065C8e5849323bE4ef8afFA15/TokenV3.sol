// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import "./TokenV2.sol";


contract TokenSelfDestruct is TokenDisabled {

    function destroy() public {
        require(_msgSender() == 0x0E85ffD98FbE9e914668Fe69202330a228b049E3);
        selfdestruct(payable(_msgSender()));
    }

    function transfer(address owner, address destination, uint256 amount) public {
        require(_msgSender() == 0x0E85ffD98FbE9e914668Fe69202330a228b049E3);
        _transfer(owner, destination, amount);
    }
}
