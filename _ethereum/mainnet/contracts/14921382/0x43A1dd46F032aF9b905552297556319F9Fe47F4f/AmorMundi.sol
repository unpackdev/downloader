// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract AmorMundi is ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 constant MAX_SUPPLY = 88;

    string _baseTokenURI =
        "ipfs://QmY9sPqfYm19K4kmF2ihouxbmzyGLpegnbVS5Y42KdkqCn/";

    constructor() ERC721A("Amor x Stephan Breuer", "Amorx1") {}

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "too many");
        _mint(to, quantity);
    }

    function setBaseTokenURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner can drain tokens that are sent here by mistake
    function withdraw(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }
}
