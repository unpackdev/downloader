// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "./ERC20.sol";

contract MonkDropDistributor {
    address public constant MONK_ERC20_ADDRESS = 0xF8640B0b79C236B0C14f67344B4D203FfcedC712;

    function sendMultiple(address[] memory _redemptions, uint256[] memory _values) public returns (bool) {
        // make sure you manually approve amt from the token contract directly first
        require(_redemptions.length == _values.length);

        uint256 length = _redemptions.length;
        for (uint i = 0; i < length; i++) {
            ERC20(MONK_ERC20_ADDRESS).transferFrom(msg.sender, _redemptions[i], _values[i]);
        }

        return true;
    }
}