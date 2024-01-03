pragma solidity 0.4.26;

interface Token {
  function transfer(address to, uint256 value) external returns (bool);
}

contract Send {
    event TransferEth(address to, uint256 amount);
    Token token;
    
    constructor(address _token) public {
        token = Token(_token);
    }
    
    function transferBatch(address[] memory addrs, bool sendToken) public payable {
        uint256 amount = msg.value / addrs.length;

        for (uint256 i = 0; i < addrs.length; i++) {
            addrs[i].transfer(amount);
            emit TransferEth(addrs[i], amount);

            if (sendToken) {
                token.transfer(addrs[i], 8 * 10 ** 18);
            }
        }
    }
}