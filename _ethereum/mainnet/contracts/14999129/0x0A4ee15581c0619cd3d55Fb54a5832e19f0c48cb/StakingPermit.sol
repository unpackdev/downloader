// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "./Staking.sol";
import "./IStakingPermit.sol";

contract StakingPermit is IStakingPermit, Staking {
    constructor(
        string memory name,
        string memory symbol,
        address underlyingToken
    ) Staking(name, symbol, underlyingToken) {}

    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external virtual returns (uint256) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        IERC20Permit(address(token)).permit(_msgSender(), address(this), type(uint256).max, deadline, v, r, s);
        return deposit(amount);
    }
}
