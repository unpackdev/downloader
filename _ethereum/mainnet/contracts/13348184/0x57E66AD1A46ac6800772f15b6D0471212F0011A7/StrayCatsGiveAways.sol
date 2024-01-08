// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./IStrayCat.sol";

contract StrayCatsGiveAways is Ownable {
    IStrayCat public strayCat =
        IStrayCat(0x25BAABaf41cE56565F448C6f6E16D44399812cAD);

    function mintGiveAwayCatsWithAddresses(address[] memory supporters)
        external
        onlyOwner
    {
        // Reserved for people who helped this project and giveaways
        for (uint256 index; index < supporters.length; index++) {
            strayCat.mint(supporters[index]);
        }
    }

    function mintGiveAwayCats(uint256 numberOfStrayCats) external onlyOwner {
        for (uint256 index; index < numberOfStrayCats; index++) {
            strayCat.mint(owner());
        }
    }
}
