// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract Withdraw is Ownable {
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function withdraw(address beneficiary) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}('');
        if (!sent) revert FailedToWithdrawEth(_msgSender(), beneficiary, amount);
    }

    function withdrawToken(address beneficiary, address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }

    function withdrawERC721(address erc721) external onlyOwner {
        require(IERC721(erc721).balanceOf(address(this)) > 0, 'Withdraw: contract does not own any ERC721');
        IERC721(erc721).transferFrom(address(this), _msgSender(), IERC721Enumerable(erc721).tokenOfOwnerByIndex(address(this), 0));
    }
}
