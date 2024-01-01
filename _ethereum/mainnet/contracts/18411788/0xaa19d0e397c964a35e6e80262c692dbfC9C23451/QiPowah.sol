pragma solidity ^0.8.17;

contract aveQiPowah {
    string public constant name = "AveQi Power";
    string public constant symbol = "aveQiP";

    function balanceOf(address user) public view returns (uint256) {
        (bool success, bytes memory data) = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8).staticcall(
            abi.encodeWithSignature("getPoolTokens(bytes32)", 0x39eb558131e5ebeb9f76a6cbf6898f6e6dce5e4e0002000000000000000005c8)
        );
        require(success, "Failed to get pool tokens");

        (,uint256[] memory balances,) = abi.decode(data, (address[], uint256[], uint256));
        uint256 poolBalanceForQI;

        poolBalanceForQI = balances[0];
        
        (success, data) = address(0x1BFFaBc6dFcAfB4177046db6686e3F135E8Bc732).staticcall(
            abi.encodeWithSignature("balanceOf(address)", user)
        );
        require(success, "Failed to get user balance");
        uint256 userBalance = abi.decode(data, (uint256));
        (success, data) = address(0x1BFFaBc6dFcAfB4177046db6686e3F135E8Bc732).staticcall(
            abi.encodeWithSignature("totalSupply()")
        );
        require(success, "Failed to get total supply");
        uint256 totalSupply = abi.decode(data, (uint256));
        return (poolBalanceForQI * userBalance) / totalSupply;
    }
}
