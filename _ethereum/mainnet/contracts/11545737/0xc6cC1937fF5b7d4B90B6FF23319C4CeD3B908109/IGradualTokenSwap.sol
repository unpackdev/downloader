// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


// Interface of https://github.com/hegic/GradualTokenSwap/blob/master/contracts/GradualTokenSwap.sol
interface IGradualTokenSwap {
    function provide(uint amount) external;
    function withdraw() external;
    function available(address account) external view returns (uint256);
}
