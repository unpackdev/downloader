// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";

//@title 资产相关结构及逻辑库
library AssetLibrary {
    using SafeMath for uint256;

    struct Asset {
        uint256 slot; //标识资产的分类
        uint256 units; //资产份数
        bool isValid; //是否有效
    }

    //@notice 增加Vault的份额
    //@dev
    //@param self 需要增加份额的Vault的引用
    //@param slot
    function mint(Asset storage self, uint256 slot, uint256 units) internal {
        if (! self.isValid) {
            self.slot = slot;
            self.isValid = true;
        } else {
            require(self.slot == slot, "not same slot");
        }
        self.units = self.units.add(units);
    }

    function merge(Asset storage self, Asset storage target) internal returns (uint256){
        require(self.isValid && target.isValid, "asset is invalid");
        require(self.slot == target.slot, "need same slot");

        uint256 mergeUnits = self.units;
        self.units = self.units.sub(mergeUnits, "units exceeds balance");
        target.units = target.units.add(mergeUnits);
        self.isValid = false;

        return (mergeUnits);
    }

    function transfer(Asset storage self, Asset storage target, uint256 units) internal {
        require(self.isValid, "source asset invalid");
        self.units = self.units.sub(units, "transfer units exceeds balance");
        if (target.isValid) {
            require(self.slot == target.slot, "need same slot");
        } else {
            target.slot = self.slot;
            target.isValid = true;
        }

        target.units = target.units.add(units);
    }

    function burn(Asset storage self, uint256 units) internal {
        self.units = self.units.sub(units, "burn units exceeds balance");
    }
}