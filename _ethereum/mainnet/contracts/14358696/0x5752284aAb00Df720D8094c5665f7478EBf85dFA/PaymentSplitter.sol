//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract PaymentSplitter is Ownable {

    uint256[] public shares = [100, 900];

    address payable[] wallets = [
        payable(0x5602607C485b0f3D943D3C13502A33ea24916E44), // EC
        payable(0xDAB723b0E4668D2F7b5fEB270C4F82aF5483ab1d) // GENETICATS
     ];

    function setWallets(
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) public onlyOwner {
        require(_wallets.length == _shares.length, "!length");
        wallets = _wallets;
        shares = _shares;
    }

    function _split(uint256 amount) internal {
        // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = (amount * shares[j]) / 1000;
            if (j == wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent, ) = wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
             require(sent, "Failed to send Ether");
        }
    }

    receive() external payable {
        _split(msg.value);
    }
}
