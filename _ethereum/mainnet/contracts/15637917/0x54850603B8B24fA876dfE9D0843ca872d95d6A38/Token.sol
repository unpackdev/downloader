// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SupportToken.sol";

contract BIZToken is ERC20, Ownable, SupportToken {
    constructor() ERC20("BizTik", "BIZ") {
        _mint(msg.sender, 200000000 * 10**decimals());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (enableWhiteListBot) {
            if (isContract(from) && !whiteListAddressBot[from]) {
                revert("ERC20: contract from is not whitelist");
            }
            if (isContract(to) && !whiteListAddressBot[to]) {
                revert("ERC20: contract to is not whitelist");
            }
        }
        require(amount > 0, "ERC20: require amount greater than 0");
        require(
            blackListWallet[from] == false,
            "ERC20: address from is blacklist"
        );
        require(blackListWallet[to] == false, "ERC20: address to is blacklist");
        if (isEnable == true && from != address(0)) {
            uint256 amountIn = checkTransfer(from);
            if (balanceOf(from) < amountIn + amount) {
                revert(
                    "ERC20: Some available balance has been unlock gradually"
                );
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
