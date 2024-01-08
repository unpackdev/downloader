//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Mcn2Token is ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("Mcn2 Token", "MCN2") {
        transferOwnership(0xD90AaBe2eA39648F31146B70B8e53C01482c63a1);
    }

    function mint(address _to, uint256 _amount) external onlyOwner() {
        _mint(_to, _amount);
    }

}