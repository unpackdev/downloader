// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./OFTCore.sol";
import "./SafeERC20.sol";

contract ProxyOFT is OFTCore {
    using SafeERC20 for IERC20;

    IERC20 internal innerToken;

    /// @inheritdoc IOFTCore
    function circulatingSupply() public view virtual override returns (uint256) {
        unchecked {
            return innerToken.totalSupply() - innerToken.balanceOf(address(this));
        }
    }

    /// @inheritdoc IOFTCore
    function token() public view virtual override returns (address) {
        return address(innerToken);
    }

    /**
     * @dev transfer tokens from sender to this contract
     * _from - the owner of tokens
     * _amount - the quantity of tokens in wei to transfer
     */
    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        require(_from == _msgSender(), "ProxyOFT: owner is not send caller");
        uint256 before = innerToken.balanceOf(address(this));

        innerToken.safeTransferFrom(_msgSender(), address(this), _amount);
        return innerToken.balanceOf(address(this)) - before;
    }

    /**
     * @dev transfer tokens from this contract to provided address
     * _toAddress - address the tokens will be transferred to
     * _amount - the quantity of tokens in wei to transfer
     */
    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override returns (uint256) {
        uint256 before = innerToken.balanceOf(_toAddress);
        innerToken.safeTransfer(_toAddress, _amount);
        return innerToken.balanceOf(_toAddress) - before;
    }
}
