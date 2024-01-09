// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity >=0.8.1;

contract HancomDistributor {

    function distribute(
        address _seller, uint16 _currencyId, uint256 _price, address _minter, uint16 _royalty, uint16 _fee,
        address _addressA, address _addressB, uint16 _shareRateA, address _currencyAddress
    ) external payable {
        if (_currencyId == 1) {
            require(msg.value == _price, "The payment is different from the distribution amount.");
            {
                uint256 valueForA = _price / 10000 * _fee * _shareRateA / 10000;
                payable(_addressA).transfer(valueForA);
            }

            {
                uint256 valueForB = _price / 10000 * _fee * (10000 - _shareRateA) / 10000;
                payable(_addressB).transfer(valueForB);
            }

            {
                uint256 valueForMinter = _price / 10000 * _royalty;
                payable(_minter).transfer(valueForMinter);
            }

            {
                uint256 valueForSeller = _price - _price / 10000 * (_fee + _royalty);
                payable(_seller).transfer(valueForSeller);
            }
        } else {
            require(ERC20(_currencyAddress).balanceOf(msg.sender) >= _price, "The payment is different from the distribution amount.");
            {
                uint256 valueForA = _price / 10000 * _fee * _shareRateA / 10000;
                ERC20(_currencyAddress).transferFrom(msg.sender, _addressA, valueForA);
            }

            {
                uint256 valueForB = _price / 10000 * _fee * (10000 - _shareRateA) / 10000;
                ERC20(_currencyAddress).transferFrom(msg.sender, _addressB, valueForB);
            }

            {
                uint256 valueForMinter = _price / 10000 * _royalty;
                ERC20(_currencyAddress).transferFrom(msg.sender, _minter, valueForMinter);
            }

            {
                uint256 valueForSeller = _price - _price / 10000 * (_fee + _royalty);
                ERC20(_currencyAddress).transferFrom(msg.sender, _seller, valueForSeller);
            }
        }

    }

}
