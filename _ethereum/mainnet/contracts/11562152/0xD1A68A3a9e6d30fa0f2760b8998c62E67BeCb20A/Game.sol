// SPDX-License-Identifier: MIT

/// @author Nazariy Vavryk [nazariy@inbox.ru] - reNFT Labs [https://twitter.com/renftlabs]
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

import "./ERC721.sol";
import "./ERC20.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

/** Holiday season NFT game. Players buy tickets to win the NFTs
 * in the prize pool. Every ticket buyer will win an NFT.
 * -------------------------------------------------------------
 *                      RULES OF THE GAME
 * -------------------------------------------------------------
 * 1. Players buy tickets before Jan 3rd 2021 23:59:59 GMT.
 * 2. Only 255 players will participate in the game.
 * 1. Players take turns to unwrap or steal.
 * 2. Each player can only steal once and be stolen from once.
 * 3. Each player has 3 hours to take the turn.
 * 4. If the player fails to take action, they lose their ability
 * to steal and an NFT is randomly assigned to them.
 */
contract Game is Ownable, ERC721Holder, VRFConsumerBase, ReentrancyGuard {
    event Received(address, uint256);
    event PrizeTransfer(address to, address nftishka, uint256 id, uint256 nftIx);
    struct Nft {
        address adr;
        uint256 id;
    }
    // ! there is no player at index 0 here. Starts from index 1
    struct Players {
        address[256] addresses;
        mapping(address => bool) contains;
        uint8 numPlayers;
    }
    struct Entropies {
        uint256[8] vals;
        uint8 numEntropies;
    }

    /// @dev Chainlink related
    address private chainlinkVrfCoordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address private chainlinkLinkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 private chainlinkKeyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 public ticketPrice = 0.5 ether;
    /// @dev before this date, you can be buying tickets. After this date, unwrapping begins
    /// @dev 2021 January 3rd 23:59:59 GMT
    uint32 public timeBeforeGameStart = 1609718399;

    /// @dev order in which the players take turns. This gets set after gameStart once everyone has randomness associated to them
    /// an example of this is 231, 1, 21, 3, ...; the numbers signify the addresses at
    /// indices 231, 1, 3 and so on from the players array. We avoid having a map
    /// of indices like 1, 2, 3 and so on to addresses which are then duplicated
    /// as well in the players array. Note that this is 1-indexed! First player is not index 0, but 1.
    /// This is done such that the maps of steals "swaps" and "spaws" would not signify a player at index
    /// 0 (default value of uninitialised uint8).
    /// Interpretation of this is that if at index 0 in playersOrder we have index 3
    /// then that means that player players.addresses[3] is the one to go first
    uint8[255] private playersOrder;
    /// @dev Chainlink entropies
    Entropies private entropies;
    /// this array tracks the addresses of all the players that will participate in the game
    /// these guys bought the ticket before `gameStart`
    Players public players;

    /// to keep track of all the deposited NFTs
    Nft[255] public nfts;
    /// address on the left stole from address on the right
    /// think of it as a swap of NFTs
    /// once again the address is the index in players array
    mapping(uint8 => uint8) public swaps;
    /// efficient reverse lookup at the expense of extra storage, forgive me
    mapping(uint8 => uint8) public spaws;
    /// for onlyOwner use only, this lets the contract know who is allowed to
    /// deposit the NFTs into the prize pool
    mapping(address => bool) public depositors;
    /// @dev flag that indicates if the game is ready to start
    /// after people bought the tickets, owners initialize the
    /// contract with chainlink entropy. Before this is done
    /// the game cannot begin
    bool private initComplete = false;
    /// @dev tracks the last time a valid steal or unwrap call was made
    /// this serves to signal if any of the players missed their turn
    /// when a player misses their turn, they forego the ability to
    /// steal from someone who unwrapped before them
    /// Initially this gets set in the initEnd by owner, when they complete
    /// the initialization of the game
    uint32 private lastAction;
    /// this is how much time in seconds each player has to unwrap
    /// or steal. If they do not act, they forego their ability
    /// to steal. 3 hours each player times 256 players max is 768 hours
    /// which equates to 32 days.
    uint16 public thinkTime = 10800;
    /// index from playersOrder of current unwrapper / stealer
    uint8 public currPlayer = 0;

    /// @dev at this point we have a way to track all of the players - players
    /// @dev we have the NFT that each player will win (unless stolen from) - playersOrder
    /// @dev we have a way to determine which NFT the player will get if stolen from - swaps
    /// @dev at the expense of storage, O(1) check if player was stolen from - spaws

    modifier beforeGameStart() {
        require(now < timeBeforeGameStart, "game has now begun");
        _;
    }

    modifier afterGameStart() {
        /// @dev I have read miners can manipulate block time for up to 900 seconds
        /// @dev I am creating two times here to ensure that there is no overlap
        /// @dev To avoid a situation where both are true
        /// @dev 2 * 900 = 1800 gives extra cushion
        require(now > timeBeforeGameStart + 1800, "game has not started yet");
        require(initComplete, "game has not initialized yet");
        _;
    }

    modifier onlyWhitelisted() {
        require(depositors[msg.sender], "you are not allowed to deposit");
        _;
    }

    modifier youShallNotPatheth(uint8 missed) {
        uint256 currTime = now;
        require(currTime > lastAction, "timestamps are incorrect");
        uint256 elapsed = currTime - lastAction;
        uint256 playersSkipped = elapsed / thinkTime;
        // someone has skipped their turn. We track this on the front-end
        if (missed != 0) {
            require(playersSkipped > 0, "zero players skipped");
            require(playersSkipped < 255, "too many players skipped");
            require(playersSkipped == missed, "playersSkipped not eq missed");
            require(currPlayer < 256, "currPlayer exceeds 255");
        } else {
            require(playersSkipped == 0, "playersSkipped not zero");
        }
        require(players.addresses[playersOrder[currPlayer + missed]] == msg.sender, "not your turn");
        _;
    }

    /// Add who is allowed to deposit NFTs with this function
    /// All addresses that are not whitelisted will not be
    /// allowed to deposit.
    function addDepositors(address[] calldata ds) external onlyOwner {
        for (uint256 i = 0; i < ds.length; i++) {
            depositors[ds[i]] = true;
        }
    }

    constructor() public VRFConsumerBase(chainlinkVrfCoordinator, chainlinkLinkToken) {
        depositors[0x465DCa9995D6c2a81A9Be80fBCeD5a770dEE3daE] = true;
        depositors[0x426923E98e347158D5C471a9391edaEa95516473] = true;
    }

    function deposit(ERC721[] calldata _nfts, uint256[] calldata tokenIds) public onlyWhitelisted {
        require(_nfts.length == tokenIds.length, "variable lengths");
        for (uint256 i = 0; i < _nfts.length; i++) {
            _nfts[i].transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function buyTicket() public payable beforeGameStart nonReentrant {
        require(msg.value >= ticketPrice, "sent ether too low");
        require(players.numPlayers < 256, "total number of players reached");
        require(players.contains[msg.sender] == false, "cant buy more");
        players.contains[msg.sender] = true;
        // !!! at 0-index we have address(0)
        players.addresses[players.numPlayers + 1] = msg.sender;
        players.numPlayers++;
    }

    /// @param missed - how many players missed their turn since lastAction
    function unwrap(uint8 missed) external afterGameStart nonReentrant youShallNotPatheth(missed) {
        currPlayer += missed + 1;
        lastAction = uint32(now);
    }

    /// @param _sender - index from playersOrder arr that you are stealing from
    /// @param _from - index from playersOrder who to steal from
    /// @param missed - how many players missed their turn since lastAction
    function steal(
        uint8 _sender,
        uint8 _from,
        uint8 missed
    ) external afterGameStart nonReentrant youShallNotPatheth(missed) {
        require(_sender > _from, "cant steal from someone who unwrapped after");
        uint8 sender = playersOrder[_sender];
        uint8 from = playersOrder[_from];
        require(sender > 0, "strictly greater than zero sender");
        require(from > 0, "strictly greater than zero from");
        require(currPlayer + missed < 256, "its a pickle, no doubt about it");
        require(players.addresses[playersOrder[currPlayer + missed]] == players.addresses[sender], "not your order");
        require(players.addresses[sender] == msg.sender, "sender is not valid");
        require(spaws[from] == 0, "cant steal from them again");
        require(swaps[sender] == 0, "you cant steal again. You can in Verkhovna Rada.");
        // sender stole from
        swaps[sender] = from;
        // from was stolen by sender
        spaws[from] = sender;
        currPlayer += missed + 1;
        lastAction = uint32(now);
    }

    /// @param startIx - index from which to start looping the prizes
    /// @param endIx - index on which to end looping the prizes (exclusive)
    /// @dev start and end indices would be useful in case we hit
    /// the block gas limit, or we want to better control our transaction
    /// costs
    function finito(
        uint8[256] calldata op,
        uint8 startIx,
        uint8 endIx
    ) external onlyOwner {
        require(startIx > 0, "there is no player at 0");
        for (uint8 i = startIx; i < endIx; i++) {
            uint8 playerIx = playersOrder[i - 1];
            uint8 prizeIx;
            uint8 stoleIx = swaps[playerIx];
            uint8 stealerIx = spaws[playerIx];
            if (stoleIx == 0 && stealerIx == 0) {
                prizeIx = playersOrder[i - 1] - 1;
            } else if (stealerIx != 0) {
                prizeIx = op[stealerIx - 1];
            } else {
                bool end = false;
                while (!end) {
                    prizeIx = stoleIx;
                    stoleIx = swaps[stoleIx];
                    if (stoleIx == 0) {
                        end = true;
                    }
                }
                prizeIx = op[prizeIx - 1];
            }
            ERC721(nfts[prizeIx].adr).transferFrom(address(this), players.addresses[playerIx], nfts[prizeIx].id);
            emit PrizeTransfer(players.addresses[playerIx], nfts[prizeIx].adr, nfts[prizeIx].id, prizeIx);
        }
    }

    /// Will revert the safeTransfer
    /// on transfer nothing happens, the NFT is not added to the prize pool
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public override returns (bytes4) {
        revert("we are saving you your NFT, you are welcome");
    }

    /// we slice up Chainlink's uint256 into 32 chunks to obtain 32 uint8 vals
    /// each one now represents the order of the ticket buyers, which also
    /// represents the NFT that they will unwrap (unless swapped with)
    function initStart(uint8 numCalls, uint256[] calldata ourEntropy) external onlyOwner {
        require(initComplete == false, "cannot init start again");
        require(now > timeBeforeGameStart + 1800, "game has not started yet");
        require(numCalls == ourEntropy.length, "incorrect entropy size");
        for (uint256 i = 0; i < numCalls; i++) {
            getRandomness(ourEntropy[i]);
        }
    }

    /// After slicing the Chainlink entropy off-chain, give back the randomness
    /// result here. The technique which will be used must be voiced prior to the
    /// game, obviously
    function initEnd(uint8[255] calldata _playersOrder, uint32 _lastAction) external onlyOwner {
        require(now > timeBeforeGameStart + 1800, "game has not started yet");
        require(_playersOrder.length == players.numPlayers, "incorrect len");
        playersOrder = _playersOrder;
        lastAction = _lastAction;
        initComplete = true;
    }

    /// Randomness is queried afterGameStart but before initComplete (flag)
    function getRandomness(uint256 ourEntropy) internal returns (bytes32 requestId) {
        uint256 chainlinkCallFee = 2000000000000000000;
        require(LINK.balanceOf(address(this)) >= chainlinkCallFee, "not enough LINK");
        requestId = requestRandomness(chainlinkKeyHash, chainlinkCallFee, ourEntropy);
    }

    receive() external payable {
        // thanks a bunch
        emit Received(msg.sender, msg.value);
    }

    /// Gets called by Chainlink
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        entropies.vals[entropies.numEntropies] = randomness;
        entropies.numEntropies++;
    }

    function setTicketPrice(uint256 v) external onlyOwner {
        ticketPrice = v;
    }

    function player(uint8 i) external view returns (address, uint8) {
        return (players.addresses[i], players.numPlayers);
    }

    /// to avoid having the players rig the game by having this information
    /// to buy multiple tickts from different accounts and computing what
    /// NFT they will get themselves
    function entropy(uint8 i) external view onlyOwner returns (uint256, uint8) {
        return (entropies.vals[i], entropies.numEntropies);
    }

    function withdrawERC721(ERC721 nft, uint256 tokenId) external onlyOwner {
        nft.transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawERC20(ERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}
