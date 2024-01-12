// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./IFlypeNFT.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FlypeTokenSale is Ownable, ReentrancyGuard{
    /// @notice Contains parameters, necessary for the pool
    /// @dev to see this parameters use getPoolInfo, checkUsedAddress and checkUsedNFT functions
    struct PoolInfo
    {
        uint256 takenSeats;
        uint256 maxSeats;
        uint256 maxTicketsPerUser;
        uint256 ticketPrice;
        uint256 ticketReward;
        uint256 lockup;
        mapping(address => uint256) takenTickets;
    }
    
    /// @notice pool ID for Econom class
    uint256 constant public ECONOM_PID = 0;
    /// @notice pool ID for Buisness class
    uint256 constant public BUISNESS_PID = 1;
    /// @notice pool ID for First class
    uint256 constant public FIRST_CLASS_PID = 2;
    
    /// @notice address of Flype NFT
    IFlypeNFT public immutable Flype_NFT;

    /// @notice address of USDC
    IERC20 public immutable USDC;
    /// @notice True if minting is paused 
    bool public onPause;

    mapping(uint256 => PoolInfo) poolInfo;
    mapping(address => bool) public banlistAddress;

    /// @notice Restricts from calling function with non-existing pool id 
    modifier poolExist(uint pid){
        require(pid <= 2, "Wrong pool ID");
        _;
    }

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause(){
        require(!onPause, "Pool is on pause");
        _;
    }

    /// @notice event emmited on each token sale
    /// @dev all events whould be collected after token sale and then distributed
    /// @param user address of buyer
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event Sale(
        address indexed user, 
        uint256 pid, 
        uint256 takenSeat, 
        uint256 reward,
        uint256 lockup,
        uint256 blockNumber, 
        uint256 timestamp
    );

    /// @notice event emmited on each pool initialization
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param maxSeats maximum number of participants
    /// @param ticketPrice amount of usdc which must be approved to participate
    /// @param ticketReward reward, which must be sent
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event InitializePool(
        uint256 pid, 
        uint256 takenSeat,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup,
        uint256 blockNumber, 
        uint256 timestamp
    );

    /// @notice Performs initial setup.
    /// @param _FlypeNFT address of Flype NFT
    constructor(IFlypeNFT _FlypeNFT, IERC20 _USDC) ReentrancyGuard(){
        Flype_NFT = _FlypeNFT;
        USDC = _USDC;
    }

    /// @notice Function that allows contract owner to initialize and update update pool settings
    /// @param pid pool id
    /// @param _maxSeats maximum number of participants
    /// @param _ticketPrice amount of usdc which must be approved to participate
    /// @param _ticketReward reward, which must be sent
    /// @param _lockup time before token can be collected
    function initializePool(
        uint256 pid, 
        uint256 _maxSeats, 
        uint256 _maxTicketPerUser,
        uint256 _ticketPrice, 
        uint256 _ticketReward,
        uint256 _lockup) 
        external 
        onlyOwner
        poolExist(pid)
    {
        PoolInfo storage pool = poolInfo[pid];
        pool.maxSeats = _maxSeats;
        pool.ticketPrice = _ticketPrice;
        pool.ticketReward = _ticketReward;
        pool.lockup = _lockup;
        pool.maxTicketsPerUser = _maxTicketPerUser;
        emit InitializePool(
            pid, 
            pool.takenSeats,
            pool.maxSeats,
            pool.maxTicketsPerUser,
            pool.ticketPrice,
            pool.ticketReward,
            pool.lockup,
            block.number, 
            block.timestamp
        );
    }

    /// @notice Function that allows contract owner to ban address from sale
    /// @param user address which whould be banned or unbanned
    /// @param isBanned state of ban
    function banAddress(address user, bool isBanned) external onlyOwner{
        banlistAddress[user] = isBanned;
    }

    /// @notice Function that allows contract owner to pause sale
    /// @param _onPause state of pause
    function setOnPause(bool _onPause) external onlyOwner{
        onPause = _onPause;
    }

    /// @notice Function that allows contract owner to receive all available usdc from sale
    /// @param receiver address which whould receive usdc
    function takeAllTokens(address receiver) external onlyOwner{
        _takeTokens(receiver, USDC.balanceOf(address(this)));
    }

    /// @notice Function that allows contract owner to receive usdc from sale
    /// @param receiver address which whould receive usdc
    /// @param amount amount of usdc to transfer to receiver
    function takeTokens(address receiver, uint256 amount) external onlyOwner{
        _takeTokens(receiver, amount);
    }

    /// @notice emit Sale event for chosen pool
    /// @param pid Pool id 
    function buyTokens (
        uint256 pid,
        uint256 amountOfTickets
    )
    external
    OnPause
    nonReentrant
    poolExist(pid)
    {
        require(!banlistAddress[_msgSender()], "This address is banned");
        require(amountOfTickets > 0, "Amount of tickets cannot be zero");
        require(Flype_NFT.allowList(_msgSender()), "NFT isn't on the balance");
        PoolInfo storage pool = poolInfo[pid];  
        require(pool.takenSeats < pool.maxSeats, "No seats left");  
        require(pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser, "User cannot buy more than maxTicketsPerUser");
        uint256 toTransfer;
        for(
            uint256 i = 0; i < amountOfTickets 
                && pool.takenSeats < pool.maxSeats
                && pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser; 
            i++
        ){
            toTransfer += pool.ticketPrice;
            pool.takenSeats++;
            pool.takenTickets[_msgSender()]++;
            emit Sale(
                _msgSender(), 
                pid, 
                pool.takenSeats, 
                pool.ticketReward,
                pool.lockup,
                block.number, 
                block.timestamp
            );        
        }
        if(toTransfer > 0) USDC.transferFrom(_msgSender(), address(this), toTransfer);
    }

    /// @notice get pool setting and parameters
    /// @param pid pool id
    /// @return takenSeats № of last taken seat
    /// @return maxSeats maximum number of participants
    /// @return maxTicketsPerUser maximum number of participations per user
    /// @return ticketPrice amount of usdc which must approve to participate in pool
    function getPoolInfo(uint256 pid) 
    external 
    poolExist(pid) 
    view 
    returns(
        uint256 takenSeats,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup
        )
    {
        return 
        (
            poolInfo[pid].takenSeats,
            poolInfo[pid].maxSeats,
            poolInfo[pid].maxTicketsPerUser,
            poolInfo[pid].ticketPrice,
            poolInfo[pid].ticketReward,
            poolInfo[pid].lockup
        );
    }

    function getUserTicketsAmount(uint256 pid, address user) external view returns(uint256){
        return(poolInfo[pid].takenTickets[user]);
    }

    /// @notice Function that transfer usdc from sale to given address
    /// @param receiver address which whould receive usdc
    /// @param amount amount to transfer
    function _takeTokens(address receiver, uint256 amount) internal{
        USDC.transfer(receiver, amount);
    }
}