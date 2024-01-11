// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721Enumerable.sol";
import "./Create2.sol";


IERC20 constant Dough = IERC20(0x10971797FcB9925d01bA067e51A6F8333Ca000B1);
OCM constant Monsters = OCM(0xaA5D0f2E6d008117B16674B0f00B6FCa46e3EFC4);


interface OCM is IERC721Enumerable {
    function currentMintingCost() external returns (uint);
    function mintMonster() external;
}


contract OnChainMonsterMintManager {
    address immutable minterAddress;
    uint256 public oneShotMintCount;

    constructor() {
        // Deploy from the constructor to set up approvals.
        minterAddress = Create2.deploy(0, 0, type(FlashMinter).creationCode);
    }

    function mintMonsters(uint256 count) external {
        // It's perfectly safe, I assure you.
        unchecked {
            uint256 id = Monsters.totalSupply(); // Next ID to be minted.
            uint256 next = id + count; // End of mint range, exclusive.

            // Calculate minting cost.
            uint256 totalCost = (id / 2000) * count;

            // Account for possible rollover into the next price tier.
            uint256 nextTierPosition = next % 2000;
            if (nextTierPosition < id % 2000) totalCost += nextTierPosition;

            // Add dough decimals.
            totalCost *= 1e18;

            // Transfer the necessary dough to the minter address.
            Dough.transferFrom(msg.sender, minterAddress, totalCost);

            // Store the mint count where the flash minter can access it.
            oneShotMintCount = count;
            // And mint.
            Create2.deploy(0, 0, type(FlashMinter).creationCode);

            // Transfer the minted monsters to the caller.
            for (; id < next; ++id)
                Monsters.transferFrom(minterAddress, msg.sender, id);
        }
    }
}


contract FlashMinter {
    // Mints monsters then self destructs.
    //
    // Assumes there is already dough sent to this contract's address.
    constructor() {
        address creator = msg.sender;

        // Set up approvals if caller is still constructing.
        if (creator.code.length == 0) {
            // Allow minting with dough.
            Dough.approve(address(Monsters), type(uint256).max);
            // Allow Monster transfers by creator.
            Monsters.setApprovalForAll(creator, true);

            selfdestruct(payable(creator));
            return;
        }

        uint count = OnChainMonsterMintManager(creator).oneShotMintCount();
        unchecked {
            for (; count > 0; --count) Monsters.mintMonster();
        }

        // The manager will take care of things from here.
        selfdestruct(payable(creator));
    }
}
