// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

contract TokenManager is ERC721Holder, ReentrancyGuard {

    event ReceivedEther(address indexed sender, uint256 amount);

    receive() external payable {
    emit ReceivedEther(msg.sender, msg.value);    
    }

    function _transferETH(uint256 amount, address payable to) internal  nonReentrant {
        Address.sendValue(to, amount);
    }

    function _transferERC721(address erc721ContractAddr, uint256 tokenId, address transferTo) internal {
        IERC721(erc721ContractAddr).safeTransferFrom(address(this), transferTo, tokenId);
    }


    function _transferERC20(address erc20ContractAddr, uint256 amount, address transferTo) internal  nonReentrant {
        SafeERC20.safeTransfer(IERC20(erc20ContractAddr), transferTo, amount);
    }

    function _approveERC20(address erc20ContractAddr, address spender, uint256 amount) internal  nonReentrant {
        SafeERC20.safeApprove(IERC20(erc20ContractAddr), spender, amount);
    }
}
