// SPDX-License-Identifier: MIT\
pragma solidity 0.7.5;

import "./SafeMath.sol";

import "./IERC20.sol";

contract MvdCirculatingSupply {
    using SafeMath for uint256;

    bool public isInitialized;

    address public MVD;
    address public owner;
    address[] public nonCirculatingMVDAddresses;

    constructor(address _owner) {
        owner = _owner;
    }

    function initialize(address _mvd) external returns (bool) {
        require(msg.sender == owner, "caller is not owner");
        require(isInitialized == false);

        MVD = _mvd;

        isInitialized = true;

        return true;
    }

    function getCirculatingSupply() external view returns (uint256) {
        uint256 _totalSupply = IERC20(MVD).totalSupply();

        uint256 _circulatingSupply = _totalSupply.sub(getNonCirculatingMVD());

        return _circulatingSupply;
    }

    function getNonCirculatingMVD() public view returns (uint256) {
        uint256 _nonCirculatingMVD;

        for (uint256 i = 0; i < nonCirculatingMVDAddresses.length; i = i.add(1)) {
            _nonCirculatingMVD = _nonCirculatingMVD.add(IERC20(MVD).balanceOf(nonCirculatingMVDAddresses[i]));
        }

        return _nonCirculatingMVD;
    }

    function setNonCirculatingMVDAddresses(address[] calldata _nonCirculatingAddresses) external returns (bool) {
        require(msg.sender == owner, "Sender is not owner");
        nonCirculatingMVDAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership(address _owner) external returns (bool) {
        require(msg.sender == owner, "Sender is not owner");

        owner = _owner;

        return true;
    }
}
