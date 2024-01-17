// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC165.sol";
import "./Ownable.sol";

contract TestToken is ERC20, Ownable, ERC165 {
    constructor() ERC20("Wrapped Dogecoin", "WDOGE") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public override pure returns (uint8) {
        return 8;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId || super.supportsInterface(interfaceId);
    }
}