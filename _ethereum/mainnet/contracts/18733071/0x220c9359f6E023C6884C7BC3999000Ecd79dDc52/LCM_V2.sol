// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LCM.sol";
import "./IERC721AQueryableUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract LCM_V2 is LCM {
    IERC721AQueryableUpgradeable public dfakeys;
    mapping (uint256 => bool) public usedIds;

    function walletMint(
        uint256[] calldata tokenIds
    ) external payable {
        require(stage == 2, "Current stage is not enabled");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(dfakeys.ownerOf(tokenIds[i]) == msg.sender, "Not owner of token");
            require(!usedIds[tokenIds[i]], "Token already used");
            usedIds[tokenIds[i]] = true;
        }
        uint256 amount = tokenIds.length;
        _callMint(msg.sender, amount);
        _handlePayment(amount * price(1));
    }

    function setKeys(address dfakeys_) external onlyAdmin {
        dfakeys = IERC721AQueryableUpgradeable(dfakeys_);
    }

function withdraw(
) external onlyAdmin {
    AddressUpgradeable.sendValue(
        payable (0xE953a437eDE5955F5F38e8782Fe173C45fB272b0),
        address(this).balance
    );
}
}
