// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";


contract ElementExchangeKeeper is Ownable {

    bytes4 constant private SUCCESS = this.receiveZeroExFeeCallback.selector;

    mapping(address => bool) public keepers;

    event KeeperAdded(address[] keepers);
    event KeeperRemoved(address[] keepers);

    constructor(address[] memory keepers_) {
        if (keepers_.length > 0) {
            for (uint256 i = 0; i < keepers_.length; i++) {
                keepers[keepers_[i]] = true;
            }
            emit KeeperAdded(keepers_);
        }
    }

    function addKeeper(address[] calldata keepers_) public onlyOwner {
        if (keepers_.length > 0) {
            for (uint256 i = 0; i < keepers_.length; i++) {
                keepers[keepers_[i]] = true;
            }
            emit KeeperAdded(keepers_);
        }
    }

    function removeKeeper(address[] calldata keepers_) public onlyOwner  {
        if (keepers_.length > 0) {
            for (uint256 i = 0; i < keepers_.length; i++) {
                delete keepers[keepers_[i]];
            }
            emit KeeperRemoved(keepers_);
        }   
    }

    function receiveZeroExFeeCallback(
        address /* tokenAddress */,
        uint256 /* amount */,
        bytes calldata /* feeData */
    )
        external
        view
        returns (bytes4 success)
    {
        require(keepers[tx.origin], "not valid keeper");
        return SUCCESS;
    }

    function withdrawETH(address recipient) onlyOwner external {
        (bool success, ) = recipient.call{value: address(this).balance}('');
        require(success, "transfer eth failed");
    }

    function withdrawERC20(
        address asset,
        address recipient
    )
        onlyOwner
        external
    {
        IERC20(asset).transfer(recipient, IERC20(asset).balanceOf(address(this)));
    }

    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    )
        onlyOwner
        external
    {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    )
        onlyOwner
        external
    {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

    fallback() external payable {
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {
    }
}