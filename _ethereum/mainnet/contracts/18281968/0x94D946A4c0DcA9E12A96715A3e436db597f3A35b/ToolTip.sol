pragma solidity 0.8.18;

contract ToolTip {
    string public unnecessarilyLongReturn;

    function setUnnecessarilyLongReturn(string memory evenLongerReturn) public {
        unnecessarilyLongReturn = evenLongerReturn;
    }
}