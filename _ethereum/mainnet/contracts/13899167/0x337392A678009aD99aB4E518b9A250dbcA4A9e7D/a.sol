// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

interface MonfterNFT {
    function safeMint(address) external;
}

contract SOSTokenMinter is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public sosToken;
    MonfterNFT public monfterNft;

    uint256 public mintPrice = 35000000e18;
    uint256 public MAX_MINT = 721;

    uint256 public sosMint;
    address public dead = address(1);

    event Mint(address indexed account);

    constructor(IERC20 _sosToken, MonfterNFT _monfterNft) {
        sosToken = _sosToken;
        monfterNft = _monfterNft;
    }

    function mint(uint256 amount) public payable nonReentrant {
        require(sosMint.add(1) <= MAX_MINT, "mint end");
        require(amount >= 1 && amount <= 10, "invalid amount");

        sosToken.transfer(dead, mintPrice.mul(amount));

        for (uint256 i = 0; i < amount; i++) {
            monfterNft.safeMint(msg.sender);
        }

        sosMint = sosMint.add(1);
        emit Mint(msg.sender);
    }
}
