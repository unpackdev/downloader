pragma solidity ^0.6.0;

//通过log函数重载，对不同类型的变量trigger不同的event，实现solidity打印效果，使用方法为：log(string name, var value)

contract Console {
    event LogUint(string);

    function log(string memory s) internal {
        emit LogUint(s);
    }


}