// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./ReentrancyGuard.sol";

import "./INestPool.sol";
import "./INestStaking.sol";
import "./INToken.sol";
import "./INestQuery.sol";
import "./INestMining.sol";
import "./INestDAO.sol";

/// @title NestQuery
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>
contract NestQuery is INestQuery, ReentrancyGuard {

    using SafeMath for uint256;

    /* ========== STATE ============== */

    /// @notice The flag is the running status of NestQuery contract
    /// @dev The flag is in {0, 1, 2}
    /// @return The value of flag
    uint8   public flag;
    uint248 private _reserved;

    // flag == 0: the contract needs initialization
    // flag == 1: the contract is active after initialization
    // flag == 2: the contract is shutdown, user interfaces like query() are closed,
    //              while the governor has privileges to rescue
    uint8  constant QUERY_FLAG_UNINITIALIZED = 0;
    uint8  constant QUERY_FLAG_ACTIVE        = 1;
    uint8  constant QUERY_FLAG_PAUSED        = 2;

    struct Client {
        uint64 startTime;
        uint64 endTime;  // endTime==0 for non-monthly clients
        uint32 fee;
        uint32 typ;     // =1: PPQ | =2: PPM (forbidden for the moment)
        uint64 _reserved;
    }

    /// @dev Here we only support pay-per-query clients. 
    ///     The other type (pay-per-month) isn't supported currently.
    uint32 constant CLIENT_TYPE_PAY_PER_QUERY = 1;
    // uint32 constant CLIENT_TYPE_PAY_PER_MONTH = 2;

    mapping(address => uint256) public clientList;
    mapping(address => address) public clientOp;

    /* ========== PARAMETERS ============== */

    /// @dev The four paramters are encoded into a uin256 slot to save GAS. Currently only four
    ///        uint32 pieces are used, leaving sufficient spaces for later upgrading.
    struct Params {
        uint32 singleFeeEthTWei;            // Twei = 1e12
        uint32 activationTime;              // second
        uint32 activationFeeNestNum;        // 1 NEST = 1e18
        uint32 _reserved2;
    }

    uint256 private paramsEncoded;

    /// @dev The default values of parameters. They shall be setup via `setParams()` before 
    ///     the contract starts to rotates.
    uint32  constant CLIENT_QUERY_FEE_ETH_TWEI = (0.01 ether) / 1e12;
    uint32  constant CLIENT_ACTIVATION_NEST_AMOUNT = 0;
    uint32  constant CLIENT_MONTHLY_FEE_NEST_AMOUNT = 0;
    uint32  constant CLIENT_ACTIVATION_DURATION_SECOND = 10;

    /* ========== ADDRESSES ============== */

    /// @dev The contract variables for other contracts' addresses, loaded from NestPool
    address    private C_NestToken;
    address    private C_NestMining;
    address    private C_NestPool;
    address    private C_NestStaking;
    address    private C_NestDAO;

    /// @dev The governor's address, which is loaded from NestPool.
    address public governance;

    /* ========== CONSTRUCTOR ============== */

    receive() external payable { }

    // NOTE: to support open-zeppelin/upgrades, leave it blank
    constructor() public { }

    /// @dev It is supposedly called by the proxy (open-zeppelin/upgrades), only ONCE!
    function initialize(address NestPool) external 
    { 
        require(flag == QUERY_FLAG_UNINITIALIZED, "Nest:Qury:!flag");
        governance = address(msg.sender); 
        C_NestPool = NestPool;
        uint32 _actFee = CLIENT_ACTIVATION_NEST_AMOUNT;
        uint32 _singleFee = CLIENT_QUERY_FEE_ETH_TWEI;
        uint32 _actTime = CLIENT_ACTIVATION_DURATION_SECOND;
        paramsEncoded = encode_4x32_256(_singleFee, _actTime, _actFee, 0);
        flag = QUERY_FLAG_ACTIVE;
    }

    /* ========== MODIFIERS ========== */

    modifier whenActive() 
    {
        require(flag == QUERY_FLAG_ACTIVE, "Nest:Qury:!flag");
        _;
    }

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:Qury:!governance");
        _;
    }

    modifier onlyGovOrBy(address _account)
    {
        if (msg.sender != governance) { 
            require(msg.sender == _account,
                "Nest:Qury:!Auth");
        }
        _;
    }
    
    /*
    modifier onlyBy(address _contract)
    {
        require(msg.sender == _contract, "Nest:Qury:!Auth");
        _;
    }*/

    modifier noContract() 
    {
        require(address(msg.sender) == address(tx.origin), "Nest:Qury:BAN(contract)");
        _;
    }

     /* ========== GOVERNANCE ========== */

    /// @dev To ensure that all of governance-addresses be consist with each other, every contract
    ///        besides NestPool must load newest `governance` from NestPool.
    function loadGovernance() override external 
    { 
        governance = INestPool(C_NestPool).governance();
    }

    /// @notice Setup the parameters for queryings, one price for all token
    /// @dev    Parameters can be reset by set time to zero
    function setParams(uint256 single, uint32 time, uint256 nestAmount) 
        public 
        onlyGovernance
    {
        (uint32 _singleFee, uint32 _time, uint32 _actFee, uint32 _res) =  decode_4x32_256(paramsEncoded);

        _singleFee = uint32(single);
        _time = uint32(time);
        _actFee = uint32(nestAmount / 1e18);
    
        uint256 oldParamsEncoded = paramsEncoded;

        paramsEncoded = encode_4x32_256(_singleFee, _time, _actFee, _res);

        emit ParamsSetup(address(msg.sender), oldParamsEncoded, paramsEncoded);
    }

    function params() external view 
        returns(uint256 single, uint64 leadTime, uint256 nestAmount) 
    {
        (uint32 _singleFee, uint32 _time, uint32 _actFee, uint32 _res) =  decode_4x32_256(paramsEncoded);
        single = uint256(_singleFee).mul(1e12);
        leadTime = uint64(_time);
        nestAmount = uint256(_actFee).mul(1e18);

    }

    function loadContracts() override external onlyGovOrBy(C_NestPool)
    {
        C_NestToken = INestPool(C_NestPool).addrOfNestToken();
        C_NestMining = INestPool(C_NestPool).addrOfNestMining();
        C_NestStaking = INestPool(C_NestPool).addrOfNestStaking();
        C_NestDAO = INestPool(C_NestPool).addrOfNestDAO();
    }

    /// @dev Remove a client if something goes wrong
    /// @param defi The address of a client (defi DApp)
    function remove(address defi) 
        external 
        onlyGovernance
    {
        clientList[defi] = encodeClient(0, 0, 0, 0);
        clientOp[defi] = address(0);
    }

    // /// @dev  The balance of NEST
    // /// @return  The amount of NEST tokens for this contract
    // function balanceNest() override external view returns (uint256) 
    // {
    //     return ERC20(C_NestToken).balanceOf(address(this));
    // }

    // /// @dev  The balance of NEST
    // /// @return  The amount of ethers withheld by this contract
    // function balanceEth() override external view returns (uint256) 
    // {
    //     return address(this).balance;
    // }

    /* ========== EMERGENCY ========== */

    /// @dev Stop service for emergency
    function pause() external onlyGovernance
    {
        require(flag == QUERY_FLAG_ACTIVE, "Nest:Qury:!flag");

        flag = QUERY_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(QUERY_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() external onlyGovernance
    {
        require(flag == QUERY_FLAG_PAUSED, "Nest:Qury:!flag");

        flag = QUERY_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(QUERY_FLAG_ACTIVE));
    }

    /* ========== CLIENT ========== */

    /// @notice Activate a pay-per-query defi client with NEST tokens
    /// @dev No contract is allowed to call it
    /// @param defi The addres of client (DeFi DApp)
    function activate(address defi) 
        override external noContract whenActive
    {
        if (defi == address(0)) {
            defi = address(msg.sender);
        }
        Client memory _c = decodeClient(clientList[defi]);
        require (_c.typ == 0, "Nest:Qury:EX(client)");
        (, uint32 _actTime, uint256 _actFee, ) = decode_4x32_256(paramsEncoded);          
        uint256 _nestFee = _actFee.mul(1e18);
        uint256 _start = uint64(block.timestamp.add(_actTime));
        uint256 _end = 0;
        uint256 _mfee = 0;
        clientList[defi] = encodeClient(uint64(_start), uint64(_end), uint32(_mfee), 0x1);
        clientOp[defi] = address(msg.sender);
        emit ClientActivated(defi, _start, _end);
        require(ERC20(C_NestToken).transferFrom(
            address(msg.sender), 
            address(C_NestDAO), 
            _nestFee), "Nest:Qury:!transfer");
    }

    /// @notice Deactivate a pay-per-query defi client
    /// @param defi The address of a client (DeFi DApp)
    function deactivate(address defi) 
        override 
        external 
        whenActive
    {
        if (defi == address(0)) {
            defi = address(msg.sender);
        }
        require(address(msg.sender) == clientOp[defi], "Nest:Qury:!Op");
        clientList[defi] = encodeClient(0, 0, 0, 0);
        clientOp[defi] = address(0);
    }

    /// @notice Query for PPQ (pay-per-query) clients
    /// @dev Consider that if a user call a DeFi that queries NestQuery, DeFi should
    ///     pass the user's wallet address to query() as `payback`.
    /// @param token The address of token contract
    /// @param payback The address of change
    function query(address token, address payback) 
        override 
        public 
        payable 
        whenActive
        nonReentrant
        returns (uint256, uint256, uint256) 
    {
        // check parameters
        Client memory c = decodeClient(clientList[address(msg.sender)]);
        require(c.typ == CLIENT_TYPE_PAY_PER_QUERY, "Nest:Qury:=!(client.typ)");
        require(c.startTime != 0 && uint256(c.startTime) < block.timestamp 
            && uint256(c.endTime) == 0, "Nest:Qury:!(client.time)");

        // lookup the latest effective price
        (uint256 ethAmount, uint256 tokenAmount, uint256 bn) = INestMining(C_NestMining).latestPriceOf(token);
        (uint256 _single, , , ) = decode_4x32_256(paramsEncoded);  

        {
            address _ntoken = INestPool(C_NestPool).getNTokenFromToken(token); 
            uint256 _ethFee = _single.mul(1e12);   // NOTE: the unit of _single is TWei
            INestDAO(C_NestDAO).addETHReward{value:_ethFee}(address(_ntoken));

            // return change
            if (payback != address(0) && msg.value > _ethFee) {
                TransferHelper.safeTransferETH(payback, msg.value.sub(_ethFee));
            }
        }
    
        emit PriceQueried(address(msg.sender), token, ethAmount, tokenAmount, bn);
        return (ethAmount, tokenAmount, uint256(bn));
    }

    /// @notice Query for PPQ (pay-per-query) clients
    /// @param token The address of token contract
    /// @param payback The address of change
    /// @return ethAmount The amount of ETH in pair (ETH, TOKEN)
    /// @return tokenAmount The amount of TOKEN in pair (ETH, TOKEN)
    /// @return avgPrice The average of last 50 prices 
    /// @return vola The volatility of prices 
    /// @return bn The block number when (ETH, TOKEN) takes into effective
    function queryPriceAvgVola(address token, address payback)
        override 
        external 
        payable 
        whenActive
        nonReentrant
        returns (uint256 ethAmount, uint256 tokenAmount, uint128 avgPrice, int128 vola, uint256 bn) 
    {
        // check parameters
        Client memory c = decodeClient(clientList[address(msg.sender)]);
        require (c.typ == CLIENT_TYPE_PAY_PER_QUERY, "Nest:Qury:=!(client.typ)");
        require(c.startTime != 0 && uint256(c.startTime) < block.timestamp 
            && uint256(c.endTime) == 0, "Nest:Qury:!(client.time)");

        (ethAmount, tokenAmount, bn) = INestMining(C_NestMining).latestPriceOf(token);
        (, avgPrice, vola,) = INestMining(C_NestMining).priceAvgAndSigmaOf(token);

        {
            (uint256 _single, , , ) = decode_4x32_256(paramsEncoded);  
            address _ntoken = INestPool(C_NestPool).getNTokenFromToken(token); 
            uint256 _ethFee = _single.mul(1e12);   // NOTE: the unit of _single is TWei
            INestDAO(C_NestDAO).addETHReward{value:_ethFee}(address(_ntoken));

            // charge back
            if (payback != address(0) && msg.value > _ethFee) {
                TransferHelper.safeTransferETH(payback, msg.value.sub(_ethFee));
            }
        }
        emit PriceAvgVolaQueried(address(msg.sender), token, bn, avgPrice, vola);

    }
    
    /// @notice The main function called by DeFi clients, compatible to Nest Protocol v3.0 
    /// @dev  The payback address is ZERO, so the changes are kept in this contract
    ///         The ABI keeps consist with Nest v3.0
    /// @param tokenAddress The address of token contract address
    /// @return ethAmount The amount of ETH in price pair (ETH, ERC20)
    /// @return erc20Amount The amount of ERC20 in price pair (ETH, ERC20)
    /// @return blockNum The block.number where the price is being in effect
    function updateAndCheckPriceNow(
            address tokenAddress
        ) 
        override
        public 
        payable 
        whenActive
        returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum) 
    {
        return query(tokenAddress, address(msg.sender));
    }

    /// @notice A non-free function for querying price 
    /// @param token  The address of the token contract
    /// @param num    The number of price sheets in the list
    /// @param payback The address for change
    /// @return The array of prices, each of which is (blockNnumber, ethAmount, tokenAmount)
    function queryPriceList(address token, uint8 num, address payback) 
        override public payable 
        whenActive
        returns (uint128[] memory) 
    {
        // check client 
        Client memory c = decodeClient(clientList[address(msg.sender)]);
        require(c.typ == CLIENT_TYPE_PAY_PER_QUERY, "Nest:Qury:=!(client.typ)");
        require(c.startTime != 0 && uint256(c.startTime) < block.timestamp 
            && uint256(c.endTime) == 0, "Nest:Qury:!(client.time)");

        // retrieve the historical price list
        (uint128[] memory data, uint256 bn) = INestMining(C_NestMining).priceListOfToken(token, num);
        // require(miner != address(0x0), "miner null");

        // get the associated NTOKEN with token
        address _ntoken = INestPool(C_NestPool).getNTokenFromToken(token); 

        // calculate the fee rate 
        (uint256 _single, , , ) = decode_4x32_256(paramsEncoded);  
        uint256 _ethFee = _single.mul(1e12);  // NOTE: the unit of _single is TWei

        // transfer fee into NestDAO
        INestDAO(C_NestDAO).addETHReward{value:_ethFee}(address(_ntoken));

        // pay back the change
        if (payback != address(0) && msg.value > _ethFee) {
                TransferHelper.safeTransferETH(payback, msg.value.sub(_ethFee));
        }

        // notify client 
        emit PriceListQueried(address(msg.sender), token, bn, num);
        
        return data;
    }

    /// @notice A view function returning the historical price list from the current block
    /// @param token  The address of the token contract
    /// @param num    The number of price sheets in the list
    /// @return The array of prices, each of which is (blockNnumber, ethAmount, tokenAmount)
    function priceList(address token, uint8 num) 
        override public view 
        whenActive
        noContract
        returns (uint128[] memory) 
    {

        // retrieve the historical price list
        (uint128[] memory data, uint256 bn) = INestMining(C_NestMining).priceListOfToken(token, num);

        // // get the associated NTOKEN with token
        // address _ntoken = INestPool(C_NestPool).getNTokenFromToken(token); 
        
        return data;
    }
    
    function latestPrice(address token)
        override 
        public 
        view 
        whenActive
        noContract
        returns (uint256 ethAmount, uint256 tokenAmount, uint128 avgPrice, int128 vola, uint256 bn) 
    {
        (ethAmount, tokenAmount, bn) = INestMining(C_NestMining).latestPriceOf(token);
        (, avgPrice, vola,) = INestMining(C_NestMining).priceAvgAndSigmaOf(token);

    }
  
    /* ========== INTER-CALLS ========== */

    // /// @dev Withdraw NEST only when emergency or governance
    // /// @param to  The address of recipient
    // /// @param amount  The amount of NEST tokens 
    // function withdrawNest(uint256 amount) 
    //     override external onlyBy(C_NestDAO)
    // {
    //     ERC20(C_NestToken).transfer(address(msg.sender), amount);
    // }

    // /// @dev Withdraw ethers only when emergency or governance
    // /// @param to  The address of recipient
    // /// @param amount  The amount of ethers 
    // function withdrawEth(uint256 amount) 
    //     override external onlyBy(C_NestDAO)
    // {
    //    TransferHelper.safeTransferETH(address(msg.sender), amount);
    // }

     /* ========== HELPERS ========== */

    /// @dev For saving GAS
    function encode_4x32_256(uint32 p1, uint32 p2, uint32 p3, uint32 p4) 
        internal 
        pure 
        returns (uint256 enc) 
    {
        assembly {
            mstore(0x20, p1)
            mstore(0x18, p2)
            mstore(0x10, p3)
            mstore(0x8, p4)
            enc := mload(0x20)
        }
    }

    /// @dev For saving GAS
    function decode_4x32_256(uint256 enc) 
        internal 
        pure 
        returns (uint32 p1, uint32 p2, uint32 p3, uint32 p4) 
    {
        assembly {
            p1 := enc
            mstore(0x18, enc)
            p4 := mload(0)
            mstore(0x10, enc)
            p3 := mload(0)
            mstore(0x8, enc)
            p2 := mload(0)
        }
    }

    /// @dev For saving GAS
    function encodeClient(uint64 _start, uint64 _end, uint32 _fee, uint32 _typ) 
        internal pure returns (uint256 enc) 
    {
        assembly {
            let y := 0
            mstore(0x20, 0)
            mstore(0x18, _typ)
            mstore(0x14, _fee)
            mstore(0x10, _end)
            mstore(0x8, _start)
            enc := mload(0x20)
        }
    }

    
    /// @dev For saving GAS
    function decodeClient(uint256 enc) 
        internal pure returns (Client memory client) 
    {
        uint32 _typ;
        uint32 _fee;
        uint64 _start;
        uint64 _end;
        assembly {
            mstore(0x18, enc)
            _start := mload(0)
            mstore(0x10, enc)
            _end := mload(0)
            mstore(0xc, enc)
            _fee := mload(0)
            mstore(0x8, enc)
            _typ := mload(0)
        }
        client = Client(_start, _end, _fee, _typ, 0);
    }
}
