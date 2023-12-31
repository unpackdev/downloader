//SPDX-License-Identifier: UNLICENSED

interface IWeth {
    function balanceOf(address addr) external returns(uint256);
    function deposit() external payable;
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
}