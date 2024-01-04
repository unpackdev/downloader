// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;

    uint256 public start = 1614556800; // 3/1/2021 12 AM UTC
    uint256 public end = 1646092800; // 3/1/2022 12 AM UTC

    IERC20 public constant ruler = IERC20(0x2aECCB42482cc64E087b6D2e5Da39f5A7A7001f8);
    mapping(address => uint256) private _vested;
    mapping(address => uint256) private _total;

    constructor() {
        _total[0x094AD38fB69f27F6Eb0c515ad4a5BD4b9F9B2996] = 54352 ether;
        _total[0x406a0c87A6bb25748252cb112a7a837e21aAcD98] = 38824 ether;
        _total[0x3e677718f8665A40AC0AB044D8c008b55f277c98] = 38824 ether;
        _total[0x82BBd2F08a59f5be1B4e719ff701e4D234c4F8db] = 6000 ether;
        _total[0xF00Bf178E3372C4eF6E15A1676fd770DAD2aDdfB] = 6000 ether;
        _total[0x0907742ce0A894b6a5D70E9df2C8D2FADCAF4039] = 4500 ether;
        _total[0x7c83B51c1feCf0631101DF8E7FF602D181A64e1b] = 1500 ether;
    }

    function vest() external {
        require(_total[msg.sender] > 0, "Vesting: no vesting schedule!");
        require(block.timestamp >= start, "Vesting: !started");
        uint256 toBeReleased = releasableAmount(msg.sender);
        require(toBeReleased > 0, "Vesting: no tokens to release");

        _vested[msg.sender] = _vested[msg.sender] + toBeReleased;
        ruler.safeTransfer(msg.sender, toBeReleased);
    }

    function releasableAmount(address _addr) public view returns (uint256) {
        return _unlockedAmount(_addr) - _vested[_addr];
    }

    function _unlockedAmount(address _addr) private view returns (uint256) {
        if (block.timestamp <= end) {
            uint256 duration = end - start;
            uint256 timePassed = block.timestamp - start;
            return (_total[_addr] * timePassed) / duration;
        } else {
            return _total[_addr];
        }
    }
}
