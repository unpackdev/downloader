// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";
import "./SafeERC20.sol";

import "./MetaverseBaseNFT.sol";

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMN+ohNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy:`.mMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMy. `/hMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm:   `dMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMm:   -yNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy`   :mMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMNo`   -yMMMMMMMMMMMMMMMMMMMMMMMMMMm:   `sNMNyNMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMms`   -hMMMMMMMMMMMMMMMMMMMMMMNo`   -dMMM/ oMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMd:   `+mMMMMMMMMMMMMMMMMMMMh-    /NMMMy  :MMMMMMMMMMMM
// MMMMMMMMMMMMMMMdosNMMMNy-   .yMMMMMMMMMMMMMMMMm/`   `sMMMMs`  .MMMMMMMMMMMM
// MMMMMMMMMMMMMMd`  -hMMMMNh:   /mMMMMMMMMMMMMNs.    -hMMMMh    `MMMMMMMMMMMM
// MMMMMMMMMMMMMM/    `/mMMMMNy-  .dMMMMMMMMMMd-    :hNMMMMh.    `MMMMMMMMMMMM
// MMMMMMMMMMMMMM`      -NMMMMMNo` `yMMMMMMMMs`   :hMMMMMd+`     `MMMMMMMMMMMM
// MMMMMMMMMMMMMm     `..mMMMMMMMm/ `yMMMMMN/   .yMMMMMm:`  `.   .MMMMMMMMMMMM
// MMMMMMMMMMMMMm    `dNmMMMMMMMMMN: `oMMMN:  `+NMMMMMN:    dm+  .MMMMMMMMMMMM
// MMMMMMMMMMMMMN    oMMMMM+omMMMMMN/  /mN:  .hMMMMMMN/    /MMy  .MMMMMMMMMMMM
// MMMMMMMMMMMMMM    dMMMMM: `+mMMMMMy` .:  +mMMMMMMd-    /NMMy  `MMMMMMMMMMMM
// MMMMMMMMMMMMMM`   NMMMMMy   .yMMMMMh.-:-yMMMMMMNs`   -yMMMM+  `MMMMMMMMMMMM
// MMMMMMMMMMMMMM`   NMMMMMM+   `yMMMMMNNMMMMMMMMm/   `+NMMMMM-  `MMMMMMMMMMMM
// MMMMMMMMMMMMMM`   NMMMMMMM+   `hMMMMMMMMMMMMMy.   `yMMMMMMN   `NMMMMMMMMMMM
// MMMMMMMMMMMMMM.   MMMMMMMMMo`  `/mMMMMMMMMMm+    .dMMMMMMMN`  `NMMMMMMMMMMM
// MMMMMMMMMMMMMM-  -MMMMMMMMMMy`   .hMMMMMMMy.    -dMMMMMMMMM-  `MMMMMMMMMMMM
// MMMMMMMMMMMMMM/  yMMMMMMMMMMMd`   `sMMMMN/    `+NMMMMMMMMMM:  `MMMMMMMMMMMM
// MMMMMMMMMMMMMMs `NMMMMMMMMMMMMd.    sMMm-    omMMMMMMMMMMMM-  .MMMMMMMMMMMM
// MMMMMMMMMMMMMMm`+MMMMMMMMMMMMMMN:    /o-   `sMMMMMMMMMMMMMM-  :MMMMMMMMMMMM
// MMMMMMMMMMMMMMMmMMMMMMMMMMMMMMMMMs`   `   :dMMMMMMMMMMMMMMM/  +MMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd//yds/hMMMMMMMMMMMMMMMMMd-`hMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract Metascapes is MetaverseBaseNFT {

    address immutable SLOIKA_TEAM = 0x720d71822E5A128EA015323e9c2Da40DDABe8e08;
    address immutable BUILDSHIP_TEAM = 0x704C043CeB93bD6cBE570C6A2708c3E1C0310587;
    address immutable AI_TEAM = 0x3F547A321EE5869DeE7B035A89aB24CfF4633181;
    address immutable METASCAPES_TEAM = 0xD7096C2E4281a7429D94ee21B53E7F0011D59FA3;

    constructor() MetaverseBaseNFT(
        0.33 ether,
        3333, // total supply
        33, // reserved supply
        1, // max mint per transaction
        750, // royalty fee
        "ipfs://QmZaubUmk5Qm3Veb2EzoYS7ZEL9B995WRPCmUiG9RqSpsE/",
        "Metascapes", "MTSCPS"
    ) {
        setRoyaltyReceiver(METASCAPES_TEAM);
    }

    function withdraw() public override onlyOwner {
        uint256 balance = address(this).balance;

        // Sloika multi-sig
        // 0x720d71822E5A128EA015323e9c2Da40DDABe8e08
        // 3.75%
        // Buildship multi-sig
        // 0x704C043CeB93bD6cBE570C6A2708c3E1C0310587
        // 3.75%
        // AI team
        // 0x3F547A321EE5869DeE7B035A89aB24CfF4633181
        // 5%
        // Metascape team
        // ​​0xD7096C2E4281a7429D94ee21B53E7F0011D59FA3
        // 87.5%

        Address.sendValue(payable(METASCAPES_TEAM), balance * 8750 / 10000);

        Address.sendValue(payable(SLOIKA_TEAM), balance * 375 / 10000);
        Address.sendValue(payable(BUILDSHIP_TEAM), balance * 375 / 10000);
        Address.sendValue(payable(AI_TEAM), balance * 500 / 10000);

    }

    function withdrawToken(IERC20 token) public override onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        SafeERC20.safeTransfer(token, msg.sender, balance);
    }

}
