//SPDX-License-Identifier: UNLICENSED

// okay#1746
// ▁ ▂ ▄ ▅ 𝔇𝔦𝔞𝔷𝔈𝔱𝔬 ▅ ▄ ▂ ▁#6666
/*          
                                            ██████████                                  
                                      ░░  ██░░░░░░░░░░██                                
                                        ██░░░░░░░░░░░░░░██                              
                                        ██░░░░░░░░████░░██████████                      
                            ██          ██░░░░░░░░████░░██▒▒▒▒▒▒██                      
                          ██░░██        ██░░░░░░░░░░░░░░██▒▒▒▒▒▒██                      
                          ██░░░░██      ██░░░░░░░░░░░░░░████████                        
                        ██░░░░░░░░██      ██░░░░░░░░░░░░██                              
                        ██░░░░░░░░████████████░░░░░░░░██                                
                        ██░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██                              
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                            
                        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                              
                          ██░░░░░░░░░░░░░░░░░░░░░░░░░░██                                
                            ██████░░░░░░░░░░░░░░░░████                                  
                                  ████████████████                                      
*/
pragma solidity ^0.8.0;

import "./IERC721EnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Enumerable.sol";
import "./CountersUpgradeable.sol";


import "./iquack.sol";
import "./iduckhouse.sol";
import "./iRandom.sol";

import "./console.sol";
contract DopeyDucklingsGen2V2 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    // using SafeMathUpgradeable for uint256;
    mapping(uint256=>uint256) tokenLastWrites;
    mapping(address=>uint256) addressLocks;
    mapping(address=>bool) admins;

    IERC721Enumerable dd;
    IQuack quack;
    IDuckHouse dh;
    IRandom r;

    mapping(address=>uint256) _hunterBalances;

    bool public quackSale;
    uint256 MAX_HUNTERS;
    uint256 HUNTER_COST_Q;

    uint256 MAX_DUCKS_MINT_PUBLIC_SALE;
    uint256 MAX_DUCKS_MINT_PUBLIC_SALE_PER_TX;
    uint256 DUCKS_MINT_COST_E;

    uint256 MAX_DUCKS_MINT_GAME;
    uint256 MAX_KING_DUCKS;

    uint256[] internal UNSTAKED_DUCKS;      //used for tracking killable ducks
    uint256[] internal UNSTAKED_HUNTERS;    //used for tracking killable hunters

    mapping(address=>uint256[]) public ownerTokens; 

    event KingDuckMinted(address indexed _from, uint256 _id);
    event DuckStolen(address indexed _from, address indexed _to, uint256 _id);
    event DuckKilled(address indexed _from, address indexed _to, uint256 _id);
    event HunterKilled(address indexed _from, address indexed _to, uint256 _id);
    event CeaseFire();

    CountersUpgradeable.Counter private _hunterIdCounter;
    CountersUpgradeable.Counter private _duckPublicCounter;
    CountersUpgradeable.Counter private _duckAdminCounter;
    CountersUpgradeable.Counter private _duckKingCounter;

    bool public stealEnabled;
    bool public killEnabled;
    uint256 public killInterval;
    uint256 public killQuantity;
    uint256 public lastKill;

    CountersUpgradeable.Counter private _mintActionCounter;
    CountersUpgradeable.Counter private _huntersKilled;
    CountersUpgradeable.Counter private _huntersStaked;
    CountersUpgradeable.Counter private _ducksStaked;
    CountersUpgradeable.Counter private _ducksKilled;
    CountersUpgradeable.Counter private _ducksStolen;
    uint256[] internal STAKED_KINGS;         // used for tracking stealers

    bool private ceaseFire;
    uint256 private version;
    string private baseuri;
    constructor() {}

    function initialize() public initializer {
        __ERC721_init("Dopey Ducklings Gen 2", "DD2");
        __Ownable_init();
        __Pausable_init();
        dd = IERC721Enumerable(0x4C1E4718818Ac8327EDC2552883ac9F19a5d0eAa);
        quack = IQuack(0x328dA827813881Ac40De42923AE734ba502Ad1A0);
        dh = IDuckHouse(0xA12136FA993C54e244760a5008f80ac8b39AA8A9);

        admins[address(dh)] = true;
        admins[owner()] = true;

        MAX_HUNTERS = 2000;
        HUNTER_COST_Q = 5 ether;

        MAX_DUCKS_MINT_PUBLIC_SALE = 3000;
        MAX_DUCKS_MINT_PUBLIC_SALE_PER_TX = 5;
        DUCKS_MINT_COST_E = 0.05 ether;

        MAX_DUCKS_MINT_GAME = 45000;

        MAX_KING_DUCKS = 5000;

        killEnabled = true;
        killInterval = 60*60*24;
        killQuantity = 1;
        lastKill = block.timestamp;

        _pause();
    }

    function upgradeFromV1() public {
        require(version < 2);
        version = 2;
        killEnabled = false;
        stealEnabled = false;
        lastKill = block.timestamp;

        MAX_DUCKS_MINT_PUBLIC_SALE = 3000;
        MAX_DUCKS_MINT_GAME = 45000;
        MAX_HUNTERS = 2000;
        MAX_KING_DUCKS = 5000;
        HUNTER_COST_Q = 5 ether;
    }

    function setRandom(address _random) public onlyOwner {
        r = IRandom(_random);
    }

    modifier humansOnly() {
        uint256 size;
        address account = _msgSender();
        assembly {
            size := extcodesize(account)
        }
        require(admins[_msgSender()] || size == 0, "Humans only");
        _;
    }

    modifier onlyFromDuckHouse() {
        require(admins[_msgSender()] || _msgSender() == address(dh) || _msgSender() == owner());
        _;
    }

    function getDucksMinted() view public humansOnly returns(uint256){
        return _duckPublicCounter.current();
    }

    function getEthDucksMinted() view public humansOnly returns(uint256){
        return _duckPublicCounter.current() - _duckAdminCounter.current();
    }

    function getHuntersMinted() view public humansOnly returns (uint256) {
        return _hunterIdCounter.current();
    }

    function getDucksStolen() view public humansOnly returns (uint256) {
        return _ducksStolen.current();
    }

    function getHuntersKilled() view public humansOnly returns (uint256) {
        return _huntersKilled.current();
    }

    function getDucksKilled() view public humansOnly returns(uint256) {
        return _ducksKilled.current();
    }

    function getDucksStaked() view public humansOnly returns(uint256) {
        return _ducksStaked.current();
    }

    function getHuntersStaked() view public humansOnly returns(uint256) {
        return _huntersStaked.current();
    }

    function userCanMintHunter(address user) view public returns(bool) {
        return (dd.balanceOf(user) + dh.stakedDuckCountByOwner(user)) > 0;
    }

    function getHuntersMintedForUser(address user) view public humansOnly returns(uint256) {
        return _hunterBalances[user];
    }

    function mintHunter(uint256 numToMint, bool stake) public humansOnly whenNotPaused {
        require(_hunterBalances[_msgSender()] + numToMint <= 3, "Maximum 3 hunters per wallet");
        // get balance of user in DD / staking wallet
        uint256 balance = dd.balanceOf(_msgSender()) + dh.stakedDuckCountByOwner(_msgSender());
        require(balance > 0, "Not a genesis holder");
        
        // spend $quack
        uint256 totalCost = HUNTER_COST_Q * numToMint;
        quack.burnFrom(_msgSender(), totalCost);

        // mint hunter
        for (uint256 i = 0; i < numToMint; i++) {
            uint256 mintedId = _mintHunter();
            if (stake) {
                _transfer(_msgSender(), address(dh), mintedId);
                dh._setStakeForGen2Token(mintedId, _msgSender());
            }
        }
        _hunterBalances[_msgSender()] += numToMint;
    }

    function _mintHunter() private returns(uint256) {
        _hunterIdCounter.increment();
        uint256 id = _hunterIdCounter.current();
        require(id <= MAX_HUNTERS, "Max hunters minted");
        console.log("Minting hunter:", id);
        _mint(_msgSender(), id);
        return id;
    }

    function _u_get_a_king_duck(uint256 tokenId) private returns (bool){
        _mintActionCounter.increment();
        bool result = r.r(keccak256(abi.encodePacked(tokenId, _msgSender(), block.timestamp, _mintActionCounter.current())),true, 50000) < 5000;
        return result;
    }

    function adminMintDuck(uint256 numToMint) public onlyOwner {
        for (uint256 i; i < numToMint; i++) {
            _duckPublicCounter.increment();
            _duckAdminCounter.increment();
            require(_duckPublicCounter.current() <= MAX_DUCKS_MINT_GAME, "Maximum supply reached");
            _mint(_msgSender(), _duckPublicCounter.current());
        }
    }

    function adminMintKing(uint256 numToMint) public onlyOwner {
        for (uint256 i; i < numToMint; i++) {
            _duckPublicCounter.increment();
            _duckAdminCounter.increment();
            _duckKingCounter.increment();
            require(_duckPublicCounter.current() <= MAX_DUCKS_MINT_GAME, "Maximum supply reached");
            _mint(_msgSender(), MAX_HUNTERS + MAX_DUCKS_MINT_PUBLIC_SALE + MAX_DUCKS_MINT_GAME - MAX_KING_DUCKS + _duckKingCounter.current());
        }
    }

    function adminMintHunter(uint256 numToMint) public onlyOwner {
        for (uint i; i < numToMint; i++) {
            _mintHunter();
        }
    }

    function mintDuckComposite(uint256 numToMint, bool stake) public humansOnly whenNotPaused payable {
        bool isEthSale = true;
        if (((_duckPublicCounter.current() - _duckAdminCounter.current()) < MAX_DUCKS_MINT_PUBLIC_SALE) && !quackSale) {
            // requirements for eth sale
            require(numToMint > 0 && numToMint <= MAX_DUCKS_MINT_PUBLIC_SALE_PER_TX, "Invalid mint number");
            require(msg.value >= DUCKS_MINT_COST_E * numToMint, "Incorrect value sent");
            require(numToMint + (_duckPublicCounter.current()-_duckAdminCounter.current()) <= MAX_DUCKS_MINT_PUBLIC_SALE, "Not enough public ducks remaining to mint");
        } else {
            // requirements for quack sale
            require(numToMint + _duckPublicCounter.current() <= (MAX_DUCKS_MINT_GAME+MAX_DUCKS_MINT_PUBLIC_SALE), "Minting would exceed supply");
            require(msg.value == 0, "$QUACK ONLY");
            isEthSale = false;
            // do quack burning here
        }
        for (uint i; i < numToMint; i++) {
            uint256 mintId = _mintDuckComposite(isEthSale);
            if (_stealFlow(mintId)) continue;

            if (stake) {
                _transfer(_msgSender(), address(dh), mintId);
                dh._setStakeForGen2Token(mintId, _msgSender());
            }
        }

        // post mint autokill action
        _autokill(); 
    }

    function _mintDuckComposite(bool isEthSale) private returns(uint256){
        uint256 id;
        bool kingFlow;
        if (_duckKingCounter.current() < MAX_KING_DUCKS && _u_get_a_king_duck(_duckKingCounter.current())) {
            // get duck king id inlined
            kingFlow = true;
            _duckKingCounter.increment();
            id = MAX_HUNTERS + MAX_DUCKS_MINT_PUBLIC_SALE + MAX_DUCKS_MINT_GAME - MAX_KING_DUCKS + _duckKingCounter.current();
        } else {
            _duckPublicCounter.increment();
            id = _duckPublicCounter.current() + MAX_HUNTERS;
            require(id <= MAX_DUCKS_MINT_GAME + MAX_DUCKS_MINT_PUBLIC_SALE + MAX_HUNTERS, "Mint limit reached");
        }
        if (id > (MAX_HUNTERS + MAX_DUCKS_MINT_PUBLIC_SALE + MAX_DUCKS_MINT_GAME - MAX_KING_DUCKS)) {
            // we cap _duckPublicCounter() at 45k and instead switch to the king id selection if this occurs
            if (!kingFlow) {
                _duckPublicCounter.decrement();
                _duckKingCounter.increment();
                id = MAX_HUNTERS + MAX_DUCKS_MINT_PUBLIC_SALE + MAX_DUCKS_MINT_GAME - MAX_KING_DUCKS + _duckKingCounter.current();
            }
            emit KingDuckMinted(_msgSender(), id);
        }

        // if $QUACK sale, burn token cost
        if (!isEthSale) {
            uint256 mc = getQuackMintCost(_duckPublicCounter.current() + _duckKingCounter.current());
            quack.burnFrom(_msgSender(), mc);
        }
        _mint(_msgSender(), id);
        return id;
    }

    function getQuackMintCostForNTokens(uint256 n) view public humansOnly returns (uint256 cost) {
        uint256 start = _duckPublicCounter.current() + 1;
        for (uint256 i; i < n; i++) {
            cost += getQuackMintCost(start + i);
        }
        return cost;
    }

    function getQuackMintCost(uint256 id) pure public returns(uint256) {
        if (id < 10000) return 1 ether;
        else if (id < 20000) return 2 ether;
        else if (id < 30000) return 4 ether;
        else if (id < 40000) return 8 ether;
        else if (id < 50000) return 16 ether;
        else return 999 ether;
    }

    function _duckHouseStakingCallback() public onlyFromDuckHouse {
        _autokill();
    }

    // remove token, isDuck for removing ducks or hunters;
    function _removeUnstakedTokenAtPosition(uint256 position, bool isDuck, bool isKing) internal {
        uint256[] storage UNSTAKED = isDuck ? (isKing ? STAKED_KINGS : UNSTAKED_DUCKS) : UNSTAKED_HUNTERS;
        delete UNSTAKED[position];
        UNSTAKED[position] = UNSTAKED[
            UNSTAKED.length-1
        ];
        UNSTAKED.pop();
    }

    /** finds a tokenId in the unstaked ducks/hunters or staked kings array. returns whether it was found + position
    */
    function _findUnstakedTokenPosition(uint256 tokenId, bool isDuck, bool isKing) internal view returns(bool found, uint256 position){
        uint256[] storage UNSTAKED = isDuck ? (isKing ? STAKED_KINGS : UNSTAKED_DUCKS) : UNSTAKED_HUNTERS;
        for (uint256 i = 0; i < UNSTAKED.length; i++) {
            if (UNSTAKED[i] == tokenId) {
                position = i;
                found = true;
                break;
            }
        }
        return (found, position);
    }    

    // === stealing mechanic ===
    // duck steal flow; 
    // ret true for stolen, false otherwise
    function _stealFlow(uint256 id) private returns(bool) {
        if (!stealEnabled) return false;
        (bool didSteal, address killer) = _maybeSteal(id);
        if (didSteal) {
            _killRandomHunter(killer);
            return true;
        }

        return false;
    }

    // stealing mechanic
    function _maybeSteal(uint256 id) private returns(bool, address){
        bool doSteal = r.r(keccak256(abi.encodePacked(id, _msgSender(), block.timestamp)), true, 10) == 0;
        if (doSteal) {
            // if no king ducks return
            if (_duckKingCounter.current() == 0 || STAKED_KINGS.length == 0) return (false, address(0));

            // get a king duck
            uint256 kId = r.r2(keccak256(abi.encodePacked(id, _msgSender(), block.number)), false, STAKED_KINGS.length) + 1;
            kId = kId + MAX_DUCKS_MINT_GAME;
            address kIdOwner = dh.getGen2StakeStatus(kId).user;
            if (_msgSender() == kIdOwner) {
                // If the minter also owns the king who steals, return to save gas + skip transfers;
                return (false, address(0));
            }

            // transfer to king duck
            _ducksStolen.increment();
            _transfer(_msgSender(), kIdOwner, id);
            emit DuckStolen(_msgSender(), kIdOwner, id);
            return (true, ownerOf(kId));
        }
        return (false, address(0));
    }
    // === end stealing mechanic ===

    // === killing mechanic ===
    function _getKillableToken(bool isDuck) view private returns (uint256 tokenId, uint256 position) {
        uint256[] memory UNSTAKED = isDuck ? UNSTAKED_DUCKS : UNSTAKED_HUNTERS;
        position = r.r(keccak256(abi.encodePacked(block.number, block.timestamp, _msgSender())), true, UNSTAKED.length);
        tokenId = UNSTAKED[position];
        return (tokenId, position);
    }

    /**
    _removeOwnerToken removes a token from a list of tokens owned by that owner
    */
    function _removeOwnerToken(address _owner, uint256 target) internal {
        if (_owner == address(0)) return;

        uint256 position = 0;
        bool found = false;
        for (uint256 i; i < ownerTokens[_owner].length; i++) {
            if (ownerTokens[_owner][i] == target) {
                found = true;
                position = i;
                break;
            }
        }
        if (found) {
            delete ownerTokens[_owner][position];
            ownerTokens[_owner][position] = ownerTokens[_owner][ownerTokens[_owner].length-1];
            ownerTokens[_owner].pop();
        }
    }

    /**
    _killDuck 
    */
    function _killDuck(uint256 id) private {
        _ducksKilled.increment();
        address _owner = ownerOf(id);
        emit DuckKilled(_owner, _owner, id);
        _burn(id);
    }

    function _autokill() private {
        if (killEnabled && (lastKill + killInterval) < block.timestamp) {
            for (uint256 i; i < killQuantity; i++) {
                _killRandomDuck();
            }
            lastKill = block.timestamp;
        }
    }

    /** 
    killDuck()
    */
    function _killRandomDuck() private {
        uint256 duckId;
        uint256 position;
        if (UNSTAKED_DUCKS.length == 0) return;
        (duckId, position) = _getKillableToken(true);
        _killDuck(duckId);
        dh.killCallback();
    }

    /**
    _killHunter burns a token and emits a hunterkilled event
    */
    function _killHunter(uint256 id, address killer) private {
        _huntersKilled.increment();
        emit HunterKilled(killer, ownerOf(id), id);
        _burn(id);
    }

    /** 
    _killRandomHunter selects an unstaked hunter and burns the token
    */
    function _killRandomHunter(address killer) private {
        uint256 hunterId;
        uint256 position;
        if (UNSTAKED_HUNTERS.length == 0) {
            return;
        } // guard against nothing to kill
        (hunterId, position) = _getKillableToken(false);
        _killHunter(hunterId, killer);
    }
    // === end killing mechanic ===

    // === enumeration things ===
    // get unstaked ducks and hunters
    function walletOfOwner(address _owner) public view humansOnly returns (uint256[] memory) {
        return ownerTokens[_owner];
    }

    function balanceOf(address _owner) override public view humansOnly returns(uint256){
        return super.balanceOf(_owner);
    }
    // === end enumeration things ===

    // === admin things ===
    function togglePaused() onlyOwner public{
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function callCeaseFire() public onlyOwner {
        _pause();
        killEnabled = false;
        emit CeaseFire();
    }

    function toggleQuackSale() public onlyOwner {
        quackSale = !quackSale;
    }

    function toggleStealEnabled() public onlyOwner {
        stealEnabled = !stealEnabled;
    }

    function toggleKillEnabled() public onlyOwner {
        killEnabled = !killEnabled;
    }

    function setKillInterval(uint256 _interval) public onlyOwner {
        killInterval = _interval;
    }

    function setKillQuantity(uint256 _quantity) public onlyOwner {
        killQuantity = _quantity;
    }

    function withdraw() public onlyOwner {
        uint256 split = (address(this).balance/1000) * 475;
        payable(0xD59F530a4C970982097Cf2CDf99e94BfD68CCA12).transfer(split);
        payable(0x3E4889cee5b4927BB3209fE43A92b42F32F647Bb).transfer(split);
        payable(0x9c43Ae878298D9Dc994f59CE13C3cF9738aeC0b6).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns(string memory) {
        return baseuri;
    }

    function setBaseURI(string calldata _base) public onlyOwner {
        baseuri = _base;
    }

    function setMaxDucksMintPublicSale(uint256 n) public onlyOwner {
        MAX_DUCKS_MINT_PUBLIC_SALE = n;
    }

    function setMaxDucksMintGame(uint256 n) public onlyOwner {
        MAX_DUCKS_MINT_GAME = n;
    }

    function setMaxKings(uint256 n) public onlyOwner {
        MAX_KING_DUCKS = n;
    }

    // === end admin things ===
    
    function _mint(address to, uint256 tokenId) internal virtual override {
        _tokenIsChanging(tokenId);
        _lockAddress(_msgSender());
        super._mint(to, tokenId);
    }

    /**
    transferFrom overridden to skip manual approval by users (and gas)
    */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override addressBlocked(from) notWhileTokenChanging (tokenId){
        require(_msgSender() == address(dh) || _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: transfer caller is not owner nor approved");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
    _beforeTokenTransfer hooks all transfers to keep track of unstaked tokens as well as users' unstaked tokens
    This hook is called on
    - burn
    - mint
    - transfer
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        bool isDuck = tokenId > MAX_HUNTERS ? true : false;
        bool isKing = tokenId > MAX_DUCKS_MINT_GAME; // if the token is king there is no need to add it to unstaked lists
        // owner balances
        _removeOwnerToken(from, tokenId);
        if (to != address(dh)) {
            // we only add to non dh balances because who cares about what dh holds
            ownerTokens[to].push(tokenId);
        }

        // Stake/unstake things
        if (from == address(dh)) {
            // If not king, add token to unstaked arrays
            if (!isKing) {
                uint256[] storage UNSTAKED = isDuck ? UNSTAKED_DUCKS : UNSTAKED_HUNTERS;
                UNSTAKED.push(tokenId);
                isDuck ? _ducksStaked.decrement() : _huntersStaked.decrement();
            } else {
            // if King, remove from staked kings
                (bool found, uint256 position) = _findUnstakedTokenPosition(tokenId, isDuck, isKing);
                if (found) {
                    _removeUnstakedTokenAtPosition(position, isDuck, isKing);
                }
                _ducksStaked.decrement();
            }

        } else if (to == address(dh)) {
            // remove token from unstaked ducks/hunters
            if (!isKing) {
                isDuck ? _ducksStaked.increment() : _huntersStaked.increment();
                (bool found, uint256 position) = _findUnstakedTokenPosition(tokenId, isDuck, isKing);
                if (found) {
                    _removeUnstakedTokenAtPosition(position, isDuck, isKing);
                }
            } else {
                // add token to staked kings
                STAKED_KINGS.push(tokenId);
                _ducksStaked.increment();
            }
        }

        // mint
        if (from == address(0)) {
            if (!isKing) {
                uint256[] storage UNSTAKED = isDuck ? UNSTAKED_DUCKS : UNSTAKED_HUNTERS;
                UNSTAKED.push(tokenId);
            }
        }

        // burn
        if (to == address(0)) {
            // remove from unstaked
            if (!isKing) {
                (bool found, uint256 position) = _findUnstakedTokenPosition(tokenId, isDuck, isKing);
                if (found) {
                    _removeUnstakedTokenAtPosition(position, isDuck, isKing);
                }
            }
        }
    }

    /** Things I wish I didn't have to do */
    function _tokenIsChanging(uint256 tokenId) internal {
        tokenLastWrites[tokenId] = block.timestamp;
    }

    function _lockAddress(address toLock) internal {
        addressLocks[toLock] = block.timestamp;
    }

    /** checkLockedAddress
    * this is a callback for additional contracts to check whether a specified address should be
    * blocked from performing an action in this block
    */
    function checkLockedAddress(address addressToCheck) view public returns(bool){
        return addressLocks[addressToCheck] == block.timestamp;
    }

    modifier notWhileTokenChanging(uint256 tokenId) {
        require(
            admins[_msgSender()] || 
            (
                tokenLastWrites[tokenId] < block.timestamp &&
                tokenLastWrites[tokenId] != 0
            ), "noooo!");
        _;
    }

    // If an address mints, they are banned from performing this action in the same block
    modifier addressBlocked(address from) {
        require(admins[_msgSender()] || addressLocks[from] < block.timestamp, "noooo.");
        _;
    }

    function ownerOf(uint256 tokenId) public view virtual override humansOnly returns (address) {
        return super.ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override humansOnly returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }

    function approve(address to, uint256 tokenId) public virtual override humansOnly notWhileTokenChanging(tokenId) {
        return super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override humansOnly notWhileTokenChanging(tokenId) returns (address) {
        return super.getApproved(tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override notWhileTokenChanging(tokenId) addressBlocked(from) {
        return super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override notWhileTokenChanging(tokenId) addressBlocked(from) {
        return super.safeTransferFrom(from, to, tokenId, _data);
    }
}