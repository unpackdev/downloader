// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Votes.sol";
import "./SafeCast.sol";

import "./IFancyStakingPool.sol";
import "./IMintableBurnableERC20.sol";

import "./TokenSaver.sol";

abstract contract BaseEscrowPool is ERC20Votes, TokenSaver {
    using SafeERC20 for IMintableBurnableERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    constructor(string memory _name, string memory _symbol) ERC20Permit(_name) ERC20(_name, _symbol) {}

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        revert("NON_TRANSFERABLE");
    }
}
