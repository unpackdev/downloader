//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Button is ERC20 {
    mapping(address => uint256) public lastClickedTimestamp;

    event Clicked(address indexed who, uint256 timestamp);

    error ClickedTooSoonPleaseWait();
    error ClicksCanOnlyBeEarnedByClicking();

    constructor() ERC20('Clicks', 'CLC') {}

    function click() external {
        if (
            lastClickedTimestamp[msg.sender] != 0 &&
            lastClickedTimestamp[msg.sender] + 6 hours > block.timestamp
        ) revert ClickedTooSoonPleaseWait();

        lastClickedTimestamp[msg.sender] = block.timestamp;

        _mint(msg.sender, 1);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (from != address(0)) revert ClicksCanOnlyBeEarnedByClicking();
    }
}
