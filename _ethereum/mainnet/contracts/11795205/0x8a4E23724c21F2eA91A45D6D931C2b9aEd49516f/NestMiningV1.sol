// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./MiningV1Data.sol";
import "./MiningV1Calc.sol";
import "./MiningV1Op.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./ABDKMath64x64.sol";

import "./INestPool.sol";
import "./INestStaking.sol";
import "./INTokenLegacy.sol";
import "./INestMining.sol";
import "./INestDAO.sol";
// import "./console.sol";

/// @title  NestMiningV1
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>
contract NestMiningV1 {

    using SafeMath for uint256;

    using MiningV1Calc for MiningV1Data.State;
    using MiningV1Op for MiningV1Data.State;

    /* ========== STATE VARIABLES ============== */

    uint8       public  flag;  // 0:  | 1:  | 2:  | 3:
    uint64      public  version; 
    uint8       private _entrant_state; 
    uint176     private _reserved;

    MiningV1Data.State state;
    
    // NOTE: _NOT_ENTERED is set to ZERO such that it needn't constructor
    uint8 private constant _NOT_ENTERED = 0;
    uint8 private constant _ENTERED = 1;

    uint8 constant MINING_FLAG_UNINITIALIZED    = 0;
    uint8 constant MINING_FLAG_SETUP_NEEDED     = 1;
    uint8 constant MINING_FLAG_UPGRADE_NEEDED   = 2;
    uint8 constant MINING_FLAG_ACTIVE           = 3;

    /* ========== ADDRESSES ============== */

    address public  governance;
    address private C_NestPool;

    /* ========== STRUCTURES ============== */

    struct Params {
        uint8    miningEthUnit;     
        uint32   nestStakedNum1k;   
        uint8    biteFeeRate;     
        uint8    miningFeeRate;     
        uint8    priceDurationBlock; 
        uint8    maxBiteNestedLevel; 
        uint8    biteInflateFactor;
        uint8    biteNestInflateFactor;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() public { }

    function initialize(address NestPool) external 
    {
        // check flag
        require(flag == MINING_FLAG_UNINITIALIZED, "Nest:Mine:!flag");

        uint256 amount = MiningV1Data.MINING_NEST_YIELD_PER_BLOCK_BASE;
        for (uint i =0; i < 10; i++) {
            state._mining_nest_yield_per_block_amount[i] = amount;
            amount = amount.mul(MiningV1Data.MINING_NEST_YIELD_CUTBACK_RATE).div(100);
        }

        amount = MiningV1Data.MINING_NTOKEN_YIELD_PER_BLOCK_BASE;
        for (uint i =0; i < 10; i++) {
            state._mining_ntoken_yield_per_block_amount[i] = amount;
            amount = amount.mul(MiningV1Data.MINING_NTOKEN_YIELD_CUTBACK_RATE).div(100);
        }
        
        // set a temporary governance
        governance = msg.sender;

        // increase version number
        version = uint64(block.number);

        // set the address of NestPool 
        C_NestPool = NestPool;

        // set flag
        flag = MINING_FLAG_SETUP_NEEDED;
    }

    /// @dev This function can only be called once immediately right after deployment
    function setup(
            uint32   genesisBlockNumber, 
            uint128  latestMiningHeight,
            uint128  minedNestTotalAmount,
            Params calldata initParams
        ) external onlyGovernance
    {
        // check flag
        require(flag == MINING_FLAG_SETUP_NEEDED, "Nest:Mine:!flag");
        
        // set system-wide parameters
        state.miningEthUnit = initParams.miningEthUnit;
        state.nestStakedNum1k = initParams.nestStakedNum1k;
        state.biteFeeRate = initParams.biteFeeRate;    // 0.1%
        state.miningFeeRate = initParams.miningFeeRate;  // 0.1% on testnet
        state.priceDurationBlock = initParams.priceDurationBlock;  // 5 on testnet
        state.maxBiteNestedLevel = initParams.maxBiteNestedLevel;  
        state.biteInflateFactor = initParams.biteInflateFactor;   // 1 on testnet
        state.biteNestInflateFactor = initParams.biteNestInflateFactor; // 1 on testnet
        state.latestMiningHeight = latestMiningHeight;
        state.minedNestAmount = minedNestTotalAmount;
        
        // genesisBlock = 6236588 on mainnet
        state.genesisBlock = genesisBlockNumber;

        // increase version number
        version = uint64(block.number);
        
        // set flag
        flag = MINING_FLAG_UPGRADE_NEEDED;
    }

    /// @dev The function will be kicking off Nest Protocol v3.5.
    ///    After upgrading, `post/post2()` are ready to be invoked.
    ///    Before that, `post2Only4Upgrade()` is used to do posting.
    ///    The purpose is to limit post2Only4Upgrade() to run 
    function upgrade() external onlyGovernance
    {
        require(flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");

        flag = MINING_FLAG_ACTIVE;
    }

    /// @notice Write the block number as a version number
    /// @dev It shall be invoked *manually* whenever the contract is upgraded(behind proxy)
    function incVersion() external onlyGovernance
    {
        version = uint64(block.number);
    }

    receive() external payable { }

    /* ========== MODIFIERS ========== */

    function _onlyGovernance() private view 
    {
        require(msg.sender == governance, "Nest:Mine:!GOV");
    }

    modifier onlyGovernance() 
    {
        _onlyGovernance();
        _;
    }

    function _noContract() private view {
        require(address(msg.sender) == address(tx.origin), "Nest:Mine:contract!");
    }

    modifier noContract() 
    {
        _noContract();
        _;
    }

    modifier noContractExcept(address _contract) 
    {
        require(address(msg.sender) == address(tx.origin) || address(msg.sender) == _contract, "Nest:Mine:contract!");
        _;
    }

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:Mine:!sender");
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_entrant_state != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _entrant_state = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _entrant_state = _NOT_ENTERED;
    }

    modifier onlyByNestOrNoContract()
    {
        require(address(msg.sender) == address(tx.origin)
            || msg.sender == state.C_NestDAO 
            || msg.sender == state.C_NestStaking 
            || msg.sender == state.C_NNRewardPool 
            || msg.sender == state.C_NestQuery, "Nest:Mine:!Auth");
        _;
    }

    /* ========== GOVERNANCE ========== */

    /// @dev Load real governance from NestPool, invalidate the temporary 
    function loadGovernance() external
    {
        governance = INestPool(C_NestPool).governance();
    }

    function loadContracts() external onlyGovOrBy(C_NestPool)
    {
        state.C_NestPool = C_NestPool;
        state.C_NestToken = INestPool(state.C_NestPool).addrOfNestToken();
        state.C_NestStaking = INestPool(state.C_NestPool).addrOfNestStaking();
        state.C_NestQuery = INestPool(state.C_NestPool).addrOfNestQuery();
        state.C_NNRewardPool = INestPool(state.C_NestPool).addrOfNNRewardPool();
        state.C_NestDAO = INestPool(state.C_NestPool).addrOfNestDAO();
    }

    function setParams(Params calldata newParams) external 
        onlyGovernance
    {
        state.miningEthUnit = newParams.miningEthUnit;
        state.nestStakedNum1k = newParams.nestStakedNum1k;
        state.biteFeeRate = newParams.biteFeeRate;
        state.miningFeeRate = newParams.miningFeeRate;

        state.priceDurationBlock = newParams.priceDurationBlock;
        state.maxBiteNestedLevel = newParams.maxBiteNestedLevel;
        state.biteInflateFactor = newParams.biteInflateFactor;
        state.biteNestInflateFactor = newParams.biteNestInflateFactor;

        emit MiningV1Data.SetParams(state.miningEthUnit, state.nestStakedNum1k, state.biteFeeRate,
                                    state.miningFeeRate, state.priceDurationBlock, state.maxBiteNestedLevel,
                                    state.biteInflateFactor, state.biteNestInflateFactor);
    }

    /// @dev only be used when upgrading 3.0 to 3.5
    /// @dev when the upgrade is complete, this function is disabled
    function setParams1(
            uint128  latestMiningHeight,
            uint128  minedNestTotalAmount
        ) external onlyGovernance
    {
        require(flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");
        state.latestMiningHeight = latestMiningHeight;
        state.minedNestAmount = minedNestTotalAmount;
    }

    /* ========== HELPERS ========== */

    function addrOfGovernance() view external
        returns (address) 
    {   
        return governance;
    }

    function parameters() view external 
        returns (Params memory params)
    {
        params.miningEthUnit = state.miningEthUnit;
        params.nestStakedNum1k = state.nestStakedNum1k;
        params.biteFeeRate = state.biteFeeRate;
        params.miningFeeRate = state.miningFeeRate;
        params.priceDurationBlock = state.priceDurationBlock;
        params.maxBiteNestedLevel = state.maxBiteNestedLevel;
        params.biteInflateFactor = state.biteInflateFactor;
        params.biteNestInflateFactor = state.biteNestInflateFactor;
    }

    /* ========== POST/CLOSE Price Sheets ========== */

    /// @notice Post a price sheet for TOKEN
    /// @dev  It is for TOKEN (except USDT and NTOKENs) whose NTOKEN has a total supply below a threshold (e.g. 5,000,000 * 1e18)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    function post(
            address token, 
            uint256 ethNum, 
            uint256 tokenAmountPerEth
        )
        external 
        payable 
        noContract
    {
        // check parameters
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0, "Nest:Mine:!(price)");

        INestPool _C_NestPool = INestPool(state.C_NestPool);
        address _ntoken = _C_NestPool.getNTokenFromToken(token);
        require(_ntoken != address(0) &&  _ntoken != address(state.C_NestToken) && token != _ntoken, "Nest:Mine:!(ntoken)");

        // check if the totalsupply of ntoken is less than MINING_NTOKEN_NON_DUAL_POST_THRESHOLD, otherwise use post2()
        require(INToken(_ntoken).totalSupply() < MiningV1Data.MINING_NTOKEN_NON_DUAL_POST_THRESHOLD, "Nest:Mine:!ntoken");

        // calculate eth fee
        // NOTE: fee = ethAmount * (feeRate * 1/10k)
        uint256 _ethFee = ethNum.mul(state.miningFeeRate).mul(1e18).div(10_000);

        { // settle ethers and tokens

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // load addresses
            INestStaking _C_NestStaking = INestStaking(state.C_NestStaking);
            INestDAO _C_NestDAO = INestDAO(state.C_NestDAO);

            // 60% fee => NestStaking
            _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
            // 20% fee => NestDAO[NTOKEN]
            _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DAO_RATE).div(100)}(_ntoken);       
            // 20% fee => NestDAO[NEST]
            _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_NEST_DAO_RATE).div(100)}(address(state.C_NestToken));  

            // freeze eths and tokens inside NestPool
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                token, tokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeNest(msg.sender, uint256(state.nestStakedNum1k).mul(1000 * 1e18));
        }

        {
            MiningV1Data.PriceSheet[] storage _sheetToken = state.priceSheetList[token];
            // append a new price sheet
            _sheetToken.push(MiningV1Data.PriceSheet(
                uint160(msg.sender),            // miner 
                uint32(block.number),           // atHeight
                uint32(ethNum),                 // ethNum
                uint32(ethNum),                 // remainNum
                uint8(0),                       // level
                uint8(MiningV1Data.PRICESHEET_TYPE_TOKEN),   // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),    // nestNum1k
                uint128(tokenAmountPerEth)      // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 

        }

        { // mining; NTOKEN branch only
            // load mining record from `minedAtHeight`
            uint256 _minedH = state.minedAtHeight[token][block.number];
            // decode `_ntokenH` & `_ethH`
            uint256 _ntokenH = uint256(_minedH >> 128);
            uint256 _ethH = uint256(_minedH % (1 << 128));
            if (_ntokenH == 0) {  // the sheet is the first in the block
                // calculate the amount the NTOKEN to be mined
                uint256 _ntokenAmount = mineNToken(_ntoken);  
                // load `Bidder` from NTOKEN contract
                address _bidder = INToken(_ntoken).checkBidder();
                if (_bidder == state.C_NestPool) { // for new NTokens, 100% to miners
                    _ntokenH = _ntokenAmount;
                    INToken(_ntoken).mint(_ntokenAmount, address(state.C_NestPool));
                } else { // for old NTokens, 95% to miners, 5% to the bidder
                    _ntokenH = _ntokenAmount.mul(MiningV1Data.MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE).div(100);
                    INTokenLegacy(_ntoken).increaseTotal(_ntokenAmount);
                    INTokenLegacy(_ntoken).transfer(state.C_NestPool, _ntokenAmount);
                    INestPool(state.C_NestPool).addNToken(_bidder, _ntoken, _ntokenAmount.sub(_ntokenH));
                }
            }
            
            // add up `_ethH`
            _ethH = _ethH.add(ethNum);
            // store `_ntokenH` & `_ethH` into `minedAtHeight`
            state.minedAtHeight[token][block.number] = (_ntokenH * (1<< 128) + _ethH);
        }

        // calculate averge and volatility
        state._stat(token);
        return; 
    }

    /// @notice Post two price sheets for a token and its ntoken simultaneously 
    /// @dev  Support dual-posts for TOKEN/NTOKEN, (ETH, TOKEN) + (ETH, NTOKEN)
    /// @param token The address of TOKEN contract
    /// @param ethNum The numbers of ethers to post sheets
    /// @param tokenAmountPerEth The price of TOKEN
    /// @param ntokenAmountPerEth The price of NTOKEN
    function post2(
            address token, 
            uint256 ethNum, 
            uint256 tokenAmountPerEth, 
            uint256 ntokenAmountPerEth
        )
        external 
        payable 
        noContract
    {
        // check parameters 
        require(ethNum == state.miningEthUnit, "Nest:Mine:!(ethNum)");
        require(tokenAmountPerEth > 0 && ntokenAmountPerEth > 0, "Nest:Mine:!(price)");
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        require(_ntoken != token && _ntoken != address(0), "Nest:Mine:!(ntoken)");

        // calculate eth fee
        uint256 _ethFee = ethNum.mul(state.miningFeeRate).mul(1e18).div(10_000);

        { // settle ethers and tokens
            INestPool _C_NestPool = INestPool(state.C_NestPool);

            // save the changes into miner's virtual account
            if (msg.value.sub(_ethFee) > 0) {
                _C_NestPool.depositEth{value:msg.value.sub(_ethFee)}(address(msg.sender));
            }

            // load addresses
            INestStaking _C_NestStaking = INestStaking(state.C_NestStaking);
            INestDAO _C_NestDAO = INestDAO(state.C_NestDAO);

            if (_ntoken == address(state.C_NestToken)) {
                // %80 => NestStaking
                _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NEST_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
                // %20 => NestDAO
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NEST_FEE_DAO_RATE).div(100)}(_ntoken);       
            } else {
                // 60% => NestStaking
                _C_NestStaking.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DIVIDEND_RATE).div(100)}(_ntoken);       
                // 20% => NestDAO[NTOKEN]
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_DAO_RATE).div(100)}(_ntoken);       
                // 20% => NestDAO[NEST]
                _C_NestDAO.addETHReward{value:_ethFee.mul(MiningV1Data.MINING_NTOKEN_FEE_NEST_DAO_RATE).div(100)}(address(state.C_NestToken));  
            }

            // freeze assets inside NestPool
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                token, tokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeEthAndToken(msg.sender, ethNum.mul(1 ether), 
                _ntoken, ntokenAmountPerEth.mul(ethNum));
            _C_NestPool.freezeNest(msg.sender, uint256(state.nestStakedNum1k).mul(2).mul(1000 * 1e18));
        }

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
                uint8(typ1),                    // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
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
                uint8(typ2),                    // typ
                uint8(MiningV1Data.PRICESHEET_STATE_POSTED), // state 
                uint8(0),                       // _reserved
                uint32(ethNum),                 // ethNumBal
                uint32(ethNum),                 // tokenNumBal
                uint32(state.nestStakedNum1k),  // nestNum1k
                uint128(ntokenAmountPerEth)     // tokenAmountPerEth
            ));
            emit MiningV1Data.PricePosted(msg.sender, token, (_sheetToken.length - 1), ethNum.mul(1 ether), tokenAmountPerEth.mul(ethNum)); 
            emit MiningV1Data.PricePosted(msg.sender, _ntoken, (_sheetNToken.length - 1), ethNum.mul(1 ether), ntokenAmountPerEth.mul(ethNum)); 
        }

        { // mining; NEST branch & NTOKEN branch
            if (_ntoken == address(state.C_NestToken)) {
                // load mining records `minedAtHeight` in the same block 
                uint256 _minedH = state.minedAtHeight[token][block.number];
                // decode `_nestH` and `_ethH` from `minedAtHeight`
                uint256 _nestH = uint256(_minedH >> 128);
                uint256 _ethH = uint256(_minedH % (1 << 128));

                if (_nestH == 0) { // the sheet is the first in the block

                    // calculate the amount of NEST to be mined
                    uint256 _nestAmount = mineNest(); 

                    // update `latestMiningHeight`, the lastest NEST-mining block 
                    state.latestMiningHeight = uint32(block.number); 

                    // accumulate the amount of NEST
                    state.minedNestAmount += uint128(_nestAmount);

                    // 
                    _nestH = _nestAmount.mul(MiningV1Data.MINER_NEST_REWARD_PERCENTAGE).div(100); 

                    // 15% of NEST to NNRewardPool
                    INestPool(state.C_NestPool).addNest(state.C_NNRewardPool, _nestAmount.mul(MiningV1Data.NN_NEST_REWARD_PERCENTAGE).div(100));
                    INNRewardPool(state.C_NNRewardPool).addNNReward(_nestAmount.mul(MiningV1Data.NN_NEST_REWARD_PERCENTAGE).div(100));

                    // 5% of NEST to NestDAO
                    INestPool(state.C_NestPool).addNest(state.C_NestDAO, _nestAmount.mul(MiningV1Data.DAO_NEST_REWARD_PERCENTAGE).div(100));
                    INestDAO(state.C_NestDAO).addNestReward(_nestAmount.mul(MiningV1Data.DAO_NEST_REWARD_PERCENTAGE).div(100));
                }

                // add up `ethNum` into `minedAtHeight`
                _ethH = _ethH.add(ethNum);
                // encode `_nestH` and `_ethH` into `minedAtHeight`
                state.minedAtHeight[token][block.number] = (_nestH * (1<< 128) + _ethH);
            } else {
                // load mining records `minedAtHeight` in the same block 
                uint256 _minedH = state.minedAtHeight[token][block.number];
                // decode `_ntokenH` and `_ethH` from `minedAtHeight`
                uint256 _ntokenH = uint256(_minedH >> 128);
                uint256 _ethH = uint256(_minedH % (1 << 128));

                if (_ntokenH == 0) { // the sheet is the first in the block

                    // calculate the amount of NEST to be mined
                    uint256 _ntokenAmount = mineNToken(_ntoken);

                    // load `Bidder` from NTOKEN contract
                    address _bidder = INToken(_ntoken).checkBidder();

                    if (_bidder == state.C_NestPool) { // for new NTokens, 100% to miners
                        
                        // save the amount of NTOKEN to be mined
                        _ntokenH = _ntokenAmount;
                        // mint NTOKEN(new, v3.5) to NestPool
                        INToken(_ntoken).mint(_ntokenAmount, address(state.C_NestPool));

                    } else {                           // for old NTokens, 95% to miners, 5% to the bidder
                        
                        // mint NTOKEN(old, v3.0)
                        INTokenLegacy(_ntoken).increaseTotal(_ntokenAmount);
                        // transfer NTOKEN(old) to NestPool
                        INTokenLegacy(_ntoken).transfer(state.C_NestPool, _ntokenAmount);
                        // calculate the amount of NTOKEN, 95% => miner
                        _ntokenH = _ntokenAmount.mul(MiningV1Data.MINING_LEGACY_NTOKEN_MINER_REWARD_PERCENTAGE).div(100);
                        // 5% NTOKEN =>  `Bidder`
                        INestPool(state.C_NestPool).addNToken(_bidder, _ntoken, _ntokenAmount.sub(_ntokenH));
                    }
                }
                // add up `ethNum` into `minedAtHeight`
                _ethH = _ethH.add(ethNum);
                // encode `_nestH` and `_ethH` into `minedAtHeight`
                state.minedAtHeight[token][block.number] = (_ntokenH * (1<< 128) + _ethH);
            }
        }

        // calculate the average-prices and volatilities for (TOKEN. NTOKEN)

        state._stat(token);
        state._stat(_ntoken);
        return; 
    }

    /// @notice Close a price sheet of (ETH, USDx) | (ETH, NEST) | (ETH, TOKEN) | (ETH, NTOKEN)
    /// @dev Here we allow an empty price sheet (still in VERIFICATION-PERIOD) to be closed 
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function close(address token, uint256 index) 
        public 
        noContract 
    {
        // call library
        state._close(token, index);

        // calculate average-price and volatility (forward)
        state._stat(token);

    }

 
    /// @notice Close a price sheet and withdraw assets for WEB users.  
    /// @dev Contracts aren't allowed to call it.
    /// @param token The address of TOKEN contract
    /// @param index The index of the price sheet w.r.t. `token`
    function closeAndWithdraw(address token, uint256 index) 
        external 
        noContract
    {
        // call library
        state._closeAndWithdraw(token, index);
        // calculate average-price and volatility (forward)
        state._stat(token);
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param token The address of TOKEN contract
    /// @param indices A list of indices of sheets w.r.t. `token`
    function closeList(address token, uint32[] memory indices) 
        external 
        noContract
    {
        // call library
        state._closeList(token, indices);

        // calculate average-price and volatility (forward)
        state._stat(token);

    }


    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteToken(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth) 
        external 
        payable 
        noContract
    {
        // call library
        state._biteToken(token, index, biteNum, newTokenAmountPerEth);

        // calculate average-price and volatility (forward)
        state._stat(token);
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param token The address of token(ntoken)
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param biteNum The amount of bitting (in the unit of ETH), realAmount = biteNum * newTokenAmountPerEth
    /// @param newTokenAmountPerEth The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function biteEth(address token, uint256 index, uint256 biteNum, uint256 newTokenAmountPerEth)
        external
        payable
        noContract
    {
        // call library
        state._biteEth(token, index, biteNum, newTokenAmountPerEth);

        // calculate average-price and volatility (forward)
        state._stat(token);
    }


    /* ========== CALCULATION ========== */

    function stat(address _token) public 
    {
        // call library
        return state._stat(_token);
    }
    
    /* ========== PRICE QUERIES ========== */

    /// @notice Get the latest effective price for a token
    /// @dev It shouldn't be read from any contracts other than NestQuery
    function latestPriceOf(address token) 
        public
        view
        onlyByNestOrNoContract
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        MiningV1Data.PriceSheet[] storage _plist = state.priceSheetList[token];
        uint256 len = _plist.length;
        uint256 _ethNum;
        MiningV1Data.PriceSheet memory _sheet;

        if (len == 0) {
            revert("Nest:Mine:no(price)");
        }

        uint256 _first = 0;
        for (uint i = 1; i <= len; i++) {
            _sheet = _plist[len-i];
            if (_first == 0 && uint256(_sheet.height) + state.priceDurationBlock < block.number) {
                _ethNum = uint256(_sheet.remainNum);
                if (_ethNum == 0) {
                    continue;  // jump over a bitten sheet
                }
                _first = uint256(_sheet.height);
                tokenAmount = _ethNum.mul(uint256(_sheet.tokenAmountPerEth));
                ethAmount = _ethNum.mul(1 ether);
                blockNum = _first;
            } else if (_first == uint256(_sheet.height)) {
                _ethNum = uint256(_sheet.remainNum);
                tokenAmount = tokenAmount.add(_ethNum.mul(uint256(_sheet.tokenAmountPerEth)));
                ethAmount = ethAmount.add(_ethNum.mul(1 ether));
            } else if (_first > uint256(_sheet.height)) {
                break;
            }
        }
        blockNum = blockNum + uint256(state.priceDurationBlock); // safe math
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @dev It shouldn't be read from any contracts other than NestQuery
    function priceOf(address token)
        public
        view
        noContractExcept(state.C_NestQuery)
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 blockNum) 
    {
        MiningV1Data.PriceInfo memory pi = state.priceInfo[token];
        require(pi.height > 0, "Nest:Mine:NO(price)");
        ethAmount = uint256(pi.ethNum).mul(1 ether);
        tokenAmount = uint256(pi.tokenAmount);
        blockNum = uint256(pi.height + state.priceDurationBlock);
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @dev It shouldn't be read from any contracts other than NestQuery
    function priceAvgAndSigmaOf(address token) 
        public 
        view 
        onlyByNestOrNoContract
        returns (uint128 price, uint128 avgPrice, int128 vola, uint32 bn) 
    {
        MiningV1Data.PriceInfo memory pi = state.priceInfo[token];
        require(pi.height > 0, "Nest:Mine:NO(price)");
        vola = ABDKMath64x64.sqrt(ABDKMath64x64.abs(pi.volatility_sigma_sq));
        price = uint128(uint256(pi.tokenAmount).div(uint256(pi.ethNum)));
        avgPrice = pi.avgTokenAmount;
        bn = pi.height + uint32(state.priceDurationBlock);
        require(price > 0 && avgPrice > 0, "Nest:Mine:no(price)");
    }

    function priceOfTokenAtHeight(address token, uint64 atHeight)
        public 
        view 
        noContractExcept(state.C_NestQuery)
        returns(uint256 ethAmount, uint256 tokenAmount, uint256 bn) 
    {
        (ethAmount, tokenAmount, bn) = state._priceOfTokenAtHeight(token, atHeight);
        require(ethAmount > 0 && tokenAmount > 0, "Nest:Mine:no(price)");
    }

    /// @notice Return a consecutive price list for a token 
    /// @dev 
    /// @param token The address of token contract
    /// @param num   The length of price list
    function priceListOfToken(address token, uint8 num) 
        external view 
        noContractExcept(state.C_NestQuery)
        returns (uint128[] memory data, uint256 bn) 
    {
        return state._priceListOfToken(token, num);
    }

    /* ========== MINING ========== */
    
    function mineNest() public view returns (uint256) 
    {
        uint256 _period = block.number.sub(state.genesisBlock).div(MiningV1Data.MINING_NEST_YIELD_CUTBACK_PERIOD);
        uint256 _nestPerBlock;
        if (_period > 9) {
            _nestPerBlock = MiningV1Data.MINING_NEST_YIELD_OFF_PERIOD_AMOUNT;
            if (block.number > MiningV1Data.MINING_FINAL_BLOCK_NUMBER) {
                return 0;  // NEST is empty
            }
        } else {
            _nestPerBlock = state._mining_nest_yield_per_block_amount[_period];
        }
        
        return _nestPerBlock.mul(block.number.sub(state.latestMiningHeight));
    }

    function minedNestAmount() external view returns (uint256) 
    {
       return uint256(state.minedNestAmount);
    }

    function latestMinedHeight() external view returns (uint64) 
    {
       return uint64(state.latestMiningHeight);
    }

    function mineNToken(address ntoken) public view returns (uint256) 
    {
        (uint256 _genesis, uint256 _last) = INToken(ntoken).checkBlockInfo();

        uint256 _period = block.number.sub(_genesis).div(MiningV1Data.MINING_NEST_YIELD_CUTBACK_PERIOD);
        uint256 _ntokenPerBlock;
        if (_period > 9) {
            _ntokenPerBlock = MiningV1Data.MINING_NTOKEN_YIELD_OFF_PERIOD_AMOUNT;
        } else {
            _ntokenPerBlock = state._mining_ntoken_yield_per_block_amount[_period];
        }
        uint256 _interval = block.number.sub(_last);
        if (_interval > MiningV1Data.MINING_NTOKEN_YIELD_BLOCK_LIMIT) {
            _interval = MiningV1Data.MINING_NTOKEN_YIELD_BLOCK_LIMIT;
        }

        // NOTE: no NTOKEN rewards if the mining interval is greater than a pre-defined number
        uint256 yieldAmount = _ntokenPerBlock.mul(_interval);
        return yieldAmount;
    }

    /* ========== WITHDRAW ========== */

    function withdrawEth(uint256 ethAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEth(address(msg.sender), ethAmount); 
    }

    function withdrawEthAndToken(uint256 ethAmount, address token, uint256 tokenAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEthAndToken(address(msg.sender), ethAmount, token, tokenAmount); 
    }

    function withdrawNest(uint256 nestAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawNest(address(msg.sender), nestAmount); 
    }

    function withdrawEthAndTokenAndNest(uint256 ethAmount, address token, uint256 tokenAmount, uint256 nestAmount) 
        external nonReentrant
    {
        INestPool(state.C_NestPool).withdrawEthAndToken(address(msg.sender), ethAmount, token, tokenAmount); 
        INestPool(state.C_NestPool).withdrawNest(address(msg.sender), nestAmount);
    }

    /* ========== VIEWS ========== */

    function lengthOfPriceSheets(address token) 
        view 
        external 
        returns (uint256)
    {
        return state.priceSheetList[token].length;
    }

    function priceSheet(address token, uint256 index) 
        view external 
        returns (MiningV1Data.PriceSheetPub memory sheet) 
    {
        return state._priceSheet(token, index); 
    }

    function fullPriceSheet(address token, uint256 index) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheet memory sheet) 
    {
        uint256 len = state.priceSheetList[token].length;
        require (index < len, "Nest:Mine:>(len)");
        return state.priceSheetList[token][index];
    }

    function unVerifiedSheetList(address token)
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.unVerifiedSheetList(token);
    }

    function unClosedSheetListOf(address miner, address token, uint256 fromIndex, uint256 num) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.unClosedSheetListOf(miner, token, fromIndex, num);
    }

    function sheetListOf(address miner, address token, uint256 fromIndex, uint256 num) 
        view 
        public
        noContract
        returns (MiningV1Data.PriceSheetPub2[] memory sheets) 
    {
        return state.sheetListOf(miner, token, fromIndex, num);
    }

    /*
     /// @dev The function will be disabled when the upgrading is completed
    /// TODO: (TBD) auth needed? 
    function post2Only4Upgrade(
            address token,
            uint256 ethNum,
            uint256 tokenAmountPerEth,
            uint256 ntokenAmountPerEth
        )
        external 
        noContract
    {
       // only avialble in upgrade phase
        require (flag == MINING_FLAG_UPGRADE_NEEDED, "Nest:Mine:!flag");
        state._post2Only4Upgrade(token, ethNum, tokenAmountPerEth, ntokenAmountPerEth);
        address _ntoken = INestPool(state.C_NestPool).getNTokenFromToken(token);

        // calculate average price and volatility
        state._stat(token);
        state._stat(_ntoken);
    }
    */
}