pragma solidity 0.6.12;

interface IWETH {
    function balanceOf(address account) external view returns (uint);

    function deposit() external payable;

    function withdraw(uint) external;

    function approve(address guy, uint wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) external returns (bool);
}
