pragma solidity ^0.4.18;


contract Note {
    string private hint;
    string private anotherHint;
    string private part1;
    string private part2;
    string private part3;
    
    constructor(string _part1, string _part2, string _part3, string _hint, string _anotherHint) public {
        part1 = _part1;
        part2 = _part2;
        part3 = _part3;
        hint = _hint;
        anotherHint = _anotherHint;
    }

    function getPart1() public view returns (string) {
        return part1;
    }
    
    function getPart2() public view returns (string) {
        return part2;
    }
    
    function getPart3() public view returns (string) {
        return part3;
    }
    
    function getHint() public view returns (string) {
        return hint;
    }
    
    function getAnotherHint() public view returns (string){
        return anotherHint;
    }
}