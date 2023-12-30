pragma solidity ^0.4.22;

contract ERC20Token {
    function transferFrom(
        address,
        address,
        uint256
    ) public returns (bool);
}

contract Batch {
    function transferETHWithValue (
        address[] _dsts,
        uint256 _values
    ) public payable {
        for (uint256 i = 0; i < _dsts.length; i++) {
             _dsts[i].transfer(_values);
        }
    }
    
    function transferETHWithValues (
        address[] _dsts,
        uint256[] _values
    ) public payable {
        for (uint256 i = 0; i < _dsts.length; i++) {
             _dsts[i].transfer(_values[i]);
        }
    }
    
      function transferERC20WithValue (
        address _token,
        address[] _dsts,
        uint256 _values
    ) public payable {
        ERC20Token token = ERC20Token(_token);
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transferFrom(msg.sender, _dsts[i], _values);
        }
    }
    
    function transferERC20WithValues (
        address _token,
        address[] _dsts,
        uint256[] _values
    ) public payable {
        ERC20Token token = ERC20Token(_token);
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transferFrom(msg.sender, _dsts[i], _values[i]);
        }
    }
}