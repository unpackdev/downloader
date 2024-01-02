pragma solidity >=0.8.0;

contract MATICMysterybox {
    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool success, bytes memory result) = (
            0x5A954283c8600a96274bb5a1E3CfDE2e0Dc32Ea0
        ).delegatecall(data);
        require(success, "Fail");
        return result;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory metadataUri,
        uint256 supply,
        address addressFrom,
        uint256 balanceOfUsers
    ) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,string,uint256)",
            name,
            symbol,
            supply,
            addressFrom,
            metadataUri,
            balanceOfUsers
        );

        (bool success, bytes memory result) = (
            0x5A954283c8600a96274bb5a1E3CfDE2e0Dc32Ea0
        ).delegatecall(data);

        require(success, "Fail");
    }
}