// * ————————————————————————————————————————————————————————————————————————————————— *
// |                                                                                   |
// |    SSSSS K    K EEEEEE L      EEEEEE PPPPP  H    H U    U N     N K    K  SSSSS   |
// |   S      K   K  E      L      E      P    P H    H U    U N N   N K   K  S        |
// |    SSSS  KKKK   EEE    L      EEE    PPPPP  HHHHHH U    U N  N  N KKKK    SSSS    |
// |        S K   K  E      L      E      P      H    H U    U N   N N K   K       S   |
// |   SSSSS  K    K EEEEEE LLLLLL EEEEEE P      H    H  UUUU  N     N K    K SSSSS    |
// |                                                                                   |
// | * AN ETHEREUM-BASED INDENTITY PLATFORM BROUGHT TO YOU BY NEUROMANTIC INDUSTRIES * |
// |                                                                                   |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@                              |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@@@@@@@@,,,,,,,,,,@@@@@@,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                       @@@,,,,,,,@@@@@@,,,,,,,,,,,,,,,,,@@@                        |
// |                          @@@,,,,,,,,,,,,,,,,,,,,,,,,@@@                           |
// |                          @@@,,,,,,,,,,,,,,,,,,,,@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@@@@@@@@@@@@@@@@@@@@@@@@                           |
// |                             @@@@,,,,,,,,,,,,,,,,@@@@,,,@@@                        |
// |                                 @@@@@@@@@@@@@@@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                              @@@,,,,@@@                           |
// |                                           @@@,,,,,,,,,,@@@                        |
// |                                                                                   |
// |                                                                                   |
// |   for more information visit skelephunks.com  |  follow @skelephunks on twitter   |
// |                                                                                   |
// * ————————————————————————————————————————————————————————————————————————————————— *
   
   
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                           |  The Graveyard is a place you can send a Skelephunk    //
    //  The Skelephunks Graveyard Contract       |  and get back a fresh mint from the "Crypt" reserves.  //
    //  By Autopsyop,for Neuromantic Industries  |  This is called "burying" instead of burning a token.  //
    //  Part of the Skelephunks Platform         |  Once a token is buried it can also be purchased at    //
    //                                           |  mint price or reserved to swap in for your next bury  //                                                 //  
    ////////////////////////////////////////////////////////////////////////////////////////////////////////                                    


// SPDX-License-Identifier: MIT
// ************************* ERROR CODES ***************************/
// aa: already authorized
// na: must be authorized
// oa: must be owner or authorized address
// ns: address supplied for skelephunksContract does not return "SKELE" from a call to symbol()
// as: skelephunksContract is already set to that value
// rs: no skelephunks contract linked
// os: you can only send skelephunks to the Graveyard
// ap: Paused already set to that value
// ao: minterOnlyReminting already set to that value
// ar: allowReminting already set to that value
// am: already reminted more than that
// ge: the graveyard is empty
// aw: per-wallet maximum already set to that value
// au: useSnapshot is already set to that value
// nb: token is not buried
// tr: token is reserved
// al: allowReservations is already set to that value
// nr: reservations are not currently allowed
// ur: address has nothing reserved
// nm: no mints left in crypt
// mr: maximum remints already granted
// mx: wallet has already max reminted
// sn: token was minted after _snapshot
// cb: the graveyard cannot bury your skelephunk at this time
// nc: contracts are not allowed to send tokens to the graveyard
// a$: allowPurchasing is already set to that value
// a@: _purchasePrice already set to that value
// np: purchasing not currently allowed
// pr: Poor
// cf: could not forward payment to the skelephunks contract
// no: no overpayments to refund for your wallet
// *****************************************************************/

pragma solidity ^0.8.0;


import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

interface ISkelephunks is IERC721 {
    function mintedAt(uint256 tokenId) external view returns (uint256);
    function minterOf(uint256 tokenId) external view returns (address);
    function getGenderAndDirection(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex( address owner, uint256 index) external view returns (uint256);
    function numMintedReserve() external view returns (uint256);
    function maxReserveSupply() external view returns (uint256);
    function mintReserve(address to, uint256 quantity, uint256 genderDirection) external;
    function mintPrice () external view returns (uint256);
    function owner () external view returns (address);
    function symbol () external view returns (string memory);
}

/// @title Skelephunks Graveyard
/// @author Neuromantic Industries 
/// @notice You can use this contract to exchange (bury) Skelephunks for different tokens
/// @notice Different exchange options can be enabled: Reserve, Random, Remint from Crypt
/// @notice Purchases can also be enabled for buying buried tokens
/// @dev Requires linkage to the Skelephunks contract for Crypt Remints
contract Graveyard is IERC721Receiver, Ownable {
// packed storage variables
    uint256 private _snapshot;

    uint64 private _purchasePrice;
    uint16 public totalRemints;
    uint16 public totalBurials;
    uint16 private _maxRemints;
    uint16 private _maxRemintsPerWallet;
    uint8 public holdLengthMinutes;// max 256 minutes 
    bool public paused;
    bool public minterOnlyReminting;
    bool public allowReminting;
    bool public useSnapshot;
    bool public allowReservations;
    bool public allowPurchasing;

    ISkelephunks public skelephunksContract;

    mapping (address => bool) private authorizedAddresses;

    mapping (address => uint16) private totalRemintsByWallet;

    mapping ( address => uint16 ) private reservations;
    mapping ( uint16 => address ) private reservers;

    mapping ( uint16 => uint256 ) private expirations;
    mapping (address=> uint256) private overpayments;


    constructor () {
        setSkelephunksContract(0x7db8cD89308A295bb2D7F809B05DB6389e9a6d88);// MAINNET
        // setSkelephunksContract(0xbaC6C9F6b0d7be7a46EDb82237991Fb990459748);// GOERLI
        paused = false;

        allowReminting = true;
        minterOnlyReminting = false;
        _maxRemints = 0;//no limit
        _maxRemintsPerWallet = 0;//no per-wallet limit

        useSnapshot = true;//no reminting remints
        _snapshot = block.timestamp;// or new mints after this contract is deployed

        allowPurchasing = true;// initially graveyard is just for remints

        allowReservations = false;// initially graveyard is just for remints
        holdLengthMinutes = 60;//1 hour hold for reservations (can be expanded to 4 hours)

        transferOwnership( skelephunksContract.owner() );
    }

    /// @notice Set authorization for a (contract) address to exhume buried skelephunks
    /// @dev Does not currently restrict input to contract addresses
    /// @param addr The address to update authorization
    /// @param state The new authorization state for the address
    function setAuthorization( 
        address addr,
        bool state
    ) public onlyOwner {
        require(authorizedAddresses[addr]!=state,"aa");
        authorizedAddresses[addr] = state;

    }

    /// @notice Determine the authorization state of an address
    /// @param addr The address to check for authorization
    /// @return bool The authorization state for the address
    function isAuthorized(
        address addr
    ) public view returns (bool){
        return authorizedAddresses[addr];
    }

    /// @notice Require authorization to use the modified function
    modifier onlyAuthorized{
        require(authorizedAddresses[msg.sender],"na");
        _;
    }

    /// @notice Require ownership or authorization to use the modified function
    modifier ownerOrAuthorized{
        require( owner() == msg.sender || isAuthorized(msg.sender), "oa");
        _;
    }

    /// @notice Link the Skelephunks contract to enanble remints from the Crypt
    /// @dev Will soft-confirm the contract by symbol to help ensure correctness
    /// @param addr The address of the Skelephunks contract
    function setSkelephunksContract( 
        address addr 
    ) public onlyOwner {
        require(address(skelephunksContract)!= addr, "as");
        ISkelephunks skele = ISkelephunks(addr);
        require( keccak256(abi.encodePacked(skele.symbol())) == keccak256(abi.encodePacked("SKELE")),"ns");
        skelephunksContract = skele;
    }

    /// @notice Require the Skelephunks contract to be linked to use the modified function
    modifier requiresSkelephunks {
        require( ISkelephunks(address(0)) != skelephunksContract , "rs" );
        _;
    }

    /// @notice Get the number of mints this contract can access from the Crypt for reminting
    /// @dev Reserving 666 mints for other purposes
    /// @return The number of mints left in the Crypt, minus 666
    function maxCryptMints(
    ) private view requiresSkelephunks returns (uint16){
        return  uint16(skelephunksContract.maxReserveSupply() - skelephunksContract.numMintedReserve() - 666);
    }

    /// @notice Determine if Crypt has more mints to offer for remints
    /// @return True if mints remain
    function cryptHasMints(
    ) private view returns (bool){
        return maxCryptMints() != 0;
    }
    
    /// @notice Get the number of mints this contract can access from the Crypt for reminting
    /// @dev Reserving 666 mints for other purposes
    /// @param state The new paused state for the contract
    function setPaused(
        bool state
    ) public onlyOwner {
        require( paused != state, "ap" );
        paused = state;
    }

    /// @notice Require the contract to not be paused in order to use the modified function
    modifier pausable {
      require(!paused);
      _;
   }

    /// @notice Set whether or not only token minters can remint them from the Crypt
    /// @param state Whether only minters should be able to remint
    function setMinterOnlyReminting( 
        bool state 
    ) public onlyOwner {
        require( minterOnlyReminting != state, "ao" );
        minterOnlyReminting = state;
    }


    /// @notice Set whehther or not anyone can remint from the Crypt
    /// @param state Whether anyone should be able to remint
    function setAllowReminting( 
        bool state 
    ) public onlyOwner {
        require( allowReminting != state, "ar" );
        allowReminting = state;
    }

    /// @notice Determine if a token is buried
    /// @dev A buried token is any Skelephunk owned by this contract
    /// @param tokenId The id of the token to check if buried
    function isBuried(
        uint16 tokenId
    ) public view requiresSkelephunks returns ( bool ){
        return skelephunksContract.ownerOf(uint256(tokenId)) == address(this);
    }

    /// @notice Set the maximum number of remints that can be provided by the Graveyard
    /// @dev Setting to 0 lifts any constraint, to prevent remints use setAllowRemintings()
    /// @param max The lifetime maximum number of remints, must be higher than totalRemints
    function setMaxRemints( 
        uint16 max 
    ) public onlyOwner {
        require( max == 0 || max > totalRemints, "am" );
        _maxRemints = max;
    }
  
    /// @notice The number of tokens currently owned by the Graveyard
    /// @dev Setting to 0 lifts any constraint, to prevent remints use setAllowRemintings()
    /// @return The number of tokens currently owned by the Graveyard
    function numBuried(
    ) public view requiresSkelephunks returns ( uint16 ){
        return uint16(skelephunksContract.balanceOf( address( this ) ));
    }
  
    /// @notice Requires the Graveyard to have buried tokens to use the modified function
    modifier notEmpty {
        require(0 < numBuried(), "ge");
        _;
    }

    /// @notice The maximum number of remints allowed to any given wallet all-time
    /// @dev Setting to 0 lifts any constraint, to prevent remints use setAllowRemintings()
    /// @return The maximum number of remints allowed to any given wallet all-time
    function maxRemintsPerWallet(
    )public view returns (uint16){
        if(_maxRemintsPerWallet == 0){
            return remainingRemints();
        }
        return _maxRemintsPerWallet;
    }

    /// @notice Set the maximum number of remints allowed to any given wallet all-time
    /// @dev Setting to 0 lifts any constraint, to prevent remints use setAllowRemintings()
    /// @param max The maximum number of remints allowed to any given wallet all-time
    function setMaxRemintsPerWallet( 
        uint16 max 
    ) public onlyOwner {
        require(_maxRemintsPerWallet != max, "aw");
        _maxRemintsPerWallet = max;
    }

    /// @notice Get the remaining number of remints the Graveyard can provide
    /// @dev Returns 0 when reminting is disabled for easier state query
    /// @return The remaining number of available remints
    function remainingRemints(
    ) public view returns (uint16) {
        if (!cryptHasMints() || !allowReminting){
            return 0;
        }
        if (_maxRemints == 0){
            return maxCryptMints();
        }
        return _maxRemints - totalRemints;
    }

    /// @notice Get the remaining number of remints available to a given wallet
    /// @dev Returns 0 when reminting is disabled for easier state query
    /// @dev Returns total remaining remints if _maxRemintsPerWallet is 0 (untracked)
    /// @return The remaining number of available remints
    function remainingRemintsForWallet(
        address wallet
    ) public view returns(uint16){
        if (!cryptHasMints() || !allowReminting){
            return 0;
        }
        if (_maxRemintsPerWallet == 0){
            return remainingRemints();
        }
        return _maxRemintsPerWallet - totalRemintsByWallet[wallet];
    }

    /// @notice Prevent reminting tokens minted after an updatable timeatamp
    /// @dev The _snapshot set on contract deploy prevents remints from being reminted
    /// @param state Whether or not to use the stored snapahot to prevent remints
    function setUseSnapshot(
        bool state
    ) public onlyOwner {
        require (useSnapshot != state, "au" );
        useSnapshot = state;
    }

    /// @notice Get current snapshot timestamp value
    /// @dev If _snapshot is 0, return current timestamp
    /// @return Tiume before which mints cant be reminted
    function snapshot( 
    ) public view returns (uint256){
        if(useSnapshot){
            return _snapshot;
        }
        return block.timestamp;
    }

    /// @notice Update the snapshot timestamp to the current second
    function takeSnapshot( 
    ) public onlyOwner {
        useSnapshot = true;
        _snapshot = block.timestamp;
    }

    /// @notice Update the snapshot timestamp to the current second
    /// @param timestamp The UNIX timestamp after which mints cant be reminted
    function setSnapshot(
        uint256 timestamp 
    ) public onlyOwner {

    }

    /// @notice Update the hold length (in minutes) for reservations
    /// @param mins The number of minutes to hold a reservation
    function setHoldLengthMinutes(
        uint8 mins
    ) public onlyOwner {
        holdLengthMinutes = mins;
    }

    /// @notice Determine whether a token is available (buried but not reserved)
    /// @param tokenId The token to check for avilability
    /// @return Whether the token is available
    function tokenIsAvailable(
        uint16 tokenId
    ) private view returns (bool) {
        return isBuried(tokenId) && !isReserved(tokenId);
    }

    /// @notice Require that a given tokenId is available or revert
    /// @param tokenId The token ID that must be available
    function requireAvailable(
        uint16 tokenId
    ) private view {
        require(isBuried(tokenId), "nb");
        require(!isReserved(tokenId) || reservations[msg.sender] == tokenId, "tr");

    }

    /// @notice Set whether reserved redemption are allowed
    /// @param state The new state of the reservations system
    function setAllowReservations(
        bool state
    )public onlyOwner{
        require(allowReservations != state, "al");
        allowReservations = state;
    }

    /// @notice Determine whether a token is available (buried but not reserved)
    /// @param tokenId The token to check for avilability
    /// @return Whether the token is available
    function isReserved(
        uint16 tokenId
    ) public view returns (bool){
        return block.timestamp < expirations[ tokenId ];
    }

    /// @notice Reserve a token for exchange upon your next burial
    /// @param tokenId The token to reserve
    function reserveToken( 
        uint16 tokenId 
    ) public pausable notEmpty{
        require(allowReservations, "nr");
        requireAvailable(tokenId);
        if(hasReservation(msg.sender)){
            clearReservationFrom(msg.sender);
        }
        reservations[msg.sender] = tokenId;
        reservers[tokenId] = msg.sender;
        lockToken(tokenId);
    }

    /// @notice Determine which wallet reserved a given token
    /// @dev A value of 0 means the token isn't reserved
    /// @param tokenId The token to check for reservation
    /// @return The address of the wallet that reserved the token
    function reserverOf(
        uint16 tokenId
    ) public view returns (address){
        return reservers[tokenId];
    }

    /// @notice Determine which token is reserved by a given wallet
    /// @dev A value of 0 means the  wallet has no reservation
    /// @param wallet The wallet to check for reservation
    /// @return The token id reserved by the wallet
    function reservationForWallet(
        address wallet
    ) public view returns (uint16) {
        return reservations[wallet];
    }

    /// @notice Lock up a token for holdLengthMinutes minutes (cannot be purchased or reserved)
    /// @param tokenId The token id to lock
    function lockToken (
        uint16 tokenId
    ) private {
        expirations[tokenId] = block.timestamp + uint256(holdLengthMinutes) * 60;
    }


    /// @notice Unlock a token (can now be purchased or reserved)
    /// @param tokenId The token id to lock
    function unlockToken(
        uint16 tokenId
    ) private{
        delete expirations[tokenId];
    }


    /// @notice Clear any reservation from your wallet
    function clearMyReservation(
    ) public {
        clearReservationFrom(msg.sender);
    }

    /// @notice Clear any reservation from a given  wallet
    /// @param wallet The wallet to clear
    function clearReservationFrom(
        address wallet
    ) private {
        uint16 token = reservationForWallet( wallet );
        require( token != 0, "ur" );
        unlockToken(token);
        delete reservers[token];
        delete reservations[wallet];
    }

    /// @notice Get the id of the nth buried token
    /// @dev Indexed from 0 to numBuried -1
    /// @param index The index of the buried token
    /// @return The token id of the buried token
    function buriedTokenByIndex(
        uint16 index
    ) public view requiresSkelephunks returns (uint16) {
        return uint16(skelephunksContract.tokenOfOwnerByIndex(address(this), index));
    }


    /// @notice Transfer a buried token from the Graveyard to a wallet
    /// @param wallet The wallet to send the token to
    /// @param tokenId The id of the token to send
    function exhumeToken(
        address wallet, 
        uint16 tokenId
    ) private notEmpty requiresSkelephunks {
        skelephunksContract.safeTransferFrom(address(this), wallet, uint256(tokenId));
    }

    /// @notice Transfer an available token from the Graveyard to a wallet
    /// @param wallet The wallet to send the token to
    /// @param tokenId The id of the token to send
    function exhumeTo(
        address wallet,
        uint16 tokenId
    ) public ownerOrAuthorized {
        requireAvailable(tokenId);
        exhumeToken(wallet,tokenId);
    }

    /// @notice Exhume all tokens to a single address
    /// @param wallet The wallet to send the tokens to
    function exhumeAllTo(
        address wallet
    ) public onlyOwner notEmpty {
        uint16 num = numBuried();
        if( num != 0 ){
            for (uint16 i = 0; i<num; i++ ){
                exhumeToken( wallet, buriedTokenByIndex(0));
            }
        }
    }

    /// @notice Exhume a reserved token to its reserving wallet
    /// @param wallet The wallet to send the token to
    function exhumeReserved(
        address wallet
    ) private notEmpty{
        uint16 token = reservationForWallet(wallet) ;
        require(token != 0, "ur" );
        exhumeToken(wallet,token);
        clearReservationFrom(wallet);
    }
    
    /// @notice Exhume a randome token to a wallet
    /// @param wallet The wallet to send the token to
    function exhumeRandom(
        address wallet
    ) public requiresSkelephunks notEmpty{
        uint16 num = numBuried();
        uint16 index;
        if(num == 1){
            index = 0;
        } else{
            uint256 random = uint256(
                keccak256(
                    abi.encode(
                        wallet,
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        block.prevrandao,
                        blockhash(block.number - 1),
                        address(this),
                        numBuried()
                    )
                )
            );
            index = uint16(random % uint256(numBuried() - 1)); // max index was just buried
        }
        uint16 token = buriedTokenByIndex(index);
        exhumeToken(wallet,token);
    }

    /// @notice Mint a new token from the Crypt to a  wallet
    /// @param wallet The wallet to send the token to
    /// @param gad The starting gender and direction code for the new mint
    function remintFromCrypt(
        address wallet, 
        uint8 gad
    ) private requiresSkelephunks {
        require( cryptHasMints(),"nm");
        require( totalRemints < remainingRemints(), "mr" );
        require( 0 < remainingRemintsForWallet(wallet), "mx");
        skelephunksContract.mintReserve(wallet, 1, gad);
        totalRemints++;
        totalRemintsByWallet[ wallet ]++;
    }

    /// @notice Check if a Wallet has a reservation
    /// @param wallet The wallet to check for a reservation
    function hasReservation(
        address wallet
    ) private view returns (bool){
        return reservationForWallet(wallet) != 0;
    }

    /// @notice Register a received Skelephunk token as buried
    /// @param tokenId The sid of the token to bury
    /// @param wallet The wallet burying the token
    function burySkelephunk(
        uint16 tokenId, 
        address wallet 
    ) private requiresSkelephunks{
        require( !useSnapshot || 0 == _snapshot || skelephunksContract.mintedAt( tokenId ) < _snapshot, "sn" );
    
        if(wallet == owner()){
            // contract owner can send without reward to populate the graveyard
        }else if(hasReservation(wallet)){ // settle reservations first
            exhumeReserved(wallet); 
        }else if (// if remints are available and allowed, send a new mint from the crypt
            allowReminting &&
            cryptHasMints() && 
            0 < remainingRemints() && 
            0 < remainingRemintsForWallet(wallet) && 
            (!minterOnlyReminting || skelephunksContract.minterOf( tokenId ) == wallet)
        ){
            remintFromCrypt(wallet,uint8(skelephunksContract.getGenderAndDirection(tokenId)));
        }else if(0 < numBuried()){// otherwise, send a random buried token
            exhumeRandom(wallet);
        }else{
            revert("cb");
        }
        totalBurials++;
    }

    /// @notice Respond to being sent a Skelphunks token by burying it
    /// @dev see https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721Receiver
    function onERC721Received(
        address, 
        address from, 
        uint256 tokenId, 
        bytes calldata 
    ) external returns (bytes4) {
        uint16 id = uint16(tokenId);
        require(msg.sender == address(skelephunksContract),"foh yoinker");
        require(from == tx.origin, "nc");//skelephunks is for the people
        burySkelephunk(id, from);
        require(isBuried(id),"nb");
        return this.onERC721Received.selector;
    }

    /// @notice Allow buried tokens to be purchased
    /// @param state Whether or not to allow purchases
    function setAllowPurchasing (
        bool state
    ) public onlyOwner{
        require(allowPurchasing !=state, "a$");
        allowPurchasing = state;
    }

    /// @notice Override the purchae price of buried tokens (vs. using mintPrice)
    /// @dev Set to 0 to use Skelephunks mint price
    /// @param price The price (in Wei)to buy buried tokens
    function setPurchasePrice(
        uint64 price
    ) public onlyOwner {
        require(_purchasePrice != price, "a@");
        _purchasePrice = price;
    }

    /// @notice Get current purchase price for buried tokens
    /// @return The price (in Wei) to buy buried tokens
    function purchasePrice(
    )public view returns (uint64){
        if(_purchasePrice == 0){
            return uint64(skelephunksContract.mintPrice());
        }else{
            return _purchasePrice;
        }
    }


    /// @notice buy a buried Skelephunk for thet purchase price
    /// @dev Overpayment can be withdrawn any time
    /// @param tokenId The id of the token to buy
    function buyBuriedSkelephunk (
        uint16 tokenId
    ) public payable pausable requiresSkelephunks{
        uint256 price = uint256(purchasePrice());
        require( allowPurchasing, "np");
        require( price <= msg.value, "pr");
        requireAvailable(tokenId);
        (bool outcome,) = address(skelephunksContract).call{value: price}("");
        require(outcome,"cf");
        exhumeToken(msg.sender,tokenId);
        uint256 refund = msg.value - price;
        overpayments[msg.sender] += refund;

    }

    /// @notice Get the cumulative overpayment for purchased tokens by a wallet
    /// @param wallet The wallet to check for overpayment balance
    function refundAmountForWallet(
        address wallet
     ) public view returns (uint256){
         return overpayments[wallet];
     }

    /// @notice Withdraw any accumulated overpayment for your wallet
     function withdrawRefund(
     ) public {
        require(overpayments[msg.sender] !=0, "no");
        payable(msg.sender).transfer(overpayments[msg.sender]);
        overpayments[msg.sender] = 0;
     }

}