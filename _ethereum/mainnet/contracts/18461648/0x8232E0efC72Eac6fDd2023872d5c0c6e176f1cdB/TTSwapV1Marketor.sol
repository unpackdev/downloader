// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ITTSwapV1Marketor.sol";

contract TTSwapV1Marketor is ITTSwapV1Marketor {
    //市场管理员
    mapping(uint128 => address) public Marketors;
    //记录管理号编号
    //Marketoraddress=>MarketorNo
    mapping(address => uint128) public MarketorsNo;
    //记录市场管理员人数(包含已加人员)
    uint128 public maxMarketorNo;
    //记录市场创建者
    address public marketCreator;

    //初始化时
    constructor(address _marketCreator) {
        marketCreator = _marketCreator;
        maxMarketorNo = 1;
    }

    //只能市场创建者运行
    modifier onlyMarketCreator() {
        require(msg.sender == marketCreator);
        _;
    }

    //增加市场管理员
    function setMarketorByMarketCreator(
        address _owner
    ) external override onlyMarketCreator {
        require(
            maxMarketorNo + 1 >= maxMarketorNo,
            "maxMarketorNo connot increase"
        );
        maxMarketorNo += 1;
        MarketorsNo[_owner] = maxMarketorNo;
        Marketors[maxMarketorNo] = _owner;
        emit e_setMarketorByMarketCreator(_owner);
    }

    //删除市场管理员
    function delMarketorByMarketCreator(
        address _owner
    ) external override onlyMarketCreator {
        delete Marketors[MarketorsNo[_owner]];
        delete MarketorsNo[_owner];
        emit e_delMarketorByMarketCreator(_owner);
    }

    //判定执行者是否是管理员
    function isValidMarketor() external view override returns (bool) {
        return MarketorsNo[msg.sender] > 0 ? true : false;
    }

    //判定特定地址是否是管理员
    function isValidMarketor(
        address mkaddress
    ) external view override returns (bool) {
        return MarketorsNo[mkaddress] > 0 ? true : false;
    }

    //获取调用者的管理员编号
    function getMarketorNo() external view returns (uint128) {
        return MarketorsNo[msg.sender];
    }

    //获取特定地址的管理员编号
    function getMarketorNo(
        address _marketorAddress
    ) external view returns (uint128) {
        return MarketorsNo[_marketorAddress];
    }

    //获取当前最大编号
    function getMaxMarketorNo() external view returns (uint128) {
        return maxMarketorNo;
    }
}
