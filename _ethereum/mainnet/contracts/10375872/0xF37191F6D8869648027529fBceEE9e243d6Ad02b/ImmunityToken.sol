pragma solidity ^0.6.10;

import "./ERC777.sol";
import "./Helpers.sol";

contract ImmunityToken is ERC777, OnlyDeployer, OnlyOnce {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) public ERC777("ImmunityToken", "IMTY", new address[](0)) {
    }

    function mintTokens (address mainHolder) onlyDeployer onlyOnce("mintTokens") public {
        _mint(mainHolder, getTokenAmount(7738550000), "", "");
        _mint(0xA8Fa50A90a7b3774d66455DF7903C562A30D9264, getTokenAmount(1000000), "", "");
        _mint(0x570d3983423AB72f9cb53Ec4C4E373dF3554cB23, getTokenAmount(9500000), "", "");
        _mint(0xdEC98f001A25E9f970C5552D1FCd2bf3e29DbA26, getTokenAmount(2500000), "", "");
        _mint(0xd715e4a4cD1AA422f0b46B24F8b1De7b73c3E151, getTokenAmount(1000000), "", "");
        _mint(0x0EEaCD4982fe1FF062d640094b929507Da161657, getTokenAmount(2500000), "", "");
        _mint(0x846b6eE79F0Bd29cd01DF75145FD5e567Ef9fEB3, getTokenAmount(50000), "", "");
        _mint(0xBDd9C620F3F0fd9e5df0C3B455a11c580ae43e9A, getTokenAmount(600000), "", "");
        _mint(0xdB3e2BE20a1Ba192D9afCDcd5d9AEEcd0B6cA014, getTokenAmount(1000000), "", "");
        _mint(0xdB3e2BE20a1Ba192D9afCDcd5d9AEEcd0B6cA014, getTokenAmount(42000000), "", "");
        _mint(0x570d3983423AB72f9cb53Ec4C4E373dF3554cB23, getTokenAmount(600000), "", "");
        _mint(0xDea249d04462Cb58cbaf727A145B97935c13127E, getTokenAmount(2000000),"", "");
        _mint(0x656571D66E9B39516CAF839Cde812C65269b170D, getTokenAmount(500000), "", "");
    }

    function getTokenAmount (uint amount) private returns (uint) {
        return amount * (10 ** 18);
    }
}