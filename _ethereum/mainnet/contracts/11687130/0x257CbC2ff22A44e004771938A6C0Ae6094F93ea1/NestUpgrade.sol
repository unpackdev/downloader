// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./INestPool.sol";
import "./INestDAO.sol";
import "./INestMining.sol";
import "./INestQuery.sol";
import "./INestStaking.sol";
import "./INNRewardPool.sol";
import "./INTokenController.sol";

import "./INest_3_Abonus.sol";
import "./INest_3_Leveling.sol";
import "./INest_3_MiningContract.sol";
import "./INest_NToken_TokenAuction.sol";
import "./INest_NToken_TokenMapping.sol";

// import "./console.sol";

/*
    steps:

    Attention: no new quote pairs are allowed when executing upgrade contracts !!!
    
    //==================== set params ====================//
   
    1. nest3Admin: Set nest3Admin address to NestUpgrade.address

    2. nest3.5: gov: NestPool.setGovernance(NestUpgrade.address)

    3. nest3.5: NestUpgrade.setPairsOfTokens(..., tokanL), can be run multiple times, 
      all token-ntoken settings must be completed before proceeding to the next step, 
      USDT-NEST included. tokenL[i] != USDT.address

    4. nest3.5: NestUpgrade.SetupParamsOfNestMining(...), this function can only be 
      executed once

    //========================================================//
    
    
    Attention: nest 3 stops running when funds are transferred !!!!
    //===================== transfer funds ===================//
    
    5. nest3.5: gov: NestPool.setGovernance(NestUpgrade.address)
    
    6. nest3.5: NestUpgrade.transferNestFromNest3(), transfer NEST(umined) to NestPool
       if failed: 
            all right, no funds are transferred to the new contract at this time;
       if succeeded: 
            go to next step;

    7. nest3.5: gov: NestPool.setGovernance(NestUpgrade.address)

    8. nest3.5: NestUpgrade.transferETHFromNest3(...), transfer ETH to address(this), 
       can be run multiple times, each tokens should be applied once, USDT must be included 
       if falied: 
            run NestUpgrade.transferNestInUrgent() to revert
       if succeeded: 
            go to next step

    9. nest3.5: NestUpgrade.transferETHToNestDAO(...), transfer ETH to NestDAO.addr, 
        if failed: can run NestUpgrade.transferETH()
        if succeeded: next step

    10. nest3.5: NestUpgrade.initNest35(), NestMining.upgrade() / NestDAO.start()
        if failed: NestDAO.migrateTo(...), transfer eth to new DAO
        if succeeded: end
*/

contract NestUpgrade {

    using SafeMath for uint256;

    address public governance;

    address public C_NestToken;
    address public C_NestPool;
    address public C_NestMining;
    address public C_NestDAO;

    uint8 public flag;

    uint256 public latestHeight;
    uint256 public nestBal;
    uint256 public minedNestAmount;
    uint256 public nest;
    uint256 public tokenNum;         // Nest_NToken_TokenAuction.checkTokenNum()

    uint256 public ntoken_num1 = 0;  // record how many pairs of tokens have been set
                                     // finally,the value should be equal to  
                                     // Nest_NToken_TokenAuction.checkTokenNum()

    uint256 public ntoken_num2 = 0;  // record the number of tokens for which funds have been transferred

    uint256 constant total_nest = 10_000_000_000;  // total nest == 10 billion

    mapping(address => address) _token_ntoken_mapping;

    receive() external payable {}

    modifier onlyGovernance()
    {
        require(msg.sender == governance, "Nest:Upg:!gov");
        _;
    }

    constructor(address NestPool) public 
    {
        governance = msg.sender;
        C_NestPool = NestPool;
        flag = 0;
    }
    
    function shutdown() public onlyGovernance
    {
        flag = 2;
    }

    function resume() public onlyGovernance
    {
        flag = 0;
    }

    /// @notice Upgrade from Nest v3.0 to v3.5
    /// @dev setNtokenToToken(token, ntoken)
    ///   If the number of ntokens is too large 
    ///   and gas consumption exceeds the limit,
    ///   you can execute setPairsOfTokens() multiple times.
    ///   open new ntoken in nest3 should not be allowed.
    function setPairsOfTokens(
            address usdtToken,
            address Nest_NToken_TokenMapping, 
            address[] memory tokenL) public onlyGovernance
    {
        address[] memory ntokenL = new address[](tokenL.length);

        require(flag < 2, "Nest:Upg:!flag");
        require(tokenL.length == ntokenL.length, "Ntoken:Upg:!len");

        for(uint i=0; i<tokenL.length; i++)
        {
            require(tokenL[i] != usdtToken, "Token:Upg:!USDT");
            ntokenL[i] = INest_NToken_TokenMapping(Nest_NToken_TokenMapping).checkTokenMapping(tokenL[i]);
            require(ntokenL[i] != address(0), "Ntoken:Upg:!addr");
        }

        INestPool _C_NestPool = INestPool(C_NestPool);
        C_NestToken = _C_NestPool.addrOfNestToken();

        if(_C_NestPool.getNTokenFromToken(usdtToken) == address(0))
        {
            _C_NestPool.setNTokenToToken(usdtToken, C_NestToken);
            ntoken_num1 += 1; 
        }

        for (uint i = 0; i < tokenL.length; i++) 
        {
            require(ntokenL[i] != C_NestToken, "Ntoken:Upg: !nest");
            if(_C_NestPool.getNTokenFromToken(tokenL[i]) == address(0))
            {
                _C_NestPool.setNTokenToToken(tokenL[i], ntokenL[i]);
                ntoken_num1 += 1;
            }
        }

        return;
    }

    /// @notice Set up params about NestMining
    /// @dev This function can only be executed once
    function setupParamsOfNestMining(
            address Nest_3_MiningContract,
            address Nest_NToken_TokenAuction,
            address Nest_NToken_TokenMapping, 
            INestMining.Params memory params
            ) public onlyGovernance
    {
        uint32 genesisBlockNumber = 6236588;
        uint256 latestMiningHeight;
        uint256 nestBalance;
        uint256 minedNestTotalAmount;

        require(flag < 2, "Nest:Upg:!flag");

        tokenNum = INest_NToken_TokenAuction(Nest_NToken_TokenAuction).checkTokenNum();
        require(tokenNum == ntoken_num1, "ntoken_num1:Upg: !sufficient");

        latestMiningHeight = INest_3_MiningContract(Nest_3_MiningContract).checkLatestMining();
        
        nestBalance = INest_3_MiningContract(Nest_3_MiningContract).checkNestBalance();
       
        minedNestTotalAmount = uint256(total_nest).mul(1e18).sub(nestBalance);

        INestPool _C_NestPool = INestPool(C_NestPool);
        C_NestMining = _C_NestPool.addrOfNestMining();
      
        INestMining(C_NestMining).loadGovernance();
      
        INestMining(C_NestMining).setup(genesisBlockNumber, uint128(latestMiningHeight), uint128(minedNestTotalAmount), params);

        _C_NestPool.setGovernance(governance);

        INestMining(C_NestMining).loadGovernance();
        
        return;
    }


    /// @dev Transfer nest from nest3 to nest3.5
    /// @param Nest_3_MiningContract Address of Nest_3_MiningContract
    function transferNestFromNest3(address Nest_3_MiningContract) public onlyGovernance
    {
        require(flag < 2, "Nest:Upg:!flag");
        INestPool _C_NestPool = INestPool(C_NestPool);
        C_NestToken = _C_NestPool.addrOfNestToken();

        C_NestMining = _C_NestPool.addrOfNestMining();

        // set latestMiningHeight and minedNestTotalAmount
    
        latestHeight = INest_3_MiningContract(Nest_3_MiningContract).checkLatestMining();
        
        nestBal = INest_3_MiningContract(Nest_3_MiningContract).checkNestBalance();
       
        minedNestAmount = uint256(total_nest).mul(1e18).sub(nestBal);

        require(latestHeight > 0, "LatestHeight:Upg: err");

        INestMining(C_NestMining).setParams1(uint128(latestHeight), uint128(minedNestAmount));

        // send nest to nestpool.addr
        INest_3_MiningContract(Nest_3_MiningContract).takeOutNest(C_NestPool);
        nest = ERC20(C_NestToken).balanceOf(C_NestPool);
        _C_NestPool.initNestLedger(nest);
 
        _C_NestPool.setGovernance(governance);

        INestMining(C_NestMining).loadGovernance();

        return;
    }

    /// @notice Transfer NEST from nest3 to nest3.5
    /// @param Nest_3_MiningContract Address of Nest_3_MiningContract
    /// @param Nest_NToken_TokenAuction Address of Nest_NToken_TokenAuction
    /// @param Nest_3_Abonus Address of Nest_NToken_TokenMapping
    /// @param Nest_3_Leveling Address of Nest_NToken_TokenMapping
    /// @param tokenL Lists of tokens addresses, usdt included
    /// @dev This function could be executed many times
    function transferETHFromNest3(
            address Nest_3_MiningContract,
            address Nest_NToken_TokenAuction,
            address Nest_3_Abonus,
            address Nest_3_Leveling,
            address[] memory tokenL
            ) public onlyGovernance
    {
        address[] memory ntokenL = new address[](tokenL.length);

        require(flag < 2, "Nest:Upg:!flag");
        INestPool _C_NestPool = INestPool(C_NestPool);
        C_NestToken = _C_NestPool.addrOfNestToken();

        C_NestMining = _C_NestPool.addrOfNestMining();
        C_NestDAO = _C_NestPool.addrOfNestDAO();
        
        INestMining(C_NestMining).loadGovernance();

        INestDAO(C_NestDAO).loadGovernance();

        
        for(uint i=0; i<tokenL.length; i++){
            ntokenL[i] = _C_NestPool.getNTokenFromToken(tokenL[i]);

            require(ntokenL[i] != address(0), "Ntoken:Upg: err");
        }

        require(tokenL.length == ntokenL.length, "Ntoken:Upg:!len");
  
        for(uint i=0; i < ntokenL.length; i++)
        {
            if(_token_ntoken_mapping[tokenL[i]] == address(0))
            {
                uint256 amount = 0;
                uint256 amount_bonus = 0;
                uint256 amount_leveling = 0;

                amount_bonus = INest_3_Abonus(Nest_3_Abonus).getETHNum(ntokenL[i]);

                if(amount_bonus > 0)
                {
                    INest_3_Abonus(Nest_3_Abonus).turnOutAllEth(amount_bonus, address(this));
                }

                amount_leveling = INest_3_Leveling(Nest_3_Leveling).checkEthMapping(ntokenL[i]);

                if(amount_leveling > 0)
                {
                    INest_3_Leveling(Nest_3_Leveling).turnOutAllEth(amount_leveling, address(this));    
                }

                amount = amount_bonus.add(amount_leveling);

                if(amount > 0)
                {
                    INestDAO(C_NestDAO).initEthLedger(ntokenL[i], amount);
                }

                _token_ntoken_mapping[tokenL[i]] = ntokenL[i];

                ntoken_num2 += 1; 

            }
        }

        return;
    }

    /// @notice Transfer ETH to NestDAO
    /// @param NestDAO Address of NestDAO contract
    /// @param Nest_NToken_TokenAuction Address of Nest_NToken_TokenAuction
    /// @dev All ETH(ntoken) must be transfered to address(this) 
    function transferETHToNestDAO(address NestDAO, address Nest_NToken_TokenAuction)
        public onlyGovernance
    {
        tokenNum = INest_NToken_TokenAuction(Nest_NToken_TokenAuction).checkTokenNum();
        require(tokenNum == ntoken_num2, "ntoken_num2:Upg: !sufficient");

        (bool success, ) = NestDAO.call{value: address(this).balance}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');

    }

    /// @dev Initialize nest3.5, NestMining.upgrade() / NestDAO.start()
    /// @dev This function can only be executed once
    /// @dev New ntoken not turned on at this time, set ntokenCounter by C_NTokenController.start(...)
    function switchOnNest35() public onlyGovernance
    {
        require(flag < 2, "Nest:Upg:!flag");
        INestPool _C_NestPool = INestPool(C_NestPool);
        C_NestToken = _C_NestPool.addrOfNestToken();

        C_NestMining = _C_NestPool.addrOfNestMining();
        C_NestDAO = _C_NestPool.addrOfNestDAO();
        
        INestMining(C_NestMining).loadGovernance();

        INestDAO(C_NestDAO).loadGovernance();
          
        // start nest3.5
        
        INestMining(C_NestMining).upgrade();

        INestDAO(C_NestDAO).loadContracts();

        _C_NestPool.setGovernance(governance);

        INestMining(C_NestMining).loadGovernance();
        INestDAO(C_NestDAO).loadGovernance();

        return;
    }


    //================== urgent, if deployment failed ================//
    
    /// @dev If the upgrading failed, transfer ETH to an temporary address
    function transferETH(address to) public onlyGovernance
    {
        (bool success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    /// @dev if the upgrading failed, withdraw nest from nestpool
    /// @param to Address where you want to transfer
    /// @param amount NEST amount
    /// @param upgrade Address of NestUpgrade
    function transferNestInUrgent(address to, uint256 amount, address upgrade) 
        public onlyGovernance 
    {
        require(flag < 2, "Nest:Upg:!flag");
        INestPool _C_NestPool = INestPool(C_NestPool);
        _C_NestPool.drainNest(to, amount, upgrade);
    }

    ///@dev set NestPool gov
    /// NestPool.setGovernance(NestUpgrade.address) at first
    function setGov() public onlyGovernance
    {
        INestPool _C_NestPool = INestPool(C_NestPool);
        
        _C_NestPool.setGovernance(governance);

        C_NestMining = _C_NestPool.addrOfNestMining();

        C_NestDAO = _C_NestPool.addrOfNestDAO();
        
        INestMining(C_NestMining).loadGovernance();

        INestDAO(C_NestDAO).loadGovernance();
    }

}