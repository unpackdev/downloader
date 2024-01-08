pragma solidity ^0.5.13;

import "./StakeableToken.sol";
import "./Roles.sol";

contract FBTC is StakeableToken {
    using Roles for Roles.Role;
    Roles.Role private _minters;

     constructor()
        public
    {
         globals.shareRate = uint40(1 * SHARE_RATE_SCALE);
        _minters.add(ORIGIN_ADDR);

        _mint(FAUCET_ADDR, FAUCET_MINT);
        _mint(LLC_ADDR, LLC_MINT);
        _mint(XP_ADDR, XP_MINT);
        _mint(BAC_ADDR, BAY_MINT);
    }

    function mint(address to, uint256 amount) public {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");

        _mint(to, amount);
    }
}
