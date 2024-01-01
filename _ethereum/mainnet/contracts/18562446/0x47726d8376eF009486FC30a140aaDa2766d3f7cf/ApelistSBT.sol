// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./Base.sol";
import "./ERC721AUpgradeable.sol";
import "./IPass.sol";

contract ApelistSBT is Initializable, Base {
    IPass public pass;

    function initialize(
        IPass _pass,
        Args memory args
    ) public initializer {
        pass = _pass;
        __Base_init(args);
    }

    function mint(uint256 value) public {
        pass.burn(msg.sender, 1, value);
        _callMint(msg.sender, value);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        revert ("Not supported");
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override(ERC721AUpgradeable)
    {
        require(from == address(0), "Token not transferable");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}