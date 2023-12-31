// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ClonesUpgradeable.sol";
import "./IToken.sol";

struct TokenAntiBot {
    uint256 deadBlocks;
    uint256 launchedAt;
    mapping(address => uint256) cooldown;
    address _dexPair;
    address _dexRouter;
}

contract KARMAAntiBot is  Initializable, OwnableUpgradeable {
    address private tokenOwner;
    mapping(address => TokenAntiBot) public tokens;
    uint256[50] private __gap;

    function initialize() external initializer {
        super.__Ownable_init();
    }

    function onPreTransferCheck(address from, address to, uint256 amount) external {
        address tokenAddress = msg.sender;
        IToken token = IToken(tokenAddress);

        if (from == tokenOwner || to == tokenOwner || token.excludedFromFees(from) || token.excludedFromFees(to)) {
            return;
        }
        require(tokens[tokenAddress].deadBlocks + tokens[tokenAddress].launchedAt < block.number, "FAIL_BC");
        require(tokens[tokenAddress].cooldown[tx.origin] < block.number, "Transfer delay enabled. Try again later.");
        tokens[tokenAddress].cooldown[tx.origin] = block.number;
        // console.log("to", to);
        // console.log("tx.origin", tx.origin);
        // console.log("cooldown origin", tokens[tokenAddress].cooldown[tx.origin]);
    }

    function setTokenOwner(address _tokenOwner) external {
        tokenOwner = _tokenOwner;
    }

    function launch(address pair, address router) external {
        require(tokenOwner == tx.origin, "FAIL_OR");

        address tokenAddress = msg.sender;
        tokens[tokenAddress].launchedAt = block.number;
        tokens[tokenAddress].deadBlocks = 2 + (block.number % 2);
        tokens[tokenAddress]._dexPair = pair;
        tokens[tokenAddress]._dexRouter = router;
    }
}
