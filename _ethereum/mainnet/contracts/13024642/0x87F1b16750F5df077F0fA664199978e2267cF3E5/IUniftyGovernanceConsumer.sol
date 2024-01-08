pragma solidity ^0.8.4;

/**
 * Mandatory interface for a UniftyGovernanceConsumer.
 * 
 * */
interface IUniftyGovernanceConsumer{
    
    /**
     * Must be emitted in withdraw() function.
     * 
     * */
    event Withdrawn(address indexed user, uint256 untEarned);

    /**
     * The name of this consumer must be requestable.
     * 
     * This information is supposed to be used in clients.
     * 
     * */
    function name() external view returns(string calldata);
    
    /**
     * The description for this consumer must be requestable.
     * 
     * This information is supposed to be used in clients.
     * 
     * */
    function description() external view returns(string calldata);
    
    /**
     * Peer whitelist required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     * 
     * Example would be to vote for farms in the governance being included.
     * Accepted peers can then be added to the consumer's internal whitelist and get further benefits like UNT.
     * 
     * Must contain a check if the caller has been the governance.
     * 
     * */
    function whitelistPeer(address _peer) external;
    
    /**
     * Peer whitelist removal required to be implemented.
     * If no peers should be used, this can have an empty implementation.
     * 
     * Example would be to vote for farms in the governance being removed and exluded.
     * 
     * Must contain a check if the caller has been the governance.
     * 
     * */
    function removePeerFromWhitelist(address _peer) external;
    
    /**
     * Called by the governance to signal an allocation event.
     * 
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     * 
     * Returns true if the allocation has been accepted, false if not.
     * 
     * Must contain a check if the caller has been the governance.
     * */
    function allocate(address _account, uint256 prevAllocation, address _peer) external returns(bool);
    
    /**
     * Called by the governance upon staking if the allocation for a user and a peer changes.
     * The consumer has then the ability to check what has been changed and act accordingly.
     *
     * Must contain a check if the caller has been the governance.
     * */
    function allocationUpdate(address _account, uint256 prevAmount, uint256 prevAllocation, address _peer) external returns(bool, uint256);
    
    /**
     * Called by the governance to signal an dellocation event.
     * 
     * The implementation must limit calls to the governance and should
     * give the consumer a chance to handle allocations (like timestamp updates)
     * 
     * This functions is also called by the governance before it calls allocate.
     * This must be akten into account to avoid side-effects.
     * */
    function dellocate(address _account, uint256 prevAllocation, address _peer) external returns(uint256);
    
    /**
     * Called by the governance to determine if allocated stakes of an account in the governance should stay frozen.
     * If this returns true, the governance won't release NIF upon unstaking.
     * 
     * */
    function frozen(address _account) external view returns(bool);
    
    /**
     * Returns true if the peer is whitelisted, otherwise false.
     * 
     * */
    function peerWhitelisted(address _peer) external view returns(bool);
    
    /**
     * Should return a URI, pointing to a json file in the format:
     * 
     * {
     *   name : '',
     *   description : '',
     *   external_link : '',
     * }
     * 
     * Can throw an error if the peer is not whitelisted or return an empty string if there is no further information.
     * Since this is supposed to be called by clients, those have to catch errors and handle empty return values themselves.
     * 
     * */
    function peerUri(address _peer) external view returns(string calldata);
    
    /**
     * Must return the time in seconds that is left until the allocation 
     * of a user to the peer he is allocating to expires.
     * 
     * */
    function timeToUnfreeze(address _account) external view returns(uint256);
    
    /**
     * _peer parameter to apply the AP info for.
     * 
     * Frontend function to help displaying apr/apy and similar strategies.
     *
     * The first index of the returned tuple should return "r" if APR or "y" if APY.
     * 
     * The second index of the returned tuple should return the actual APR/Y value for the consumer.
     * 18 decimals precision required.
     *
     * The 2nd uint256[] array should return a list of proposed services for price discovery on the client-side.
     *
     * 0 = uni-v2 unt/eth
     * 1 = uni-v2 unt/usdt
     * 2 = uni-v2 unt/usdc
     * 3 = uni-v3 unt/eth
     * 4 = uni-v3 unt/usdt
     * 5 = uni-v3 unt/usdc
     * 6 = kucoin unt/usdt
     * 7 = binance unt/usdt
     *
     * The rate and list should be udpatable/extendible through an admin function due to possible updates on the client-side.
     * (e.g. adding more exchanges)
     *
     * */
    function apInfo(address _peer) external view returns(string memory, uint256, uint256[] memory);
    
    /**
     * Withdraws UNT rewards for accounts that stake in the governance and allocated their funds to this consumer and peer.
     * 
     * Must return the amount of withdrawn UNT.
     * 
     * */
    function withdraw() external returns(uint256);
    
    /**
     * Must return the account's _current_ UNT earnings (as of current blockchain state).
     * 
     * Used in the frontend.
     * */
    function earned(address _account) external view returns(uint256);
    
    /**
     * Same as earned() except adding a live component that may be inaccurate due to not yet occurred state-changes.
     * 
     * If unsure how to implement, call and return earned() inside.
     * 
     * Used in the frontend.
     * */
    function earnedLive(address _account) external view returns(uint256);
    
    /**
     * If there are any nif caps per peer, this function should return those.
     * 
     * */
    function peerNifCap(address _peer) external view returns(uint256);
}