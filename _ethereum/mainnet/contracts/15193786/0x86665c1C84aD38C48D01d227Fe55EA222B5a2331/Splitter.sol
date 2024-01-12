// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";

interface ISplitter {
    function split() external;
}

contract Splitter is ISplitter, Ownable {
    constructor() {}

    fallback() external payable {}

    receive() external payable {}

    function split() external onlyOwner {
        uint256 totBalance = address(this).balance;

        (bool hs1, ) = payable(0x5D7063f01b51AfA6d44D46797Cb9Ae5D90e3D64a).call{
            value: (totBalance * 27) / 100
        }("");
        require(hs1);

        (bool hs2, ) = payable(0xb0a5Cc4Ebe226e44445cAFDE6129b1e7d7cefaad).call{
            value: (totBalance * 265) / 1000
        }("");
        require(hs2);

        (bool hs3, ) = payable(0xa1f3a4887ba0A62dEA17FB137BB4bA9E46751068).call{
            value: (totBalance * 265) / 1000
        }("");
        require(hs3);

        (bool hs4, ) = payable(0xDaBE2E170a124Fc3eD9764656Dd2cb03c67387d2).call{
            value: (totBalance * 10) / 100
        }("");
        require(hs4);

        (bool hs5, ) = payable(0x794187FC9A06bC7f6495eC92B9326D6cD20c24a7).call{
            value: (totBalance * 2) / 100
        }("");
        require(hs5);

        (bool hs6, ) = payable(0x34BE61FD1C1958dAB8fed09221cDF0D4Ec12312C).call{
            value: (totBalance * 3) / 100
        }("");
        require(hs6);

        (bool hs7, ) = payable(0x993fDFA5A15fDee00bF3cDC85C28c710bf6720e5).call{
            value: (totBalance * 5) / 100
        }("");
        require(hs7);
    }
}
