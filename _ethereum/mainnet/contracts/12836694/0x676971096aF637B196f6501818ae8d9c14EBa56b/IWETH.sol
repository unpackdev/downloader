pragma solidity 0.7.6;

interface IWETH {
  function withdraw ( uint256 wad ) external;
  function deposit (  ) external payable;
}
