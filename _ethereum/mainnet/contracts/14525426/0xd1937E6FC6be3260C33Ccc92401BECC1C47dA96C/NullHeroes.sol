// contracts/NullHeroes.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 *       __   __     __  __     __         __
 *      /\ "-.\ \   /\ \/\ \   /\ \       /\ \
 *      \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
 *       \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
 *    www.\/_/ \/_/   \/_____/   \/_____/   \/_____/
 *       __  __     ______     ______     ______     ______     ______
 *      /\ \_\ \   /\  ___\   /\  == \   /\  __ \   /\  ___\   /\  ___\
 *      \ \  __ \  \ \  __\   \ \  __<   \ \ \/\ \  \ \  __\   \ \___  \
 *       \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_____\  \/\_____\
 *        \/_/\/_/   \/_____/   \/_/ /_/   \/_____/   \/_____/   \/_____/.io
 *
 *
 *  Somewhere in the metaverse the null heroes compete to farm the
 *  $LEGENDZ token, an epic ERC20 token that only the bravest will be able
 *  to claim.
 *
 *  Enroll some heroes and start farming the $LEGENDZ tokens now on:
 *  https://www.nullheroes.io
 *
 *  - OpenSea is already approved for transactions to spare gas fees
 *  - NullHeroes and related staking contracts are optimized for low gas fees,
 *    at least as much as I could :)
 *
 *  made with love by Stigmatix@github
 *  special credits: NuclearNerds, WolfGame
 *
 */

import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./LEGENDZ.sol";

error NonExistentToken();
error LevelMax();
error TooMuchTokensPerTx();
error NotEnoughTokens();
error NotEnoughGiveaways();
error SaleNotStarted();
error NotEnoughEther();
error NotEnoughLegendz();

contract NullHeroes is ERC721Enumerable, Ownable, Pausable {

    // hero struct
    struct Hero {
        uint8 level;
        uint8 class;
        uint8 race;
        uint8 force;
        uint8 intelligence;
        uint8 agility;
    }

    // max heroes
    uint256 public constant MAX_TOKENS = 40000;

    // genesis heroes (25% of max heroes)
    uint256 public constant MAX_GENESIS_TOKENS = 10000;

    // giveaways (5% of genesis heroes)
    uint256 public constant MAX_GENESIS_TOKENS_GIVEAWAYS = 500;

    // max per tx
    uint256 public constant MAX_TOKENS_PER_TX = 10;

    uint256 public MINT_GENESIS_PRICE = .06942 ether;

    uint256 public MINT_PRICE = 70000;

    // giveaways counter
    uint256 public giveawayGenesisTokens;

    // $LEGENDZ token contract
    LEGENDZ private legendz;

    // pre-generated list of traits distributed by weight
    uint8[][3] private traits;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => Hero) public heroes;

    // mapping from proxy address to authorization
    mapping(address => bool) private proxies;

    address private proxyRegistryAddress;

    address private accountingAddress;

    string private baseURI;

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _accountingAddress,
        address _legendz
    )
    ERC721("NullHeroes","NULLHEROES")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        accountingAddress = _accountingAddress;
        legendz = LEGENDZ(_legendz);

        // classes - warrior: 0 | rogue: 1 | wizard: 2 | cultist: 3 | mercenary: 4 | ranger: 5
        traits[0] = [1, 5, 3, 2, 4, 0];

        // races - human: 0 | orc: 1 | elf: 2 | undead: 3 | ape: 4 | human: 5
        traits[1] = [5, 0, 1, 3, 5, 0, 1, 4, 1, 5, 2, 0, 3, 0, 1, 5];

        // base attribute points - 1 to 6
        traits[2] = [1, 2, 3, 2, 2, 5, 1, 3, 2, 4, 1, 1, 2, 2, 3, 2, 5, 3, 6, 2, 2, 4, 3, 1, 3, 1, 4, 1, 1, 2, 1, 4, 2, 1, 3, 1, 2, 1, 2, 1, 1];
    }

    /**
     * mints genesis heroes for the sender
     * @param amount the amount of heroes to mint
     */
    function enrollGenesisHeroes(uint256 amount) external payable whenNotPaused {
        uint256 totalSupply = _owners.length;
        if (totalSupply >= MAX_GENESIS_TOKENS) revert NotEnoughTokens();
        if (amount > MAX_TOKENS_PER_TX) revert TooMuchTokensPerTx();
        if (msg.value < MINT_GENESIS_PRICE * amount) revert NotEnoughEther();

        uint256 seed = _random(totalSupply);
        for (uint i; i < amount; i++) {
            heroes[i + totalSupply] = _generate(seed >> i, true);
            _mint(_msgSender(), i + totalSupply);
        }
    }

    /**
     * mints heroes for the sender
     * @param amount the amount of heroes to mint
     */
    function enrollHeroes(uint256 amount) external whenNotPaused {
        uint256 totalSupply = _owners.length;
        if (totalSupply < MAX_GENESIS_TOKENS) revert SaleNotStarted();
        if (totalSupply + amount > MAX_TOKENS) revert NotEnoughTokens();
        if (amount > MAX_TOKENS_PER_TX) revert TooMuchTokensPerTx();

        // check $LEGENDZ balance
        uint balance = legendz.balanceOf(_msgSender());
        uint cost = MINT_PRICE * amount;

        if (cost > balance) revert NotEnoughLegendz();

        // burn $LEGENDZ
        legendz.burn(_msgSender(), cost);

        uint256 seed = _random(totalSupply);
        for (uint i; i < amount; i++) {
            heroes[i + totalSupply] = _generate(seed >> i, false);
            _mint(_msgSender(), i + totalSupply);
        }
    }

    /**
     * mints free genesis heroes for a community member
     * @param amount the amount of genesis heroes to mint
     * @param recipient address of the recipient
     */
    function enrollGenesisHeroesForGiveaway(address recipient, uint256 amount) external onlyOwner whenNotPaused {
        uint256 totalSupply = _owners.length;
        if (totalSupply >= MAX_GENESIS_TOKENS) revert NotEnoughTokens();
        if (amount > MAX_TOKENS_PER_TX) revert TooMuchTokensPerTx();
        if (giveawayGenesisTokens + amount > MAX_GENESIS_TOKENS_GIVEAWAYS) revert NotEnoughGiveaways();

        giveawayGenesisTokens += amount;

        uint256 seed = _random(totalSupply);
        for (uint i; i < amount; i++) {
            heroes[i + totalSupply] = _generate(seed >> i, true);
            _mint(recipient, i + totalSupply);
        }
    }

    /**
     * generates a hero
     * @param seed a seed
     * @param isGenesis genesis flag
     */
    function _generate(uint256 seed, bool isGenesis) private view returns (Hero memory h) {

        h.level = 1;

        h.class = _selectTrait(uint16(seed), 0);
        seed >>= 16;
        h.race = _selectTrait(uint16(seed), 1);
        seed >>= 16;

        h.force = _selectTrait(uint16(seed), 2);
        seed >>= 16;
        h.intelligence = _selectTrait(uint16(seed), 2);
        seed >>= 16;
        h.agility = _selectTrait(uint16(seed), 2);

        // add race modifiers
        if (h.race == 0 || h.race == 5) { // human
            h.force += 2;
            h.intelligence += 2;
            h.agility += 2;
        } else if (h.race == 1) { // orc
            h.force += 4;
            h.agility += 2;
        } else if (h.race == 3) { // undead
            h.force += 7;
            h.intelligence += 3;
        } else if (h.race == 2) { // elf
            h.force += 3;
            h.intelligence += 7;
            h.agility += 7;
        } else if (h.race == 4) { // ape
            h.force += 9;
            h.intelligence -= 1;
            h.agility += 9;
        }

        // add class modifiers
        if (h.class == 0) { // warrior
            h.force += 9;
        } else if (h.class == 1) { // rogue
            h.force += 3;
            h.agility += 7;
        } else if (h.class == 2) { // wizard
            h.agility += 4;
            h.force += 1;
            h.intelligence += 6;
        } else if (h.class == 3) { // cultist
            h.intelligence += 9;
        } else if (h.class == 4) { // mercenary
            h.force += 4;
            h.intelligence += 4;
            h.agility += 4;
        } else if (h.class == 5) { // ranger
            h.intelligence += 3;
            h.agility += 7;
        }

        // add genesis modifier
        if (isGenesis) {
            h.force += 1;
            h.agility += 1;
            h.intelligence += 1;
        }
    }

    /**
     * selects a random trait
     * @param seed portion of the 256 bit seed
     * @param traitType the trait type
     * @return the index of the randomly selected trait
     */
    function _selectTrait(uint256 seed, uint256 traitType) private view returns (uint8) {
        if (seed < traits[traitType].length)
            return traits[traitType][seed];
        return traits[traitType][seed % traits[traitType].length];
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function _random(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * transfers an array of tokens
     * @param _from the current owner
     * @param _to the new owner
     * @param _tokenIds the array of token ids
     */
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) public {
        for (uint i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    /**
     * transfers an array of tokens
     * @param _from the current owner
     * @param _to the new owner
     * @param _tokenIds the ids of the tokens
     * @param _data the transfer data
     */
    function batchSafeTransferFrom(address _from, address _to, uint256[] calldata _tokenIds, bytes memory _data) public {
        for (uint i; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], _data);
        }
    }

    /**
     * level up a hero
     * @param tokenId the id of the token
     * @param attribute the attribute to update - force: 0 | intelligence: 1 | agility: 2
     */
    function levelUp(uint256 tokenId, uint8 attribute) external {
        if (!proxies[_msgSender()]) revert OnlyAuthorizedOperators();
        if (!_exists(tokenId)) revert NonExistentToken();
        if (heroes[tokenId].level > 99) revert LevelMax();

        heroes[tokenId].level += 1;
        if (attribute == 0)
            heroes[tokenId].force += 1;
        else if (attribute == 1)
            heroes[tokenId].intelligence += 1;
        else if (attribute == 2)
            heroes[tokenId].agility += 1;
    }

    /**
     * gets a hero token
     * @param tokenId the id of the token
     * @return a hero struct
     */
    function getHero(uint256 tokenId) public view returns (Hero memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
        return heroes[tokenId];
    }

    /**
     * gets the tokens of an owner
     * @param owner owner's address
     * @return an array of the corresponding owner's token ids
     */
    function tokensOfOwner(address owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensIds = new uint256[](tokenCount);
        for (uint i; i < tokenCount; i++) {
            tokensIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return baseURI;
    }

    /**
     * updates base URI
     * @param _baseURI the new base URI
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * updates proxy registry address
     * @param _proxyRegistryAddress proxy registry address
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * sets a proxy's authorization
     * @param proxyAddress address of the proxy
     * @param authorized the new authorization value
     */
    function setProxy(address proxyAddress, bool authorized) external onlyOwner {
        proxies[proxyAddress] = authorized;
    }

    /**
     * burns a token
     * @param tokenId the id of the token
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "not approved to burn");
        _burn(tokenId);
    }

    /**
     * withdraws from contract's balance
     */
    function withdraw() public onlyOwner {
        (bool success, ) = accountingAddress.call{value: address(this).balance}("");
        require(success, "failed to send balance");
    }

    /**
     * enables the contract's owner to pause / unpause minting
     * @param paused the new pause flag
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /**
     * updates the genesis mint price
     * @param price new price
     */
    function updateGenesisMintPrice(uint256 price) external onlyOwner {
        MINT_GENESIS_PRICE = price;
    }

    /**
     * updates the mint price
     * @param price new price
     */
    function updateMintPrice(uint256 price) external onlyOwner {
        MINT_PRICE = price;
    }

    /**
     * overrides approvals to avoid opensea and operator contracts to generate approval gas fees
     * @param _owner the current owner
     * @param _operator the operator
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || proxies[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
