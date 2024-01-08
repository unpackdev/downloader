// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";

contract RevSharable is Ownable {
    using SafeMath for uint256;

    address public wallet0 = 0x62760FdAE6c7F42f618e71321FF8f58271181069; // Set this charity wallet

    address[] private wallets = [
        0x91AC9B0DFe3234473c4492127BB40e072958Dbdd, // 1
        0x8C8F766dEF561a4eAe7A629921d8b34af06BA850, // 2
        0xa56C03c9F73421e19759ddB5973f0D0340834E3b, // 3
        0xdFb57B7B2f7cf98536fA9bbC74814d2cB9930678, // 4
        0x617885C90888a82bd57b037a23144b1Ce88EC0ba // 5
    ];

    function setCharityWallet(address _to) public onlyOwner {
        wallet0 = _to;
    }

    function distribute() public onlyOwner {

        uint256 balance = address(this).balance;

        require(balance > 0, 'Balance is <= 0');

        uint256 toCharity = balance.div(2);

        // Transfer to the Charity Wallet
        payable(wallet0).transfer(toCharity);

        // Split the rest into 5
        uint256 share = toCharity.div(5);

        for(uint i = 0; i < 5; i++){
            payable(wallets[i]).transfer(share);
        }

    }
}