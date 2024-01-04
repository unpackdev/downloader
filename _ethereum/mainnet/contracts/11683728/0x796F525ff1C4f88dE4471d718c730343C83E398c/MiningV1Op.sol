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
library MiningV1Op {

    using SafeMath for uint256;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function _biteToken(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index, 
            uint256 biteNum, 
            uint256 newTokenAmountPerEth
        )
        external
    {
        // check parameters
        require(token != address(0x0), "Nest:Mine:(token)=0"); 
        require(newTokenAmountPerEth > 0, "Nest:Mine:(price)=0");
        require(biteNum >= state.miningEthUnit && biteNum % state.miningEthUnit == 0, "Nest:Mine:!(bite)");

        // check sheet
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index]; 
        require(_sheet.height + state.priceDurationBlock >= block.number, "Nest:Mine:!EFF(sheet)");
        require(_sheet.remainNum >= biteNum, "Nest:Mine:!(remain)");

        // load address of NestPool 
        INestPool _C_NestPool = INestPool(state.C_NestPool);

        // check sheet sate
        uint256 _state = uint256(_sheet.state);
        require(_state == MiningV1Data.PRICESHEET_STATE_POSTED 
             || _state == MiningV1Data.PRICESHEET_STATE_BITTEN,  "Nest:Mine:!(state)");

        {
            address _ntoken = _C_NestPool.getNTokenFromToken(token);
            uint256 _ethFee = biteNum.mul(1 ether).mul(state.biteFeeRate).div(1000);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // pump fee into staking pool
            if (_ethFee > 0) {
                INestStaking(state.C_NestStaking).addETHReward{value:_ethFee}(_ntoken);
            }
        }
 
        // post a new price sheet
        { 
            // check bitting conditions
            uint256 _newEthNum;
            uint256 _newNestNum1k = uint256(_sheet.nestNum1k);
            {
                uint256 _level = uint256(_sheet.level);
                uint256 _newLevel = _level;

                if (_level > state.maxBiteNestedLevel && _level < 127) { // bitten sheet, nest doubling
                    _newEthNum = biteNum;
                    _newNestNum1k = _newNestNum1k.mul(state.biteNestInflateFactor * biteNum).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                } else if (_level <= state.maxBiteNestedLevel) {  // bitten sheet, eth doubling 
                    _newEthNum = biteNum.mul(state.biteInflateFactor);
                    _newNestNum1k = _newNestNum1k.mul(state.biteNestInflateFactor * biteNum).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                } 

                _C_NestPool.freezeNest(address(msg.sender), _newNestNum1k.mul(1000 * 1e18));


                if( _newEthNum.mul(newTokenAmountPerEth) < biteNum * _sheet.tokenAmountPerEth) {
                    uint256 _unfreezetokenAmount;
                    //_unfreezetokenAmount = uint256(_sheet.tokenAmountPerEth).sub(uint256(newTokenAmountPerEth)).mul(biteNum);
                    _unfreezetokenAmount = uint256(_sheet.tokenAmountPerEth).mul(biteNum).sub((uint256(newTokenAmountPerEth)).mul(_newEthNum));               
                    _C_NestPool.unfreezeToken(msg.sender, token, _unfreezetokenAmount);
                    _C_NestPool.freezeEth(msg.sender, _newEthNum.add(biteNum).mul(1 ether));
                } else {
                    _C_NestPool.freezeEthAndToken(msg.sender, _newEthNum.add(biteNum).mul(1 ether), 
                        token, _newEthNum.mul(newTokenAmountPerEth)
                                         .sub(biteNum * _sheet.tokenAmountPerEth));
                }

                MiningV1Data.PriceSheet[] storage _sheetOfToken = state.priceSheetList[token];
                // append a new price sheet
                _sheetOfToken.push(MiningV1Data.PriceSheet(
                    uint160(msg.sender),             // miner 
                    uint32(block.number),            // atHeight
                    uint32(_newEthNum),                 // ethNum
                    uint32(_newEthNum),                 // remainNum
                    uint8(_newLevel),                // level
                    uint8(_sheet.typ),               // typ
                    uint8(MiningV1Data.PRICESHEET_STATE_POSTED),  // state 
                    uint8(0),                        // _reserved
                    uint32(_newEthNum),                 // ethNumBal
                    uint32(_newEthNum),                 // tokenNumBal
                    uint32(_newNestNum1k),           // nestNum1k
                    uint128(newTokenAmountPerEth)    // tokenAmountPerEth
                ));
              
            }

            _sheet.state = MiningV1Data.PRICESHEET_STATE_BITTEN;
            _sheet.ethNumBal = uint32(uint256(_sheet.ethNumBal).add(biteNum));
            _sheet.tokenNumBal = uint32(uint256(_sheet.tokenNumBal).sub(biteNum));
            _sheet.remainNum = uint32(uint256(_sheet.remainNum).sub(biteNum));
            state.priceSheetList[token][index] = _sheet;
            
        }

        emit MiningV1Data.TokenBought(address(msg.sender), address(token), index, biteNum.mul(1 ether), biteNum.mul(_sheet.tokenAmountPerEth));
        return; 

    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function _biteEth(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index, 
            uint256 biteNum, 
            uint256 newTokenAmountPerEth
        )
        external
    {
        require(token != address(0x0), "Nest:Mine:(token)=0"); 
        require(newTokenAmountPerEth > 0, "Nest:Mine:(price)=0");
        require(biteNum >= state.miningEthUnit && biteNum % state.miningEthUnit == 0, "Nest:Mine:!(bite)");

        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index]; 
        require(block.number.sub(_sheet.height) <= state.priceDurationBlock, "Nest:Mine:!EFF(sheet)");
        require(_sheet.remainNum >= biteNum, "Nest:Mine:!(remain)");

        INestPool _C_NestPool = INestPool(state.C_NestPool);

        uint256 _state = uint256(_sheet.state);
        require(_state == MiningV1Data.PRICESHEET_STATE_POSTED 
            || _state == MiningV1Data.PRICESHEET_STATE_BITTEN,  "Nest:Mine:!(state)");

        {
            address _ntoken = _C_NestPool.getNTokenFromToken(token);

            uint256 _ethFee = biteNum.mul(1 ether).mul(state.biteFeeRate).div(1000);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // pump fee into staking pool
            INestStaking(state.C_NestStaking).addETHReward{value:_ethFee}(_ntoken);
        }
        
        // post a new price sheet
        { 
            // check bitting conditions
            uint256 _newEthNum;
            uint256 _newNestNum1k = uint256(_sheet.nestNum1k);
            {
                uint256 _level = uint256(_sheet.level);
                uint256 _newLevel = _level;

                if (_level > state.maxBiteNestedLevel && _level < 127) { // bitten sheet, nest doubling
                    _newEthNum = biteNum;
                    _newNestNum1k = _newNestNum1k.mul(state.biteNestInflateFactor * biteNum).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                } else if (_level <= state.maxBiteNestedLevel) {  // bitten sheet, eth doubling 
                    _newEthNum = biteNum.mul(state.biteInflateFactor);
                    _newNestNum1k = _newNestNum1k.mul(state.biteNestInflateFactor * biteNum).div(_sheet.ethNum);
                    _newLevel = _level + 1;
                }

                MiningV1Data.PriceSheet[] storage _sheetOfToken = state.priceSheetList[token];
                // append a new price sheet
                _sheetOfToken.push(MiningV1Data.PriceSheet(
                    uint160(msg.sender),             // miner 
                    uint32(block.number),            // atHeight
                    uint32(_newEthNum),                 // ethNum
                    uint32(_newEthNum),                 // remainNum
                    uint8(_newLevel),                // level
                    uint8(_sheet.typ),               // typ
                    uint8(MiningV1Data.PRICESHEET_STATE_POSTED),  // state 
                    uint8(0),                        // _reserved
                    uint32(_newEthNum),                 // ethNumBal
                    uint32(_newEthNum),                 // tokenNumBal
                    uint32(_newNestNum1k),           // nestNum1k
                    uint128(newTokenAmountPerEth)    // tokenAmountPerEth
                ));
            }
            _C_NestPool.freezeNest(address(msg.sender), _newNestNum1k.mul(1000 * 1e18));
            _C_NestPool.freezeEthAndToken(msg.sender, _newEthNum.sub(biteNum).mul(1 ether), 
                token, _newEthNum.mul(newTokenAmountPerEth)
                                    .add(biteNum * _sheet.tokenAmountPerEth));
            _sheet.state = MiningV1Data.PRICESHEET_STATE_BITTEN;
            _sheet.ethNumBal = uint32(uint256(_sheet.ethNumBal).sub(biteNum));
            _sheet.tokenNumBal = uint32(uint256(_sheet.tokenNumBal).add(biteNum));
            _sheet.remainNum = uint32(uint256(_sheet.remainNum).sub(biteNum));
            state.priceSheetList[token][index] = _sheet;
        }
        emit MiningV1Data.TokenSold(address(msg.sender), address(token), index, biteNum.mul(1 ether), biteNum.mul(_sheet.tokenAmountPerEth));
        return; 
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function _close(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        )
        external
    {
        // load sheet
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        // check if the sheet is closable
        require(_sheet.height + state.priceDurationBlock < block.number // safe_math
            || _sheet.remainNum == 0, "Nest:Mine:!(height)");

        // check owner
        require(address(_sheet.miner) == address(msg.sender), "Nest:Mine:!(miner)");
        // check state flag
        require(uint256(_sheet.state) != MiningV1Data.PRICESHEET_STATE_CLOSED, "Nest:Mine:!unclosed");

        // load ntoken
        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);

        // distribute rewards (NEST or NTOKEN)
        {
            uint256 h = _sheet.height;
            if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD && _sheet.level == 0) {   // for (USDT, NEST)
                uint256 _nestH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_nestH).div(_ethH);
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN && _sheet.level == 0) { // for (ERC20, NTOKEN)
                uint256 _ntokenH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }

        // unfreeze the assets withheld by the sheet
        {
            uint256 _ethAmount = uint256(_sheet.ethNumBal).mul(1 ether);
            uint256 _tokenAmount = uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth);
            uint256 _nestAmount = uint256(_sheet.nestNum1k).mul(1000 * 1e18);
            _sheet.ethNumBal = 0;
            _sheet.tokenNumBal = 0;
            _sheet.nestNum1k = 0;

            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 
        }

        // update the state flag
        _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;

        // write backs
        state.priceSheetList[token][index] = _sheet;

        // emit an event
        emit MiningV1Data.PriceClosed(address(msg.sender), token, index);
    }

    /// @notice Close a price sheet and withdraw assets for WEB users.  
    /// @dev Contracts aren't allowed to call it.
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function _closeAndWithdraw(
            MiningV1Data.State storage state, 
            address token, 
            uint256 index
        ) 
        external 
    {
        // check sheet if passing verification
        MiningV1Data.PriceSheet memory _sheet = state.priceSheetList[token][index];
        require(_sheet.height + state.priceDurationBlock < block.number // safe_math
            || _sheet.remainNum == 0, "Nest:Mine:!(height)");

        // check ownership and state
        require(address(_sheet.miner) == address(msg.sender), "Nest:Mine:!(miner)");
        require(uint256(_sheet.state) != MiningV1Data.PRICESHEET_STATE_CLOSED, "Nest:Mine:!unclosed");

        // get ntoken
        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);

        {
            uint256 h = _sheet.height;
            if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD && _sheet.level == 0) {
                uint256 _nestH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_nestH).div(_ethH);
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN && _sheet.level == 0) {
                uint256 _ntokenH = uint256(state.minedAtHeight[token][h] / (1 << 128));
                uint256 _ethH = uint256(state.minedAtHeight[token][h] % (1 << 128));
                uint256 _reward = uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }

        {
            uint256 _ethAmount = uint256(_sheet.ethNumBal).mul(1 ether);
            uint256 _tokenAmount = uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth);
            uint256 _nestAmount = uint256(_sheet.nestNum1k).mul(1000 * 1e18);
            _sheet.ethNumBal = 0;
            _sheet.tokenNumBal = 0;
            _sheet.nestNum1k = 0;

            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 
            _C_NestPool.withdrawEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
            _C_NestPool.withdrawNest(address(msg.sender), _nestAmount);
        }

        /*  
        - Issue #23: 
            Uncomment the following code to support withdrawing ethers cached 
        {
            uint256 _ethAmount = _C_NestPool.balanceOfEthInPool(address(msg.sender));
            if (_ethAmount > 0) {
                _C_NestPool.withdrawEth(address(msg.sender), _ethAmount);
            }
        }
        */

        _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;

        state.priceSheetList[token][index] = _sheet;

        emit MiningV1Data.PriceClosed(address(msg.sender), token, index);    
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param token The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function _closeList(
            MiningV1Data.State storage state, 
            address token, 
            uint32[] memory indices) 
        external 
    {
        uint256 _ethAmount;
        uint256 _tokenAmount;
        uint256 _nestAmount;
        uint256 _reward;

        // load storage point to the list of price sheets
        MiningV1Data.PriceSheet[] storage prices = state.priceSheetList[token];
        
        // loop
        for (uint i=0; i<indices.length; i++) {
            // load one sheet
            MiningV1Data.PriceSheet memory _sheet = prices[indices[i]];

            // check owner
            if (uint256(_sheet.miner) != uint256(msg.sender)) {
                continue;
            }

            // check state
            if(_sheet.state == MiningV1Data.PRICESHEET_STATE_CLOSED) {
                continue;
            }

            uint256 h = uint256(_sheet.height);
            // check if the sheet closable
            if (h + state.priceDurationBlock < block.number || _sheet.remainNum == 0) { // safe_math: untainted values

                // count up assets in the sheet
                _ethAmount = _ethAmount.add(uint256(_sheet.ethNumBal).mul(1 ether));
                _tokenAmount = _tokenAmount.add(uint256(_sheet.tokenNumBal).mul(_sheet.tokenAmountPerEth));
                _nestAmount = _nestAmount.add(uint256(_sheet.nestNum1k).mul(1000 * 1e18));

                // clear bits in the sheet
                _sheet.ethNumBal = 0;
                _sheet.tokenNumBal = 0;
                _sheet.nestNum1k = 0;
                
                // update state flag
                _sheet.state = MiningV1Data.PRICESHEET_STATE_CLOSED;
                
                // write back
                prices[indices[i]] = _sheet;

                // count up the reward
                if(_sheet.level == 0 && (_sheet.typ == MiningV1Data.PRICESHEET_TYPE_USD || _sheet.typ == MiningV1Data.PRICESHEET_TYPE_TOKEN)) {
                    uint256 _ntokenH = uint256(state.minedAtHeight[token][h] >> 128);
                    uint256 _ethH = uint256(state.minedAtHeight[token][h] << 128 >> 128);
                    _reward = _reward.add(uint256(_sheet.ethNum).mul(_ntokenH).div(_ethH));
                }
                emit MiningV1Data.PriceClosed(address(msg.sender), token, indices[i]);
            }
        }
        
        // load address of NestPool (for gas saving)
        INestPool _C_NestPool = INestPool(state.C_NestPool);

        // unfreeze assets
        if (_ethAmount > 0 || _tokenAmount > 0) {
            _C_NestPool.unfreezeEthAndToken(address(msg.sender), _ethAmount, token, _tokenAmount);
        }
        _C_NestPool.unfreezeNest(address(msg.sender), _nestAmount); 

        // distribute the rewards
        {
            uint256 _typ = prices[indices[0]].typ;
            if  (_typ == MiningV1Data.PRICESHEET_TYPE_USD) {
                _C_NestPool.addNest(address(msg.sender), _reward);
            } else if (_typ == MiningV1Data.PRICESHEET_TYPE_TOKEN) {
                address _ntoken = _C_NestPool.getNTokenFromToken(token);
                _C_NestPool.addNToken(address(msg.sender), _ntoken, _reward);
            }
        }
    }

    /*
    /// @dev This function is only for post dual-price-sheet before upgrading without assets
    function _post2Only4Upgrade(
            MiningV1Data.State storage state,
            address token,
            uint256 ethNum,
            uint256 tokenAmountPerEth,
            uint256 ntokenAmountPerEth
        )
        external 
    {
        // check parameters 
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "Nest:Mine:!(price)");
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        // no eth fee, no freezing

        // push sheets
        {
            uint8 typ1;
            uint8 typ2; 
            if (_ntoken == address(state.C_NestToken)) {
                typ1 = MiningV1Data.PRICESHEET_TYPE_USD;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NEST;
            } else {
                typ1 = MiningV1Data.PRICESHEET_TYPE_TOKEN;
                typ2 = MiningV1Data.PRICESHEET_TYPE_NTOKEN;
            }
            MiningV1Data.PriceSheet[] storage _sheetToken = state.priceSheetList[token];
            // append a new price sheet
            _sheetToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ1),     // typ
                uint8(MiningV1Data.PRICESHEET_STATE_CLOSED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),        // nestNum1k
                uint128(tokenAmountPerEth)      // tokenAmountPerEth
            ));

            MiningV1Data.PriceSheet[] storage _sheetNToken = state.priceSheetList[_ntoken];
            // append a new price sheet for ntoken
            _sheetNToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(typ2),     // typ
                uint8(MiningV1Data.PRICESHEET_STATE_CLOSED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),        // nestNum1k
                uint128(ntokenAmountPerEth)      // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 
            emit MiningV1Data.PricePosted(msg.sender, _ntoken, (_sheetNToken.length - 1), ethNum.mul(1 ether), ntokenAmountPerEth.mul(ethNum)); 
        }

        // no mining

        return; 
    }
    */

}