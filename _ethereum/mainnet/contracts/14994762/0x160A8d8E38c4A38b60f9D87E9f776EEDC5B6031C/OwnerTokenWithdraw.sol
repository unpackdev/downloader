// SPDX-License-Identifier: MIT
// Creator: tyler@radiocaca.com

pragma solidity ^0.8.8;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

abstract contract OwnerTokenWithdraw is Ownable {
    using SafeERC20 for IERC20;

    function withdraw(address payable _receiver, uint256 _amount) external onlyOwner {
        Address.sendValue(_receiver, _amount);
    }

    function withdrawERC20(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    function withdrawERC721(
        address _tokenAddress,
        address _receiver,
        uint256[] memory _tokenIds
    ) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ++i) {
            IERC721(_tokenAddress).transferFrom(address(this), _receiver, _tokenIds[i]);
        }
    }
}
