// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./IMint.sol";
import "./LibMint.sol";


contract AirdropsFacet is Base, IMint {

    function airdrop(address[] calldata receivers)
        external
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            if (LibMint.minted(receivers[i])) revert AlreadyMinted();
            LibMint.setMinted(receivers[i]);
            LibMint.mint(receivers[i], s);
        }
    }
}
