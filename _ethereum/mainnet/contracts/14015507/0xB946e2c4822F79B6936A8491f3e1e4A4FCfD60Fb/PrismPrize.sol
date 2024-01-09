// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ECDSA.sol";

// You stumble across a cave and see a bright flash of light.
// Upon inspection, there is a medium size chest with a display.
// Beneeth the display are a list of engraved numbers:
//  "3241"

// Whoever left this chest also left a sheet of paper which read:
//  - Congratulations for finding this. If you have found this, you know why you are here.
//  - This chest requires a passcode. To generate a passcode, you need a password.
//  - If you have generated the correct passcode, enter it into the interface at: "https://ethchecker.com/chest/[wallet]/[password]"
//  - Good luck.

contract HiddenChest {
    using ECDSA for bytes32;

    bytes32 public password =
        0x97cb0595d76852d894b77137ffcd02b876c8d81dd8e55e1e0bdbc16e9655e454;
    address public signer = 0x95223bA4Dd076588aC34546367839D06720D682b;

    function claimPrize(bytes memory _passcode) external {
        require(
            keccak256(abi.encodePacked(msg.sender, password))
                .toEthSignedMessageHash()
                .recover(_passcode) == signer,
            "Invalid signature"
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    function deposit() external payable {}
}

// 0x40707231736d5f646576
