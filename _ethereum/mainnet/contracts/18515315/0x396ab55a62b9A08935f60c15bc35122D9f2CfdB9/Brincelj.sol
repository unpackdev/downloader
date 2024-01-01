/**
    $KEKEᑕ Iᔕ IᗰᑭOᔕTEᖇ. ᕼE TOOK ᗰY ᑭᖇETTY ᖴᗩᑕE ᗩᑎᗪ Iᔕ ᖴOᑕKIᑎG ᗩᖇOᑌᑎᗪ ᗯITᕼ ᗰY ᖴᒪᑌTE 

    GIᗷ ᗰE ᗷᗩᑕK ᗰY ᖴᒪᑌTE!!!! 

    🔥ᖴᒪᑌTE ᗷᗩTTᒪE ᗰOᖴO Iᔕ Oᑎ!!! 🔥

    Page: https://brincelj.wtf/
    TW: https://twitter.com/brinceljeth
    TG: https://t.me/brinceljwtfeth
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";

contract Brincelj is ERC20 {

    uint256 private constant _maxSupply = 1_200_000_000 * 1 ether; // 1.2 billion

    constructor() ERC20("The Balkan Zwerg", "BRINCELJ") {
        _mint(msg.sender, _maxSupply);
    }
}