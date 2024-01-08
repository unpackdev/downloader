// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./ERC777.sol";
import "./Ownable.sol";

contract BeagleCoin is ERC777, Ownable {
    /* Public variables of the token */
    string public version; //Just an arbitrary versioning scheme.
    address private _owner;

    constructor()
        ERC777("Beagle Inu", "BEAGLE", new address[](0))
        Ownable()
    {
        _owner = tx.origin; //set the owner of the contract
        version = "2.0";

        uint256 totalSupply = 10**10 * 10**uint256(decimals()); //10 billion tokens with 8 decimal places
        mint(msg.sender, totalSupply);
    }

    /**
     * @dev [OnlyOwner - can call this]
     * Creates new token and sends them to account
     * @param account The address to send the minted tokens to
     * @param amount Amounts of tokens to generate
     */
    function mint(address account, uint256 amount) public onlyOwner {
        super._mint(account, amount, "", "");
    }
}
