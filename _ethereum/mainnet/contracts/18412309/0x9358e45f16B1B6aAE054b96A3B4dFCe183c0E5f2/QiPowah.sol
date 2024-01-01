pragma solidity ^0.8.17;

contract aveQiPowah {
    string public constant name = "AveQi Power";
    string public constant symbol = "aveQiP";

    function balanceOf(address user) public view returns (uint256) {
        uint256 poolBalanceForQi = getPoolBalanceForQi();
        uint256 lockedBalance = getLockedBalance(user);
        uint256 veBalance = getVeBalance(user);
        uint256 bptSupply = getBPTSupply();

        if (veBalance == 0 || bptSupply == 0) {
            return 0;
        }

    /*
(QI in pool * BPT user / BPT supply) * (BPT user  * 4 / veBPT user )
    */
        return (poolBalanceForQi * lockedBalance) / bptSupply * (veBalance*4) / lockedBalance;
    }

    function getPoolBalanceForQi() public view returns (uint256) {
        (bool success, bytes memory data) = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8).staticcall(
            abi.encodeWithSignature("getPoolTokens(bytes32)", 0x39eb558131e5ebeb9f76a6cbf6898f6e6dce5e4e0002000000000000000005c8)
        );
        require(success, "Failed to get pool tokens");

        (,uint256[] memory balances,) = abi.decode(data, (address[], uint256[], uint256));
        return balances[0];
    }

    function getVeBalance(address user) public view returns (uint256) {
        (bool success, bytes memory data) = address(0x1BFFaBc6dFcAfB4177046db6686e3F135E8Bc732).staticcall(
            abi.encodeWithSignature("balanceOf(address)", user)
        );
        require(success, "Failed to get user balance");
        uint256 userBalance = abi.decode(data, (uint256));
        return userBalance;
    }

    function getLockedBalance(address user) public view returns (uint256) {
        (bool success, bytes memory data) = address(0x1BFFaBc6dFcAfB4177046db6686e3F135E8Bc732).staticcall(
            abi.encodeWithSignature("locked(address)", user)
        );
        require(success, "Failed to get locked amount");
        (int128 amount,) = abi.decode(data, (int128, uint256));
        return uint256(int256(amount));
    }

    function getBPTSupply() public view returns (uint256) {
        (bool success, bytes memory data) = address(0x39eB558131E5eBeb9f76a6cbf6898f6E6DCe5e4E).staticcall(
            abi.encodeWithSignature("totalSupply()")
        );
        require(success, "Failed to get total supply");
        uint256 totalSupply = abi.decode(data, (uint256));
        return totalSupply;
    }
}


