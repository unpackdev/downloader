// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract PaycerToken is ERC20Capped, Ownable {

    /**
     * @dev Sets the values for {_initialSupply} and {_totalSupply}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 _initialSupply, uint256 _totalSupply) public ERC20('PaycerToken', 'PCR') ERC20Capped(_totalSupply) {
        ERC20._mint(msg.sender, _initialSupply);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }


    function getChainId() external view returns (uint256) {
        uint256 chainId;
        
        assembly {
            chainId := chainid()
        }

        return chainId;
    }
}