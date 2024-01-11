//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game OG Token
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract LL420OGToken is ERC20Capped, Ownable {
    bool public transferAllowed = false;
    uint256 public constant OG_SUPPLY = 420 * 10**18;
    address public ogStakingContract;

    /* ==================== EVENTS ==================== */
    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);
    event AllowTransfer(bool allowed);

    /* ==================== MODIFIERS ==================== */
    modifier onlyOGStaking() {
        require(ogStakingContract != address(0), "OG staking address is not set yet");
        require(_msgSender() == ogStakingContract, "Not allowed caller");
        _;
    }

    /* ==================== METHODS ==================== */

    constructor() ERC20Capped(OG_SUPPLY) ERC20("420OG", "420OG") {
        setTransferAllowed(false);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (transferAllowed || from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        revert("Transfer not allowed");
    }

    function mint(address _account, uint256 _amount) external onlyOGStaking {
        require(_amount > 0, "Wrong amount");
        _mint(_account, _amount);

        emit Mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOGStaking {
        require(_amount > 0, "Wrong amount");
        _burn(_account, _amount);

        emit Burn(_account, _amount);
    }

    /* ==================== OWNER METHODS ==================== */
    function setOGStakingContract(address _address) external onlyOwner {
        require(_address != address(0), "Zero address");
        ogStakingContract = _address;
    }

    function setTransferAllowed(bool _allowed) public onlyOwner {
        transferAllowed = _allowed;

        emit AllowTransfer(_allowed);
    }
}
