// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Ownable.sol";

contract splitter is Ownable {
    address payable[] public _wallets;
    uint16[] public _shares;

    constructor(
        address payable[] memory _newWallets,
        uint16[] memory _newShares
    ) {
        UpdateWalletsAndShares(_newWallets, _newShares);
    }

    /**
     * @dev Royalties splitter
     */
    receive() external payable {
        _split(msg.value);
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;

        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 10000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent,) = _wallets[j].call{value: _amount}("");
            require(sent, "PaymentSplitter:Failed to send ether");
        }
    }

    /**
     * @dev Admin: Update wallets and shares
     */
    function UpdateWalletsAndShares(
        address payable[] memory _newWallets,
        uint16[] memory _newShares
    ) public onlyOwner {
        require(_newWallets.length == _newShares.length && _newWallets.length > 0, "PaymentSplitter: Must have at least 1 output wallet");
        uint16 totalShares = 0;
        for (uint8 j = 0; j < _newShares.length; j++) {
            totalShares+= _newShares[j];
        }
        require(totalShares == 10000, "PaymentSplitter: Shares total must be 10000");
        _shares = _newShares;
        _wallets = _newWallets;
    }

}

