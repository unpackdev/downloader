// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./Address.sol";

abstract contract Recoverable is ConfirmedOwner {
    using SafeERC20 for IERC20;

    event RecoveredERC721(address token, address recipient);
    event RecoveredERC20(address token, address recipient);
    event RecoveredETH(address recipient);

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _recipient: recipient
     * @param _tokenIds: tokenIds
     * @dev Callable by owner
     */
    function recoverERC721(address _token, address _recipient, uint256[] calldata _tokenIds) external onlyOwner {
         for (uint256 i = 0; i < _tokenIds.length; ) {
            IERC721(_token).transferFrom(address(this), _recipient, _tokenIds[i]);
            unchecked { ++i; }
         }
         emit RecoveredERC721(_token, _recipient);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _recipient: recipient
     * @dev Callable by owner
     */
    function recoverERC20(address _token, address _recipient) public virtual onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Cannot recover zero balance");

        IERC20(_token).safeTransfer(_recipient, balance);
        emit RecoveredERC20(_token, _recipient);
    }

    /**
     * @notice Allows the owner to recover eth sent to the contract by mistake
     * @param _recipient: recipient
     * @dev Callable by owner
     */
    function recoverEth(address payable _recipient) public virtual onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "Cannot recover zero balance");

        Address.sendValue(_recipient, balance);
        emit RecoveredETH(_recipient);
    }
}