// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Delegable.sol";

contract CoinDogsERC20 is ERC20, Delegable {
    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("TokenDog", "DOG") {
        _mint(address(this), 1_000_000_000 * 10 ** decimals() );
    }

    function buyDogCoins(address to, uint256 amount) external onlyOwnerOrApproved {
        _transfer(address(this), to, amount);
    }

    function decimals() public pure override returns(uint8){
        return 10;
    }
    function transferApproved(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        require(isApproved(_msgSender()), "ERC20: transfer amount exceeds allowance");
        return true;
    }
}
