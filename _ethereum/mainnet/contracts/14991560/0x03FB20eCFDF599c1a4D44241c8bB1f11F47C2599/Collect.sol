// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface Comp {
  function claimStrike(address, address [] calldata) external;
}

interface ERC20 {
  function transferFrom(address src, address dst, uint256 amount) external returns (bool);
  function transfer(address dst, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function approve(address tgt, uint256 amount) external returns (bool);
}

contract Collect {
  fallback() external {
    Comp c = Comp(0xe2e17b2CBbf48211FA7eB8A875360e5e39bA2602);
    ERC20 strk = ERC20(0x74232704659ef37c08995e386A2E26cc27a8d7B1);
    address [] memory addList;
    addList = new address[](3);
    addList[0] = 0xbEe9Cf658702527b0AcB2719c1FAA29EdC006a92;
    addList[1] = 0x69702cfd7DAd8bCcAA24D6B440159404AAA140F5;
    addList[2] = 0x9d1C2A187cf908aEd8CFAe2353Ef72F06223d54D;
    c.claimStrike(0xee2826453A4Fd5AfeB7ceffeEF3fFA2320081268, addList);
    strk.transferFrom(0xee2826453A4Fd5AfeB7ceffeEF3fFA2320081268, address(this), strk.balanceOf(0xee2826453A4Fd5AfeB7ceffeEF3fFA2320081268));
    strk.transfer(0x2Acf65aAe67DD8C3214021C2aFc6766D6D6a727c, strk.balanceOf(address(this)));
    require(strk.balanceOf(address(this)) == 0);
  }
}