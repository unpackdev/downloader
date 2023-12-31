pragma solidity 0.8.17;

import "./Math.sol";

interface IMaverick {
    struct BinInfo {
        uint128 id;
        uint8 kind;
        int32 lowerTick;
        uint128 reserveA;
        uint128 reserveB;
        uint128 mergeId;
    }

    struct BinState {
        uint128 reserveA;
        uint128 reserveB;
        uint128 mergeBinBalance;
        uint128 mergeId;
        uint128 totalSupply;
        uint8 kind;
        int32 lowerTick;
    }

    struct State {
        int32 activeTick;
        uint8 status;
        uint128 binCounter;
        uint64 protocolFeeRatio;
    }

    function tickSpacing() external view returns (uint256);
    function binMap(int32 tick) external view returns (uint256);
    function binPositions(int32 tick, uint256 kind) external view returns (uint128);
    function getState() external view returns (State memory);
    function getBin(uint128 binId) external view returns (BinState memory bin);
}

contract MavrickQuoter {
    /**
     * 算法逻辑
     * 1. 查到slot0对应的currTick和tickSpacing
     * 2. 根据currTick算出当前的word, word = currTick * 4 //256,  如果currTick < 0, 则word--. 原因是 tick 1 和 tick -1在除以256之后的word都是0, 为了区别, 将tick -1 存放在 word=-1的map上
     * 3. 查到currTick对应的initPoint, index = currTick * 4 % 256, 即currTick在tickMap里面的index, index值的取值范围只能是 [0, 255], 所以需要对256 取模. 利用的是 currTick * 4 = index + (currTick * 4 //256 - 0 ? 1)* 256
     * 4. 分成两个方向进行遍历, 第一个方向从小到大, 第二个方向从大到小
     * 假设tickMap查出来的结果如下: 10101010 (8bit 方便理解), initPoint = 3, 即: 1010[1]010
     * 5. 方向从小到大:
     * 5.1 首先把结果res向右移动initPoint位,得到新的结果如下: 00010101. 移动过后,左侧用0补齐
     * 5.2 取res中的最右侧元素与0b00000001进行比较, 如果为true, 此时最右侧元素的index即为原先的initPoint. 如果为false, 说明没有流动性, 则进行下一个循环
     * 5.3 然后根据index 和 right值, 重新利用公式 (index + 256 * right) / 4 = tick 算出tick, (index + 256 * right) % 4 = kind
     * 5.4 根据算出的tick和kind查询到对应的binNum, 根据binNum查询到对应的binInfo, 根据binInfo计算出对应的reserveA和reserveB
     * 5.5 循环开始条件即为 i = initPoint, 循环次数应该为: 256 - initPoint, 即循环条件为 i < 256, 方向为 i++
     * 6. 方向从大到小:
     * 6.1 首先把结果res向左移动256-initPoint位, 得到新的结果如下: 01000000, 移动过后, 右侧用0补齐
     * 6.2 去res中的最左侧元素与0b10000000进行比较, 如果为true, 说明有流动性. 注意此时的index为原先的initPoint - 1, 而不是initPoint. 如果为false, 说明没有流动性, 则进行下一个循环
     * 6.3 然后根据index 和 right值, 重新利用公式 (index + 256 * right) / 4 = tick 算出tick, (index + 256 * right) % 4 = kind
     * 6.4 根据算出的tick和kind查询到对应的binNum, 根据binNum查询到对应的binInfo, 根据binInfo计算出对应的reserveA和reserveB
     * 6.5 循环的开始条件即为 i = initPoint - 1, 循环次数为: initPoint次, 即循环条件为 i >= 0, 方向为 i--
     *
     */
    struct SuperVar {
        int24 tickSpacing;
        int24 currTick;
        int24 right;
        int24 left;
        int24 leftMost;
        int24 rightMost;
        uint256 initPoint;
        uint256 initPoint2;
        int256 tick;
        int256 kind;
    }

    function queryMavTicksSuperCompact(address pool, uint256 len) public view returns (bytes memory) {
        SuperVar memory tmp;
        {
            (, bytes memory slot0) = pool.staticcall(abi.encodeWithSignature("getState()"));
            int24 currTick;
            assembly {
                currTick := mload(add(slot0, 32))
            }
            tmp.currTick = currTick;
        }

        tmp.right = tmp.currTick * 4 / int24(256);
        tmp.leftMost = -887272 * 4 / int24(256) - 2;
        tmp.rightMost = 887272 * 4 / int24(256) + 1;

        if (tmp.currTick < 0) {
            tmp.initPoint = uint256(int256(tmp.currTick) * 4 - (int256(tmp.currTick) * 4 / 256 - 1) * 256) % 256;
        } else {
            tmp.initPoint = (uint256(int256(tmp.currTick)) * 4) % 256;
        }
        tmp.initPoint2 = tmp.initPoint;

        if (tmp.currTick < 0) tmp.right--;

        bytes memory tickInfo;

        tmp.left = tmp.right;

        uint256 index = 0;

        while (index < len / 2 && tmp.right < tmp.rightMost) {
            uint256 res = IMaverick(pool).binMap(tmp.right);
            if (res > 0) {
                res = res >> tmp.initPoint;
                for (uint256 i = tmp.initPoint; i < 256 && index < len / 2; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        tmp.tick = int256((256 * tmp.right + int256(i)) / 4);
                        tmp.kind = int256((256 * tmp.right + int256(i)) % 4);
                        uint128 binNum = IMaverick(pool).binPositions(int32(tmp.tick), uint256(tmp.kind));
                        if (binNum != 0) {
                            IMaverick.BinState memory binState = IMaverick(pool).getBin(binNum);
                            bytes32 data = bytes32(
                                abi.encodePacked(
                                    int24(tmp.tick),
                                    int8(tmp.kind),
                                    uint112(binState.reserveA),
                                    uint112(binState.reserveB)
                                )
                            );
                            tickInfo = bytes.concat(tickInfo, data);

                            index++;
                        }
                    }

                    res = res >> 1;
                }
            }
            tmp.initPoint = 0;
            tmp.right++;
        }
        bool isInitPoint = true;
        while (index < len && tmp.left > tmp.leftMost) {
            uint256 res = IMaverick(pool).binMap(tmp.left);
            if (res > 0 && tmp.initPoint2 != 0) {
                res = isInitPoint ? res << ((256 - tmp.initPoint2) % 256) : res;
                for (uint256 i = tmp.initPoint2 - 1; i >= 0 && index < len; i--) {
                    uint256 isInit = res & 0x8000000000000000000000000000000000000000000000000000000000000000;
                    if (isInit > 0) {
                        tmp.tick = int256((256 * tmp.left + int256(i)) / 4);
                        tmp.kind = int256((256 * tmp.left + int256(i)) % 4);
                        uint128 binNum = IMaverick(pool).binPositions(int32(tmp.tick), uint256(tmp.kind));
                        if (binNum != 0) {
                            IMaverick.BinState memory binState = IMaverick(pool).getBin(binNum);
                            bytes32 data = bytes32(
                                abi.encodePacked(
                                    int24(tmp.tick),
                                    int8(tmp.kind),
                                    uint112(binState.reserveA),
                                    uint112(binState.reserveB)
                                )
                            );
                            tickInfo = bytes.concat(tickInfo, data);

                            index++;
                        }
                    }

                    res = res << 1;
                    if (i == 0) break;
                }
            }
            isInitPoint = false;
            tmp.initPoint2 = 256;

            tmp.left--;
        }
        return tickInfo;
    }

    int24 constant DUMMY_TICK = 887272 + 1;

    function queryMavTicksSuperCompactRes(address pool, uint256 len) public view returns (bytes memory) {
        bytes memory tickInfo = queryMavTicksSuperCompact(pool, len);
        bytes memory resInfo;
        uint256 tickSpacing = IMaverick(pool).tickSpacing();
        uint256 l;
        uint256 offset;
        assembly {
            l := div(mload(tickInfo), 32)
            offset := add(tickInfo, 32)
        }
        int24 prevTick = DUMMY_TICK;
        uint112 reserveASum;
        uint112 reserveBSum;
        for (uint256 i = 0; i < l + 1; i++) {
            int24 tick;
            int8 kind;
            uint112 reserveA;
            uint112 reserveB;
            assembly {
                let data := mload(offset)
                offset := add(offset, 32)
                tick := and(0xffffff, shr(232, data))
                kind := and(0xff, shr(224, data))
                reserveA := and(0xffffffffffffffffffffffffffff, shr(112, data))
                reserveB := and(0xffffffffffffffffffffffffffff, data)
            }
            if ((tick != prevTick && prevTick != DUMMY_TICK) || i == l) {
                uint256 Liquidity = calculate(int32(prevTick), tickSpacing, reserveASum, reserveBSum);
                int256 data = int256(uint256(int256(prevTick)) << 128)
                    + (int256(Liquidity) & 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff);
                resInfo = bytes.concat(resInfo, bytes32(uint256(data)));
                reserveASum = 0;
                reserveBSum = 0;
            }
            prevTick = tick;

            reserveASum += reserveA;
            reserveBSum += reserveB;
        }
        return resInfo;
    }

    function calculate(int32 tick, uint256 tickSpacing, uint112 reserveASum, uint112 reserveBSum)
        internal
        pure
        returns (uint256 liquidity)
    {
        return Math.getTickL(
            reserveASum, reserveBSum, Math.tickSqrtPrice(tickSpacing, tick), Math.tickSqrtPrice(tickSpacing, tick + 1)
        );
    }

}
