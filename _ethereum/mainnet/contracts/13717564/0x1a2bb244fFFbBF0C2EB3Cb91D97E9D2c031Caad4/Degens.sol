// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IDegens.sol";
import "./IFortress.sol";
import "./ITraits.sol";
import "./IGains.sol";

contract Degens is IDegens, ERC721Enumerable, Ownable, Pausable {

    // mint price
    uint256 public MINT_PRICE = .069420 ether;
    // max number of tokens that can be minted - 50000 in production
    uint256 public immutable MAX_TOKENS;
    // number of tokens that can be claimed for free - 20% of MAX_TOKENS
    uint256 public PAID_TOKENS;
    // number of tokens have been minted so far
    uint16 public minted;

    bool isOGMintEnabled = true;
    bool isNFTOwnerWLEnabled = false;
    bool isPublicSaleEnabled = false;
    mapping(address => uint256) public whitelists;
    address[11] public extNftContractAddressWhitelists;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => IDegens.Degen) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    //eff ajwalkers algo
    uint8[8][4] rarities;

    // reference to the fortress for choosing random zombie thieves
    IFortress public fortress;
    // reference to $Gains for burning on mint
    IGains public gains;
    // reference to Traits
    ITraits public traits;

    /**
     * instantiates contract and rarity tables
     */
    constructor(address _gains, address _traits, uint256 _maxTokens) ERC721("Game of Degens", 'GOD') {
        gains = IGains(_gains);
        traits = ITraits(_traits);
        MAX_TOKENS = _maxTokens;
        PAID_TOKENS = _maxTokens / 5;

        //accessories
        //clothes
        //eyes
        //background
        //mouth
        //body
        //hairdo
        //alphaIndex

        //bull
        rarities[0] = [16, 13, 9, 23, 9, 10, 0, 0];
        //bear
        rarities[1] = [16, 9, 3, 23, 6, 8, 0, 0];
        //ape
        rarities[2] = [16, 8, 4, 23, 8, 7, 0, 0];
        //zombie
        rarities[3] = [16, 13, 3, 23, 0, 1, 7, 4];

        //neotoken
        extNftContractAddressWhitelists[0] = 0x86357A19E5537A8Fba9A004E555713BC943a66C0;
        //fluf
        extNftContractAddressWhitelists[1] = 0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d;
        //ppg
        extNftContractAddressWhitelists[2] = 0xBd3531dA5CF5857e7CfAA92426877b022e612cf8;
        //doggy
        extNftContractAddressWhitelists[3] = 0xF4ee95274741437636e748DdAc70818B4ED7d043;
        //doodle
        extNftContractAddressWhitelists[4] = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
        //toadz
        extNftContractAddressWhitelists[5] = 0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6;
        //cool
        extNftContractAddressWhitelists[6] = 0x1A92f7381B9F03921564a437210bB9396471050C;
        //kongz
        extNftContractAddressWhitelists[7] = 0x57a204AA1042f6E66DD7730813f4024114d74f37;
        //bayc
        extNftContractAddressWhitelists[8] = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        //cryptopunkz
        extNftContractAddressWhitelists[9] = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        //mayc
        extNftContractAddressWhitelists[10] = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    }

    /** EXTERNAL */

    function addOGsToWhitelist(address[] calldata addressArrays) external onlyOwner {
        uint256 addylength = addressArrays.length;
        for (uint256 i; i < addylength; i++) {
            whitelists[addressArrays[i]] = 1;
        }
    }

    function enableOGWLMint() external onlyOwner {
        isOGMintEnabled = true;
        isNFTOwnerWLEnabled = false;
        isPublicSaleEnabled = false;
        MINT_PRICE = .069420 ether;
    }

    function enableOtherNFTOwnerWLMint() external onlyOwner {
        isOGMintEnabled = false;
        isNFTOwnerWLEnabled = true;
        isPublicSaleEnabled = false;
        MINT_PRICE = .069420 ether;
    }

    function enablePublicMint() external onlyOwner {
        isOGMintEnabled = false;
        isNFTOwnerWLEnabled = false;
        isPublicSaleEnabled = true;
        MINT_PRICE = .069420 ether;
    }

    function getNFTBalance(address contrct, address acc) internal view returns (uint256 balance){
        balance = 0;
        try IERC721(contrct).balanceOf(acc) returns (uint256 _balance){
            balance = _balance;
        } catch {
            balance = 0;
        }
        return balance;
    }

    function isWLBasisNFTOwner(address acc) external view returns (bool) {
        for (uint i = 0; i < extNftContractAddressWhitelists.length; i++) {
            if (getNFTBalance(extNftContractAddressWhitelists[i], acc) > 0) {
                return true;
            }
        }
        return false;
    }

    function isWLBasisOG(address acc) external view returns (bool){
        return whitelists[acc] == 1;
    }

    function getMintMode() external view returns (bool, bool, bool){
        return (isOGMintEnabled, isNFTOwnerWLEnabled, isPublicSaleEnabled);
    }

    /**
     * mint a token - 90% Degens, 10% Zombies
     * The first 20% are free to claim, the remaining cost $GAINS
     */
    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (minted < PAID_TOKENS) {
            require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
            require(amount * MINT_PRICE <= msg.value, "Invalid payment amount");

            if (!isPublicSaleEnabled) {
                if (isOGMintEnabled) {
                    require(this.isWLBasisOG(_msgSender()), "Only open for whitelist");
                } else if (isNFTOwnerWLEnabled) {
                    require(this.isWLBasisNFTOwner(_msgSender()), "Only open for special peeps at the moment");
                }
            }

        } else {
            require(msg.value == 0);
        }

        uint256 totalGainsCost = 0;
        uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
        uint256 seed;
        for (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            address recipient = selectRecipient(seed);
            if (!stake || recipient != _msgSender()) {
                _safeMint(recipient, minted);
            } else {
                _safeMint(address(fortress), minted);
                tokenIds[i] = minted;
            }
            totalGainsCost += mintCost(minted);
        }

        if (totalGainsCost > 0) gains.burn(_msgSender(), totalGainsCost);
        if (stake) fortress.addDegensToFortressAndHorde(_msgSender(), tokenIds);
    }

    /**
     * the first 20% are paid in ETH
     * the next 20% are 20000 $GAINS
     * the next 40% are 40000 $GAINS
     * the final 20% are 80000 $GAINS
     * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= PAID_TOKENS) return 0;
        if (tokenId <= MAX_TOKENS * 2 / 5) return 20000 ether;
        if (tokenId <= MAX_TOKENS * 4 / 5) return 40000 ether;
        return 80000 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721) {
        // Hardcode the fortress's approval so that users don't have to waste gas approving
        if (_msgSender() != address(fortress))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
    function generate(uint256 tokenId, uint256 seed) internal returns (IDegens.Degen memory t) {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
   * @param traitType the trait type to select a trait for
   * @return the ID of the randomly selected trait
   */
    function selectTrait(uint16 seed, uint8 traitType, uint8 degenType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[degenType][traitType]);
        return trait;
    }

    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked zombie
     * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the zombie thief's owner)
   */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender();
        // top 10 bits haven't been used
        address thief = fortress.randomZombieOwner(seed >> 144);
        // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t -  a struct of randomly selected traits
   */
    function selectTraits(uint256 seed) internal view returns (IDegens.Degen memory t) {
        bool isZombie = uint8((seed & 0xFFFF) % 10) == 0;
        t.degenType = isZombie ? 3 : uint8((seed & 0xFFFF) % 3);
        seed >>= 16;
        t.accessories = selectTrait(uint16(seed & 0xFFFF), 0, t.degenType);
        seed >>= 16;
        t.clothes = selectTrait(uint16(seed & 0xFFFF), 1, t.degenType);
        seed >>= 16;
        t.eyes = selectTrait(uint16(seed & 0xFFFF), 2, t.degenType);
        seed >>= 16;
        t.background = selectTrait(uint16(seed & 0xFFFF), 3, 0);
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 5, t.degenType);

        if (!this.isZombies(t)) {
            seed >>= 16;
            t.mouth = selectTrait(uint16(seed & 0xFFFF), 4, t.degenType);
        } else {
            seed >>= 16;
            t.hairdo = selectTrait(uint16(seed & 0xFFFF), 6, t.degenType);
            seed >>= 16;
            t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 7, t.degenType);
        }
        return t;
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
   * @return the 256 bit hash of the struct
   */
    function structToHash(IDegens.Degen memory s) internal pure returns (uint256) {
        return uint256(bytes32(
                abi.encodePacked(
                    s.degenType,
                    s.accessories,
                    s.clothes,
                    s.eyes,
                    s.background,
                    s.mouth,
                    s.body,
                    s.hairdo,
                    s.alphaIndex
                )
            ));
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                seed
            )));
    }

    /** READ */

    function getTokenTraits(uint256 tokenId) external view override returns (Degen memory) {
        return tokenTraits[tokenId];
    }

    function getPaidTokens() external view override returns (uint256) {
        return PAID_TOKENS;
    }

    function isBull(Degen memory _degen) external pure override returns (bool){
        return _degen.degenType == 0;
    }

    function isBears(Degen memory _degen) external pure override returns (bool){
        return _degen.degenType == 1;
    }

    function isApes(Degen memory _degen) external pure override returns (bool){
        return _degen.degenType == 2;
    }

    function isZombies(Degen memory _degen) external pure override returns (bool){
        return _degen.degenType == 3;
    }

    function getNFTName(Degen memory _degen) external view override returns (string memory){
        if (this.isZombies(_degen)) {
            return "Zombie";
        }
        else {
            return "Degen";
        }
    }

    function getDegenTypeName(Degen memory _degen) external view override returns (string memory){
        if (this.isBull(_degen)) {
            return "Bull";
        }
        else if (this.isBears(_degen)) {
            return "Bear";
        }
        else if (this.isZombies(_degen)) {
            return "Zombie";
        }
        else if (this.isApes(_degen)) {
            return "Ape";
        }

        return "Error";
    }

    function getNFTGeneration(uint256 tokenId) external pure returns (string memory){
        if (tokenId >= 1 && tokenId < 3333) {
            return "Gen 0";
        }
        else if (tokenId >= 3333 && tokenId < 6666) {
            return "Gen 1";
        }
        else if (tokenId >= 6666 && tokenId < 13333) {
            return "Gen 2";
        }
        else if (tokenId >= 13333 && tokenId <= 16666) {
            return "Gen X";
        }

        return "Error";
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random zombie thieves
     * @param _fortress the address of the fortress
   */
    function setFortressContractAddress(address _fortress) external onlyOwner {
        fortress = IFortress(_fortress);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setPaidTokens(uint256 _paidTokens) external onlyOwner {
        PAID_TOKENS = _paidTokens;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

}
