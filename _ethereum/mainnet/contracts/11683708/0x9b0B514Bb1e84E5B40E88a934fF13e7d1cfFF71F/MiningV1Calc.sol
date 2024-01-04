// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./ABDKMath64x64.sol";

import "./INestPool.sol";
import "./INestStaking.sol";
import "./INToken.sol";
import "./INNRewardPool.sol";
import "./MiningV1Data.sol";
//import "./console.sol";


/// @title  NestMiningV1/MiningV1Calc
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>
library MiningV1Calc {

    using SafeMath for uint256;
    // average block-out time: 14s
    uint8 constant timespan = 14;
    function _calcVola(
            // uint256 ethA0, 
            uint256 tokenA0, 
            // uint256 ethA1, 
            uint256 tokenA1, 
            int128 _sigma_sq, 
            int128 _ut_sq,
            uint256 _interval
        ) 
        private 
        pure
        // pure 
        returns (int128, int128)
    {
        int128 _ut_sq_2 = ABDKMath64x64.div(_ut_sq, 
            ABDKMath64x64.fromUInt(_interval.mul(timespan)));

        int128 _new_sigma_sq = ABDKMath64x64.add(
            ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _sigma_sq), 
            ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _ut_sq_2));

        int128 _new_ut_sq;
        _new_ut_sq = ABDKMath64x64.pow(ABDKMath64x64.sub(
                    ABDKMath64x64.divu(tokenA1, tokenA0), 
                    ABDKMath64x64.fromUInt(1)), 
                2);
        
        return (_new_sigma_sq, _new_ut_sq);
    }

    function _calcAvg(uint256 ethA, uint256 tokenA, uint256 _avg) 
        private 
        pure
        returns(uint256)
    {
        uint256 _newP = tokenA.div(ethA);
        uint256 _newAvg;

        if (_avg == 0) {
            _newAvg = _newP;
        } else {
            _newAvg = (_avg.mul(95).div(100)).add(_newP.mul(5).div(100));
            // _newAvg = ABDKMath64x64.add(
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(95, 100), _avg),
            //     ABDKMath64x64.mul(ABDKMath64x64.divu(5,100), _newP));
        }

        return _newAvg;
    }

    function _moveAndCalc(
            MiningV1Data.PriceInfo memory p0,
            MiningV1Data.PriceSheet[] storage pL,
            uint256 priceDurationBlock
        )
        private
        view
        returns (MiningV1Data.PriceInfo memory)
    {
        uint256 i = p0.index + 1;
        if (i >= pL.length) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 h = uint256(pL[i].height);
        if (h + priceDurationBlock >= block.number) {
            return (MiningV1Data.PriceInfo(0,0,0,0,0,int128(0),int128(0), uint128(0), 0));
        }

        uint256 ethA1 = 0;
        uint256 tokenA1 = 0;
        while (i < pL.length && pL[i].height == h) { 
            uint256 _remain = uint256(pL[i].remainNum);
            if (_remain == 0) {
                i = i + 1;
                continue;
            }
            ethA1 = ethA1 + _remain;
            tokenA1 = tokenA1 + _remain.mul(pL[i].tokenAmountPerEth);
            i = i + 1;
        }
        i = i - 1;

        if (ethA1 == 0 || tokenA1 == 0) {
            return (MiningV1Data.PriceInfo(
                    uint32(i),  // index
                    uint32(0),  // height
                    uint32(0),  // ethNum
                    uint32(0),  // _reserved
                    uint32(0),  // tokenAmount
                    int128(0),  // volatility_sigma_sq
                    int128(0),  // volatility_ut_sq
                    uint128(0),  // avgTokenAmount
                    0           // _reserved2
            ));
        }
        int128 new_sigma_sq;
        int128 new_ut_sq;
        {
            if (uint256(p0.ethNum) != 0) {
                (new_sigma_sq, new_ut_sq) = _calcVola(
                    uint256(p0.tokenAmount).div(uint256(p0.ethNum)), 
                    uint256(tokenA1).div(uint256(ethA1)),
                p0.volatility_sigma_sq, p0.volatility_ut_sq, 
                i - p0.index);
            }
        }
        uint256 _newAvg = _calcAvg(ethA1, tokenA1, p0.avgTokenAmount); 

        return(MiningV1Data.PriceInfo(
                uint32(i),          // index
                uint32(h),          // height
                uint32(ethA1),      // ethNum
                uint32(0),          // _reserved
                uint128(tokenA1),   // tokenAmount
                new_sigma_sq,       // volatility_sigma_sq
                new_ut_sq,          // volatility_ut_sq
                uint128(_newAvg),   // avgTokenAmount
                uint128(0)          // _reserved2
        ));
    }

    /// @dev The function updates the statistics of price sheets
    ///     It calculates from priceInfo to the newest that is effective.
    ///     Different from `_statOneBlock()`, it may cross multiple blocks.
    function _stat(MiningV1Data.State storage state, address token)
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];

        if (pL.length < 2) {
            return;
        }

        if (p0.height == 0) {
            MiningV1Data.PriceSheet memory _sheet = pL[0];
            p0.ethNum = _sheet.ethNum;
            p0.tokenAmount = uint128(uint256(_sheet.tokenAmountPerEth).mul(_sheet.ethNum));
            p0.height = _sheet.height;
            p0.volatility_sigma_sq = 0;
            p0.volatility_ut_sq = 0;
            p0.avgTokenAmount = uint128(_sheet.tokenAmountPerEth);
            state.priceInfo[token] = p0;
        }

        MiningV1Data.PriceInfo memory p1;

        // record the gas usage
        uint256 startGas = gasleft();
        uint256 gasUsed;

        while (uint256(p0.index) < pL.length && uint256(p0.height) + state.priceDurationBlock < block.number){
            gasUsed = startGas - gasleft();
            // NOTE: check gas usage to prevent DOS attacks
            if (gasUsed > 1_000_000) {
                break; 
            }
            p1 = _moveAndCalc(p0, pL, state.priceDurationBlock);
            if (p1.index <= p0.index) {    // bootstraping
                break;
            } else if (p1.ethNum == 0) {   // jump cross a block with bitten prices
                p0.index = p1.index;
                continue;
            } else {                       // calculate one more block
                p0 = p1;
            }
        }

        if (p0.index > state.priceInfo[token].index) {
            state.priceInfo[token] = p0;
        }
        return;
    }

    /// @dev The function updates the statistics of price sheets across only one block.
    function _statOneBlock(MiningV1Data.State storage state, address token) 
        external 
    {
        MiningV1Data.PriceInfo memory p0 = state.priceInfo[token];
        MiningV1Data.PriceSheet[] storage pL = state.priceSheetList[token];
        if (pL.length < 2) {
            return;
        }
        (MiningV1Data.PriceInfo memory p1) = _moveAndCalc(p0, state.priceSheetList[token], state.priceDurationBlock);
        if (p1.index > p0.index && p1.ethNum != 0) {
            state.priceInfo[token] = p1;
        } else if (p1.index > p0.index && p1.ethNum == 0) {
            p0.index = p1.index;
            state.priceInfo[token] = p1;
        }
        return;
    }

    /// @notice Return a consecutive price list for a token 
    /// @dev 
    /// @param token The address of token contract
    /// @param num   The length of price list
    function _priceListOfToken(
            MiningV1Data.State storage state, 
            address token, 
            uint8 num
        )
        external 
        view
        returns (uint128[] memory data, uint256 bn) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = _list.length;
        uint256 _index = 0;
        data = new uint128[](num * 3);
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        // loop
        uint256 _curr = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _curr = uint256(_sheet.height);
            if (_prev == 0) {
                if (_curr + state.priceDurationBlock < block.number) {
                    data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                    _ethNum = uint256(_sheet.remainNum);
                    data[_index + 1] = uint128(_ethNum.mul(1 ether));
                    data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                    bn = _curr + state.priceDurationBlock;  // safe math
                    _prev = _curr;
                }
            } else if (_prev == _curr) {
                _ethNum = uint256(_sheet.remainNum);
                data[_index + 1] += uint128(_ethNum.mul(1 ether));
                data[_index + 2] += uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _curr) {
                _index += 3;
                if (_index >= uint256(num * 3)) {
                    break;
                }
                data[_index] = uint128(_curr + state.priceDurationBlock); // safe math
                _ethNum = uint256(_sheet.remainNum);
                data[_index + 1] = uint128(_ethNum.mul(1 ether));
                data[_index + 2] = uint128(_ethNum.mul(_sheet.tokenAmountPerEth));
                _prev = _curr;
            }
        } 
        // require (data.length == uint256(num * 3), "Incorrect price list length");
    }


    function _priceOfTokenAtHeight(
            MiningV1Data.State storage state, 
            address token, 
            uint64 atHeight
        )
        external 
        view 
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {

        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token];
        uint256 len = state.priceSheetList[token].length;
        MiningV1Data.PriceSheet memory _sheet;
        uint256 _ethNum;

        if (len == 0) {
            return (0, 0, 0);
        }

        uint256 _first = 0;
        uint256 _prev = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _list[len - i];
            _first = uint256(_sheet.height);
            if (_prev == 0) {
                if (_first <= uint256(atHeight) && _first + state.priceDurationBlock < block.number) {
                    _ethNum = uint256(_sheet.remainNum);
                    ethAmount = _ethNum.mul(1 ether);
                    tokenAmount = _ethNum.mul(_sheet.tokenAmountPerEth);
                    blockNum = _first;
                    _prev = _first;
                }
            } else if (_first == _prev) {
                _ethNum = uint256(_sheet.remainNum);
                ethAmount = ethAmount.add(_ethNum.mul(1 ether));
                tokenAmount = tokenAmount.add(_ethNum.mul(_sheet.tokenAmountPerEth));
            } else if (_prev > _first) {
                break;
            }
        }
    }

    function _priceSheet(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        ) 
        view external 
        returns (MiningV1Data.PriceSheetPub memory sheet) 
    {
        uint256 len = state.priceSheetList[token].length;
        require (index < len, "Nest:Mine:!index");
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        sheet.miner = _sheet.miner;
        sheet.height = _sheet.height;
        sheet.ethNum = _sheet.ethNum;
        sheet.typ = _sheet.typ;
        sheet.state = _sheet.state;
        sheet.ethNumBal = _sheet.ethNumBal;
        sheet.tokenNumBal = _sheet.tokenNumBal;
    }

    
    function unVerifiedSheetList(
            MiningV1Data.State storage state, 
            address token
        ) 
        view 
        public
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        uint256 num;
        for (uint i = 0; i < len; i++) {
            if (_list[len - 1 - i].height + state.priceDurationBlock < block.number) {
                break;
            }
            num += 1;
        }

        sheets = new MiningV1Data.PriceSheetPub2[](num);
        for (uint i = 0; i < num; i++) {
            MiningV1Data.PriceSheet memory _sheet = _list[len - 1 - i];
            if (_sheet.height + state.priceDurationBlock < block.number) {
                break;
            }
            //sheets[i] = _sheet;
            sheets[i].miner = _sheet.miner;
            sheets[i].height = _sheet.height;
            sheets[i].ethNum = _sheet.ethNum;
            sheets[i].remainNum = _sheet.remainNum;
            sheets[i].level = _sheet.level;
            sheets[i].typ = _sheet.typ;
            sheets[i].state = _sheet.state;

            sheets[i].index = len - 1 - i;

            sheets[i].nestNum1k = _sheet.nestNum1k;
            sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;
        }
    }

    function unClosedSheetListOf(
            MiningV1Data.State storage state, 
            address miner, 
            address token, 
            uint256 fromIndex, 
            uint256 num) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }

            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)
                && (_sheet.state == MiningV1Data.PRICESHEET_STATE_POSTED 
                    || _sheet.state == MiningV1Data.PRICESHEET_STATE_BITTEN)) {
            
            sheets[i].miner = _sheet.miner;
            sheets[i].height = _sheet.height;
            sheets[i].ethNum = _sheet.ethNum;
            sheets[i].remainNum = _sheet.remainNum;
            sheets[i].level = _sheet.level;
            sheets[i].typ = _sheet.typ;
            sheets[i].state = _sheet.state;

            sheets[i].index = fromIndex - i;

            sheets[i].nestNum1k = _sheet.nestNum1k;
            sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

    function sheetListOf(
           MiningV1Data.State storage state, 
           address miner, 
           address token, 
           uint256 fromIndex, 
           uint256 num
        ) 
        view 
        external
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        sheets = new MiningV1Data.PriceSheetPub2[](num);
        MiningV1Data.PriceSheet[] storage _list = state.priceSheetList[token]; 
        uint256 len = _list.length;
        require(fromIndex < len, "Nest:Mine:!from");

        for (uint i = 0; i < num; i++) {
            if (fromIndex < i) {
                break;
            }
            MiningV1Data.PriceSheet memory _sheet = _list[fromIndex - i];
            if (uint256(_sheet.miner) == uint256(miner)) {
            
            sheets[i].miner = _sheet.miner;
            sheets[i].height = _sheet.height;
            sheets[i].ethNum = _sheet.ethNum;
            sheets[i].remainNum = _sheet.remainNum;
            sheets[i].level = _sheet.level;
            sheets[i].typ = _sheet.typ;
            sheets[i].state = _sheet.state;

            sheets[i].index = fromIndex - i;

            sheets[i].nestNum1k = _sheet.nestNum1k;
            sheets[i].tokenAmountPerEth = _sheet.tokenAmountPerEth;

            }
        }
    }

}