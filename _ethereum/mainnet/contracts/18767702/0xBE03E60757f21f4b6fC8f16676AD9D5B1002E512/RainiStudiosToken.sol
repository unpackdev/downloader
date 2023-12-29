// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Ownable2Step.sol";

contract RainiStudiosToken is ERC20, AccessControl, Ownable2Step {

    bytes32 public constant NO_FEE_FROM_ROLE = keccak256("NO_FEE_FROM_ROLE");

    // Transfer fee applies only for transfers to addresses with FEE_TO_ROLE
    bytes32 public constant FEE_TO_ROLE = keccak256("FEE_TO_ROLE");

    uint256 public constant MAX_FEE = 200;
    uint256 public transferFeeBasisPoints;

    address public treasury;

    constructor() ERC20("Raini Studios Token", "RST") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10**18);
    }

    function _transfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20)
    {
        if((hasRole(FEE_TO_ROLE, to) && !hasRole(NO_FEE_FROM_ROLE, from))) {
            uint256 fee = (amount * transferFeeBasisPoints) / 10000;
            super._transfer(from, treasury, fee);
            super._transfer(from, to, amount - fee);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function setTransferFeeBasisPoints(uint256 _transferFeeBasisPoints) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not an admin");
        require(_transferFeeBasisPoints <= MAX_FEE, "Fee > 2%");
        transferFeeBasisPoints = _transferFeeBasisPoints;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
