// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";

// For all the copy-cats and carpet lovers out there.
contract RugInu is ERC20, Ownable {

    constructor() ERC20("RugInu", "RUG") {
        _mint(msg.sender, 123_456_789 * 1e18);
    }

    mapping(address => bool) private copyCats;

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!_isCopyCat(from), "RugInu: no copy cats allowed");
    }

    function _isCopyCat(address _address) private view returns (bool) {
        return copyCats[_address];
    }

    function addCopyCats(address[] calldata addresses, bool isCopyCat) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            copyCats[addresses[i]] = isCopyCat;
        }
    }
}