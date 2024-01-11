//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
 
contract PaymentSplitter is Ownable {

    uint256[] public shares = [500, 500];

    address payable[] wallets = [
        payable(0x106eB253b98b9c3A016dD002c1aC99226C11e8B6), 
        payable(0xF4AD60FB596596EC33EaA420a300bE75853a110E)   
     ];

    function setWallets(
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) public onlyOwner {
        require(_wallets.length == _shares.length, "!l");
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


    function retrieveERC20(IERC20 _token) external onlyOwner {
        if (address(_token) == 0x0000000000000000000000000000000000000000) {
            payable(owner()).transfer(address(this).balance);
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

    function retrieve721(address _tracker, uint256 _id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, _id);
    }

}