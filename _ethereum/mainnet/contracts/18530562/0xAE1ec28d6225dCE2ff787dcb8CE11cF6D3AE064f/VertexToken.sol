// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ISanctionsList.sol";

contract VertexToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    address public sanctions;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _sanctions) public initializer {
        __ERC20_init("Vertex", "VRTX");
        __Ownable_init();
        sanctions = _sanctions;

        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(
            !ISanctionsList(sanctions).isSanctioned(from),
            "sender is sanctioned."
        );
        require(
            !ISanctionsList(sanctions).isSanctioned(to),
            "recipient is sanctioned."
        );
    }
}
