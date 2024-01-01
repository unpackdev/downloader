// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library LGate {
    struct Info {
        // the address of the Market
        // 记录market地址
        //Gate编号
        uint128 gateNo;
        // 门户地址
        address gateAddress;
        // 门户简称
        bytes32 name;
        //创建时间
        uint256 createtimestamp;
        // 如果门户违反行为准则,进行冻结限制
        bool marketunlock; //true 表示已解冻 false表示已冻结
        // config by the gater
        bool gateunlock; //true 表示已解冻 false表示已冻结
        bool isUsed;
    }

    //相应接口
    struct DetailInfo {
        bytes32 full_name; //全称
        bytes32 country; //国家
        bytes32 OfficalWebsite; //官网
        bytes32 OfficalIp; //Ip
        bytes32 twriterUrl; //推特
        bytes32 bbsUrl; //bbs论坛地址
    }
}
