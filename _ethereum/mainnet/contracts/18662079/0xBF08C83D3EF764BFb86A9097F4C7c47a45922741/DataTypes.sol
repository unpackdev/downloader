// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IBlurPool.sol";
import "./IBlend.sol";
import "./Structs.sol";

library DataTypes {
    struct LienData {
        Lien lien;
        uint256 lienId;
    }

    struct State {
        IBlurPool blurPool;
        IBlend blend;
        LienData[] liens;
        mapping(uint256 => uint256) lienIdToIndex;
        uint256 managerFee;
    }
}
