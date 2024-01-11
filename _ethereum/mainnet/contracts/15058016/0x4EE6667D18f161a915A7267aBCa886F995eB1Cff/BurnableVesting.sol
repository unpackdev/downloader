// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Vesting.sol";
import "./Position.sol";

contract BurnableVesting is Vesting {
    function burn(uint256 _tokenId) external virtual onlyOwner {
        Position.Data storage position = positions[_tokenId];
        underlyingSupplied -= position.balance;
        delete positions[_tokenId];

        _burn(_tokenId);
    }
}
