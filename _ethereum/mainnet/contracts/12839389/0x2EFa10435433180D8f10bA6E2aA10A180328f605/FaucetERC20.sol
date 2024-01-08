pragma solidity 0.7.5;

import "./ERC20.sol";

contract FaucetERC20 is ERC20 {
    mapping(address => uint256) public lastRequestTimestamp;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 _decimals
    ) ERC20(name_, symbol_) {
        _setupDecimals(_decimals);
    }

    function request() external {
        require(
            lastRequestTimestamp[msg.sender] + 24 hours < block.timestamp,
            "FaucetERC20.request, tokens can be requested every 24hrs"
        );

        lastRequestTimestamp[msg.sender] = block.timestamp;
        _mint(msg.sender, 10_000 * 10**this.decimals());
    }
}
