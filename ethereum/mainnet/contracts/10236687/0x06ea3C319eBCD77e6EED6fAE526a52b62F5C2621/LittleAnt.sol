pragma solidity ^0.4.26;


contract LittleAnt {
    string public activity = '<div>为了感谢一路陪伴小蚂蚁成长的伙伴家人们制定此时间红包，此红包从2020年6月1日起开始生效，有效期为6年。<br>红包持有人通过对应编码的人民币编号以及对应小蚂蚁账号，可以来领取对应的时间红包奖励，仅限一次，领取或过期即失效。<br>时间：2021年6月1日，等级：黄金KOL达人，红包：<span style="color: red">99</span> CFT;<br>时间：2022年6月1日，等级：铂金KOL达人，红包：<span style="color: red">999</span> CFT;<br>时间：2023年6月1日，等级：钻石KOL达人，红包：<span style="color: red">9999</span> CFT;<br>时间：2024年6月1日，等级：星耀KOL达人，红包：<span style="color: red">99999</span> CFT;<br>时间：2025年6月1日，等级：王者KOL达人，红包：<span style="color: red">999999</span> CFT;<br>时间：2026年6月1日，等级：荣耀KOL达人，红包：<span style="color: red">9999999</span> CFT;</div>';
    address public owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    event ProclaimData(string activity, string users);
    
    // 更换管理员
    function changeOwner(address _newOwner) public returns (bool success){
         require(msg.sender == owner, "You are not a owner");
         owner = _newOwner;
         success = true;
    }

    // 宣布
	function proclaimData(string users) public {
	    require(msg.sender == owner, "You are not a owner");
	    emit ProclaimData(activity, users);
	}
	
}