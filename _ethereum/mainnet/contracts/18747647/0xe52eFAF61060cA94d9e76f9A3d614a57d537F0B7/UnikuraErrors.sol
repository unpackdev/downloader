// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface UnikuraErrors {
    error ZeroAddress();
    error ZeroAmount();
    error EmptyString();
    error CannotRenounceOwnership();
    error NotMinter(address account);
    error NotBurner(address account);
    error NotAdmin(address account);
    error WrongPercentage(uint256 percent);
    error WrongAmount(uint256 amount);
    error TokenMinted(uint256 tokenId);
    error TokenNotMinted(uint256 tokenId);
    error NoOrder(uint256 tokenId, address account);
    error OrderPlaced(uint256 tokenId, address account);
}
