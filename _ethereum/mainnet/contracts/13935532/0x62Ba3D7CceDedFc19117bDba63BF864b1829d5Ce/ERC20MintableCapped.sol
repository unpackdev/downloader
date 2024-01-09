// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

/**
* WOKE is the token for the WokeDAO ecosystem.
*
* This contract is intended to be owned by a DAO-controlled smart contract,
* taking care of further distribution after a 3-month lock period, starting 
* from the date of genesis mint.
*
* The total cap of WOKE is at 100,000,000 (100 mln).
*
* To reward early supporters and to raise awareness, 10% will be minted shortly 
* after contract deployment and fair-released on decentralised exchanges.
*
* Further distribution rules are subject to the WokeDAO community and their decisions.
*
* Please visit https://wokedao.art for further information and to take part in the community.
*/
contract WokeDAO is ERC20Capped, Ownable {
    
    // timestamp of genesis mint
    uint256 public genesis_mint = 0;

    constructor(uint256 _cap) ERC20("WokeDAO", "WOKE") ERC20Capped(_cap) {}

    /**
    * The mint function will be hand over to a DAO instance as soon as it is available.
    * As additional trust-layer, there will be a 3-month period in which no minting is allowed at all.
    * 
    * This is equivalent to locked tokens.
    *
    * We expect the ownership of this token contract being transferred to the DAO smart contract by then.
    */
    function mint(address _to, uint256 _amount) public onlyOwner {

        if(genesis_mint != 0){

            // no minting allowed for 3 months after the genesis mint, also not for the current owner.
            require(block.timestamp > genesis_mint + 7776000, "mint: no minting allowed yet.");
        }
        else
        {
            genesis_mint = block.timestamp;
        }

        _mint(_to, _amount);
    }
}