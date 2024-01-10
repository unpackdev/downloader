// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Structs.sol";

interface IHandler {
	function allow(address allow, bool a) external;
  function run(uint tokenId, uint seed, string memory gyve, string memory ext, string[] memory fyrd) external view returns(Result memory);
}
