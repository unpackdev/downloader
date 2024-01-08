//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

//import "./SafeMath.sol";
import "./Ownable.sol";

// import "./console.sol";

contract PaymentSplitter is Ownable {
    //  using SafeMath for uint256;

    address payable public EC_wallet;
    address payable public AOKI_wallet;
    address payable public METAZOO_wallet;
    uint256 public creator_fee_percentage;

    uint256[] public shares = [70, 180, 750];

    address payable[] wallets = [
        payable(0xA3cB071C94b825471E230ff42ca10094dEd8f7bB), // EC
        payable(0xA807a452e20a766Ea36019bF5bE5c5f4cbDE7563), // AOKI
        payable(0x77b94A55684C95D59A8F56a234B6e555fC79997c) // MetaZoo
    ];

    function setWallets(
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) public onlyOwner {
        require(_wallets.length == _shares.length, "not same lenght");
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
            //  console.log(_amount);

            (sent, ) = wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            //  console.log(sent);
            require(sent, "Failed to send Ether");
        }
    }

    receive() external payable {
        _split(msg.value);
    }
}
