// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

contract Splitter is Ownable {
    mapping(address => uint256) public shareMap;

    address[] public addressList;

    constructor(address[] memory _addrList, uint256[] memory _shareList)
        payable
    {
        setSplits(_addrList, _shareList, false);
    }

    fallback() external payable {}

    receive() external payable {}

    function withdraw() public {
        require(address(this).balance > 100, "Not enough to split");
        uint256 bal = address(this).balance;
        for (uint256 i = 0; i < addressList.length; i++) {
            address payable currentAddress = payable(addressList[i]);
            Address.sendValue(
                currentAddress,
                (bal * shareMap[currentAddress]) / 10000
            );
        }
    }

    function setSplits(
        address[] memory _addrList,
        uint256[] memory _shareList,
        bool _andWithdraw
    ) public onlyOwner {
        require(_addrList.length == _shareList.length, "Lengths must match");
        require(_addrList.length > 0, "Provide addresses and shares");

        if (_andWithdraw) {
            withdraw();
        }

        addressList = _addrList;

        for (uint256 i = 0; i < _addrList.length; i++) {
            shareMap[_addrList[i]] = _shareList[i];
        }
    }
}
