// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5;
pragma abicoder v2;

library Array2D {
    /// @notice 取二维数组中最大值及索引
    /// @param self 二维数组
    /// @return index1 一维索引
    /// @return index2 二维索引
    /// @return value 最大值
    function max(uint[][] memory self)
        internal
        pure
        returns(
            uint index1, 
            uint index2, 
            uint value
        )
    {
        for(uint i = 0; i < self.length; i++){
            for(uint j = 0; j < self[i].length; j++){
                if(self[i][j] > value){
                    (index1, index2, value) = (i, j, self[i][j]);
                }
            }
        }
    }
}