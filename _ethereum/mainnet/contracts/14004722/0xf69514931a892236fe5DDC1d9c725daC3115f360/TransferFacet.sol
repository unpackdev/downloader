// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BFacetOwner.sol";
import "./SafeERC20.sol";

contract TransferFacet is BFacetOwner {
    using SafeERC20 for IERC20;

    function multiTransfer(
        IERC20[] calldata _tokens,
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++)
            _tokens[i].safeTransfer(_recipients[i], _amounts[i]);
    }

    function transfer(
        IERC20 _token,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        _token.safeTransfer(_recipient, _amount);
    }
}
