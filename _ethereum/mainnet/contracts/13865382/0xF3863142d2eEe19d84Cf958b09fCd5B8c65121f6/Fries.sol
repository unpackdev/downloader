// SPDX-License-Identifier: MIT
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Fries is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Fries", "FRY") {
        _mint(msg.sender, 100000000 * 10**18);
    }

    function mint(uint256 _amount, address _to) external onlyOwner {
        _mint(_to, _amount);
    }
}