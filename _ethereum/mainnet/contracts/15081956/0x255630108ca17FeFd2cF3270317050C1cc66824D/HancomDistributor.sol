// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity >=0.8.1;

contract HancomDistributor {

    struct ShareInfo {
        address addressA;
        address addressB;
        uint16 shareRateA;
        uint16 fee;
    }

    function distribute(
        address _seller, uint16 _currencyId, uint256 _price, address _minter, uint16 _royalty,
        ShareInfo memory _shareInfo, address _currencyAddress
    ) external payable {
        if (_currencyId == 1) {
            require(msg.value == _price, "The payment is different from the distribution amount.");
            {
                uint256 valueForA = _price / 10000 * _shareInfo.fee * _shareInfo.shareRateA / 10000;
                if (valueForA > 0) {
                    payable(_shareInfo.addressA).transfer(valueForA);
                }
            }

            {
                uint256 valueForB = _price / 10000 * _shareInfo.fee * (10000 - _shareInfo.shareRateA) / 10000;
                if (valueForB > 0) {
                    payable(_shareInfo.addressB).transfer(valueForB);
                }
            }

            {
                uint256 valueForMinter = _price / 10000 * _royalty;
                if (valueForMinter > 0) {
                    payable(_minter).transfer(valueForMinter);
                }
            }

            {
                uint256 valueForSeller = _price - _price / 10000 * (_shareInfo.fee + _royalty);
                if (valueForSeller > 0) {
                    payable(_seller).transfer(valueForSeller);
                }
            }
        } else {
            require(ERC20(_currencyAddress).balanceOf(msg.sender) >= _price, "The payment is different from the distribution amount.");
            {
                uint256 valueForA = _price / 10000 * _shareInfo.fee * _shareInfo.shareRateA / 10000;
                if (valueForA > 0) {
                    ERC20(_currencyAddress).transferFrom(msg.sender, _shareInfo.addressA, valueForA);
                }
            }

            {
                uint256 valueForB = _price / 10000 * _shareInfo.fee * (10000 - _shareInfo.shareRateA) / 10000;
                if (valueForB > 0) {
                    ERC20(_currencyAddress).transferFrom(msg.sender, _shareInfo.addressB, valueForB);
                }
            }

            {
                uint256 valueForMinter = _price / 10000 * _royalty;
                if (valueForMinter > 0) {
                    ERC20(_currencyAddress).transferFrom(msg.sender, _minter, valueForMinter);
                }
            }

            {
                uint256 valueForSeller = _price - _price / 10000 * (_shareInfo.fee + _royalty);
                if (valueForSeller > 0) {
                    ERC20(_currencyAddress).transferFrom(msg.sender, _seller, valueForSeller);
                }
            }
        }
    }

}
