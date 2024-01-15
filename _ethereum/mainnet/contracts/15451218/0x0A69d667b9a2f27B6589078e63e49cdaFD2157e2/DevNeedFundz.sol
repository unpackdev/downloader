// SPDX-License-Identifier: Unlicense
// Creator: The Dank One

pragma solidity ^0.8.9;

import "./IERC20.sol";

contract DevNeedFundz {
    mapping(address => bool) public isDevBased;
    address[] public basedDevs;
    uint256[] public basisPoints;

    constructor (
        address[] memory _basedDevs,
        uint256[] memory _basisPoints
    ) {
        require(_basedDevs.length == _basisPoints.length, "bruh");
        basedDevs = _basedDevs;
        basisPoints = _basisPoints;
        for (uint256 whichDev = 0; whichDev < _basedDevs.length; whichDev++) {
            isDevBased[_basedDevs[whichDev]] = true;
        }
    }

    receive() external payable {
        uint256 totalDevPay = address(this).balance;
        for (uint256 whichDev = 0; whichDev < basedDevs.length; whichDev++) {
            (bool success, ) = payable(basedDevs[whichDev]).call{value: (totalDevPay/10000)*basisPoints[whichDev]}("");
            require(success, "wtfbro");
        }
    }

    function withdrawTokens(address tokenAddress) external {
        require(isDevBased[msg.sender], "must be based");
        for (uint256 whichDev = 0; whichDev < basedDevs.length; whichDev++) {
            IERC20(tokenAddress).transfer(
                basedDevs[whichDev],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*(basisPoints[whichDev])
            );
        }
    }
}

