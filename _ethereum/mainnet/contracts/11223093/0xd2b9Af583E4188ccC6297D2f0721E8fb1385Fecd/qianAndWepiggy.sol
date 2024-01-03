pragma solidity ^0.5.16;


interface Proxy {
    function userInfo(uint256,address) external view returns(uint256,uint256,uint256,bool) ;
    function reserve(address, address) external view returns(uint256);
}


contract qianAndWepiggy {
    function balanceOf(address _voter) public view returns (uint) {
        (uint256 amount,,,) = Proxy(0x451032C55F813338b6e73c1c4B24217614165454).userInfo(10,_voter);
        uint256 qian = Proxy(0x2336817CCC263B17725D7c15D687510D1d10a1b6).reserve(_voter,0xa1d0E215a23d7030842FC67cE582a6aFa3CCaB83);
        return amount+qian;
    }    
}