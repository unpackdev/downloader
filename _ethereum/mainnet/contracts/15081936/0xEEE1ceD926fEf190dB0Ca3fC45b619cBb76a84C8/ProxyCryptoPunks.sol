// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports
import "./Ownable.sol";
import "./Counters.sol";

// interfaces
import "./IProxyNFTStation.sol";
import "./ILucksHelper.sol";
import "./IPunks.sol";

contract ProxyCryptoPunks is IProxyNFTStation, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _depositIds;

    // ============ Public  ============    

    ILucksHelper public HELPER;

    // OpenLuck executors
    mapping(address => bool) public executors;

    // store user deposited nfts, support multiple executors (executor-address => depositId => NFT)    
    mapping(address => mapping(uint256 => DepositNFT)) public deposits;


    modifier onlyExecutor() {
        require(executors[msg.sender] == true, "Lucks: onlyExecutor");
        _;
    }

    // ======== Constructor =========

    /**
     * @notice Constructor
     * @param _executor address
     */
    constructor(address _executor, ILucksHelper _helper) {       
       executors[_executor]= true;
       HELPER = _helper;
    }

    // ============ Public functions ============

    function getNFT(address executor, uint256 depositId) public view override returns(DepositNFT memory){
        return deposits[executor][depositId];
    }

    function deposit(address user, address nft, uint256[] memory tokenIds, uint256[] memory amounts, uint256 endTime) override external payable onlyExecutor 
        returns(uint256 depositId) { 

        require(HELPER.isPunks(nft), "Punks: not Punks");

        // transfer punks to this contract
        // user need to offerPunkForSaleToAddress before createTask
        IPunks punks = HELPER.getPunks();
        
        for (uint256 i = 0; i < tokenIds.length; i++) {

            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == user, "Punks: not owner of punkIndex");

            punks.buyPunk(tokenIds[i]);    
        }     

        // store deposit record
        _depositIds.increment();
        depositId = _depositIds.current();

        deposits[msg.sender][depositId] = DepositNFT(user, nft, tokenIds, amounts, endTime);
        
        emit Deposit(msg.sender, depositId, user, nft, tokenIds, amounts, endTime);   
    }

    function withdraw(uint256 depositId, address to) override external onlyExecutor {

        require(deposits[msg.sender][depositId].tokenIds.length > 0, "Invalid depositId");

        address nft = deposits[msg.sender][depositId].nftContract;
        uint256[] memory tokenIds = deposits[msg.sender][depositId].tokenIds;
        uint256[] memory amounts = deposits[msg.sender][depositId].amounts;

        // update storage
        delete deposits[msg.sender][depositId];

        // transfer out nft
        IPunks punks = HELPER.getPunks();
      
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == address(this), "Punks: proxy is not owner");

            punks.transferPunk(to, tokenIds[i]);
        }

        emit Withdraw(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }

    
    // ============ only Owner ============

    /**
     * @notice for enmergency case
     * for user to redeem
     * in case of cross chain withdraw suck nft, enable to redeem back to seller nft after endTime
    */
    function redeem(address executor, uint256 depositId, address to) override external onlyOwner {
        
        require(deposits[executor][depositId].tokenIds.length > 0, "Invalid depositId");
        require(block.timestamp > deposits[executor][depositId].endTime, "Not time to redeem");
        require(deposits[executor][depositId].user == to , "Invalid redeem to");

        address nft = deposits[executor][depositId].nftContract;
        uint256[] memory tokenIds = deposits[executor][depositId].tokenIds;
        uint256[] memory amounts = deposits[executor][depositId].amounts;

        // update storage
        delete deposits[executor][depositId];

        // transfer back nft to user
        IPunks punks = HELPER.getPunks();
      
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address holder = punks.punkIndexToAddress(tokenIds[i]);
            require(holder == address(this), "Punks: proxy is not owner");

            punks.transferPunk(to, tokenIds[i]);
        }

        emit Redeem(msg.sender, depositId, to, nft, tokenIds, amounts);   
    }


    //  ============ onlyOwner  functions  ============

    function setExecutor(address executor) external onlyOwner {
        executors[executor] = true;
    }
} 