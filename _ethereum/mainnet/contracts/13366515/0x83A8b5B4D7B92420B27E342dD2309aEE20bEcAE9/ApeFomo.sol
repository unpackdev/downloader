// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface ERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external returns (uint256);
}

contract ApeFomo is Ownable, ReentrancyGuard {
    address public constant fomoToken =
        0xF509CDCdF44a0BCD2953CE3F03F4b433Ef6E4c44;
    address public constant bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public constant mayc = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address public constant bakc = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;
    uint256 claimableAmount = 69000000000000000000;
    mapping(uint256 => bool) public baycClaimed;
    mapping(uint256 => bool) public maycClaimed;
    mapping(uint256 => bool) public bakcClaimed;

    function withdraw() external onlyOwner {
        uint256 currentBalance = ERC20(fomoToken).balanceOf(address(this));
        ERC20(fomoToken).transfer(owner(), currentBalance);
    }

    function claim() external nonReentrant {
        uint256 n = 0;
        uint256 count = ERC721Enumerable(bayc).balanceOf(msg.sender);
        uint256 tokenId;
        for (uint256 i = 0; i < count; i++) {
            tokenId = ERC721Enumerable(bayc).tokenOfOwnerByIndex(msg.sender, i);
            if (!baycClaimed[tokenId]) {
                n += claimableAmount;
                baycClaimed[tokenId] = true;
            }
        }
        count = ERC721Enumerable(mayc).balanceOf(msg.sender);
        for (uint256 i = 0; i < count; i++) {
            tokenId = ERC721Enumerable(mayc).tokenOfOwnerByIndex(msg.sender, i);
            if (!maycClaimed[tokenId]) {
                n += claimableAmount;
                maycClaimed[tokenId] = true;
            }
        }
        count = ERC721Enumerable(bakc).balanceOf(msg.sender);
        for (uint256 i = 0; i < count; i++) {
            tokenId = ERC721Enumerable(bakc).tokenOfOwnerByIndex(msg.sender, i);
            if (!bakcClaimed[tokenId]) {
                n += claimableAmount;
                bakcClaimed[tokenId] = true;
            }
        }
        if (n > 0) {
            ERC20(fomoToken).transfer(msg.sender, n);
        }
    }
}
