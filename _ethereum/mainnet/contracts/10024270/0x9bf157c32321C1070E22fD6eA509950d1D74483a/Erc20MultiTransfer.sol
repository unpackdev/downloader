pragma solidity ^0.4.25;
contract MultiTransfer {
    function multiTransfer(address[] _addresses, uint256 amount) payable {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].call.value(amount).gas(21000)();
        }
    }
    function() payable {}
}
contract ERC20 {
    function transfer(address _recipient, uint256 amount) public;
}       
contract Erc20MultiTransfer {
    function erc20MultiTransfer(ERC20 token, address[] _addresses, uint256 amount) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
}