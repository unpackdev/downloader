// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC20.sol";

/// DeArbitrage Token: DARB
contract DeArbitrageToken is ERC20, Ownable {
    using SafeMath for uint256;

    // 1B cap
    uint256 public cap = 1_000_000_000 * 10**18;

    constructor() ERC20('DeArbitrage Token', 'DARB') {}

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply().add(amount) <= cap, 'CE');
        _mint(to, amount);
    }
}
