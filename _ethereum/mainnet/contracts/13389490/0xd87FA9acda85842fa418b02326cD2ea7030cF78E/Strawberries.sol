// contracts/Strawberries.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./ISeeds.sol";
import "./FruitsLibrary.sol";

contract Strawberries is ERC721Enumerable {

    /**
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMMMMWKkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkKWMMMMMMMMMMMM
    MMMMMMMMWKOkdc'..................................'cdkOKWMMMMMMMM
    MMMMMMWKx:...',;,'''''''''''''''''''''''''''''',;,'...:xKWMMMMMM
    MMMMWKx:......',;;,,'''''''''''''''''''''''',,;;,'......:xKWMMMM
    MMWKx:..........',;;,,,,,,,,,,,,,,,,,,,,,,,,;;,'..........:xKWMM
    WKx:..............',;:;;;;;;;;;;;;;;;;;;;;:;,'..............:xKW
    No............................................................oN
    Xl. ..........''''''''''''''''''''''''''''''''''''.......... .lX
    Xl. ........,oO0000000000000000000000000000000000Oo,........ .lX
    Xl. ......,oOKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKOo,...... .lX
    Xl. ... .:kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. .....,oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo,..... .lX
    Xl. ..... .c0XXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXX0c. ..... .lX
    Xl. .......,oOKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKOo,....... .lX
    Xl. .........,oOKXXKKKKKKKKKKKKKKKKKKKKKKKKKKXXKOo,......... .lX
    Xl. ...........,oOKXKKKKKKKKKKKKKKKKKKKKKKKKXKOo,........... .lX
    Xl. .............,oOKXXXXXXXXXXXXXXXXXXXXXXKOo,............. .lX
    Nk:................,looooooooooooooooooooool,................:kN
    MWKc. .................................................... .cKWM
    MMNk:..............,;;;;;;;;;;;;;;;;;;;;;;;;,..............:kNMM
    MMMWXx;.............','''''''''''''''''''','.............;xXWMMM
    MMMMMWXx:...........''''''''''''''''''''''''...........:xXWMMMMM
    MMMMMMMWXx:;,......................................,;:xXWMMMMMMM
    MMMMMMMMMWNX0c.                                  .c0XNWMMMMMMMMM

    :cheese::astronaut::cheese: RIP 7767 :cheese::astronaut::cheese:
    **/
    using FruitsLibrary for uint8;
    struct Trait {
        string traitName;
        string traitType;
        string traitLayout;
        string traitColors;
    }
    //Mappings
    mapping(string => bool) hashToMinted;
    mapping(uint256 => string) internal tokenIdToHash;
    mapping(bytes => Trait[]) public traitTypes;
    uint32 currentMappingVersion;
    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 MINTS_PER_TIER = 3000;
    uint256 SEEDS_NONCE = 0;
    // Price
    uint256 public price = 50000000000000000; // 0.05 eth
    //uint arrays
    uint16[][5] TIERS;
    //address
    address seedsAddress;
    address _owner;

    constructor() ERC721("Strawberries", "STRBRY") {
        _owner = msg.sender;
        //Declare all the rarity tiers
        //Hat
        TIERS[0] = [50, 100, 300, 500, 1250, 1500, 1600, 2200, 2500];
        //Eyes
        TIERS[1] = [100, 200, 400, 500, 700, 1000, 1100, 1200, 1300, 1400, 2100];
        //Mouth
        TIERS[2] = [100, 300, 600, 900, 1250, 1750, 2350, 2750];
        //Base
        TIERS[3] = [50, 100, 250, 400, 500, 600, 600, 800, 1000, 1200, 1500, 3000];
        //Background
        TIERS[4] = [100, 100, 100, 400, 500, 1300, 1500, 6000];
    }

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
    internal
    view
    returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ){
                return i.toString();
            }
            currentLowerBound = currentLowerBound + thisPercentage;
        }
        revert();
    }

    /**
     * @dev Generates a 9 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);
        // This will generate a 8 character string.
        //The last 7 digits are random, the first two are 00, due to the strawberry not being burned.
        string memory currentHash = "00";
        for (uint8 i = 0; i < 5; i++) {
            SEEDS_NONCE++;
            uint16 _randinput = uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEEDS_NONCE
                        )
                    )
                ) % 10000
            );
            currentHash = string(
                abi.encodePacked(currentHash, FruitsLibrary.slice(
                    string(abi.encodePacked("00",rarityGen(_randinput, i))),2
                ))
            );
        }
        if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);
        return currentHash;
    }

    /**
     * @dev Returns the current seeds cost of minting.
     */
    function currentSeedsCost() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply <= 3000) return 1000000000000000000;
        if (_totalSupply > 3000 && _totalSupply <= 4000)
            return 1000000000000000000;
        if (_totalSupply > 4000 && _totalSupply <= 6000)
            return 2000000000000000000;
        if (_totalSupply > 6000 && _totalSupply <= 8000)
            return 3000000000000000000;
        if (_totalSupply > 8000 && _totalSupply <= 10000)
            return 4000000000000000000;
        revert();
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        uint256 _totalSupply = totalSupply();
        require((_totalSupply < MAX_SUPPLY) && (!FruitsLibrary.isContract(msg.sender)));
        uint256 thisTokenId = _totalSupply;
        tokenIdToHash[thisTokenId] = hash(thisTokenId, msg.sender, 0);
        hashToMinted[tokenIdToHash[thisTokenId]] = true;
        _mint(msg.sender, thisTokenId);
    }

    /**
     * @dev Mints new tokens.
     */
    function mintStrawberry(uint256 _times) public payable {
        require((_times > 0 && _times <= 20) && (msg.value == _times * price) && (totalSupply() < MINTS_PER_TIER), "Check values.");
        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
    }

    /**
     * @dev Mints new tokens.
     */
    function mintStrawberryWithSeeds(uint256 _times) public {
        require((_times > 0 && _times <= 20));
        //Burn this much seeds
        ISeeds(seedsAddress).burnFrom(msg.sender, currentSeedsCost()*_times);
        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
        return;
    }

    /**
     * @dev Burns and mints new.
     * @param _tokenId The token to burn.
     */
    function burnForMint(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );
        mintInternal();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
    public
    view
    returns (string memory)
    {
        string memory traitLayout;
        string memory traitColors;
        uint index = (uint8(bytes(_hash).length)/2)-1;
        for (uint8 i = 0; i < bytes(_hash).length; i+=2) {
            uint8 thisTraitIndex = FruitsLibrary.parseInt(
                FruitsLibrary.substring(_hash, index*2, (index*2) + 2)
            );
            Trait storage trait = traitTypes[abi.encodePacked(currentMappingVersion, index)][thisTraitIndex];
            traitLayout = string(abi.encodePacked(traitLayout,trait.traitLayout));
            traitColors = string(abi.encodePacked(traitColors,trait.traitColors));
            if(index > 0){
                index--;
            }
        }
        return string(
            abi.encodePacked(
                '<svg style="shape-rendering: crispedges;" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32"> ',
                traitLayout,
                "<style>rect{width:1px;height:1px;}",
                traitColors,
                "</style></svg>"
            )
        );
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
    public
    view
    returns (string memory)
    {
        string memory metadataString;
        uint index = 0;
        for (uint8 i = 0; i < bytes(_hash).length; i+=2) {
            uint8 thisTraitIndex = FruitsLibrary.parseInt(
                FruitsLibrary.substring(_hash, i, i + 2)
            );
            Trait storage trait = traitTypes[abi.encodePacked(currentMappingVersion, index)][thisTraitIndex];
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    trait.traitType,
                    '","value":"',
                    trait.traitName,
                    '"}'
                )
            );
            if (index != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
            index++;
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                FruitsLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Strawberries #',
                                FruitsLibrary.toString(_tokenId),
                                '", "description": "A collection of 10,000 unique strawberries. All the metadata and images are generated and stored on-chain. No IPFS, no API. Just the blockchain.", "image": "data:image/svg+xml;base64,',
                                FruitsLibrary.encode(
                                    bytes(hashToSVG(tokenHash))
                                ),
                                '","attributes":',
                                hashToMetadata(tokenHash),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
    public
    view
    returns (string memory)
    {
        string memory tokenHash = tokenIdToHash[_tokenId];
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "01",
                    FruitsLibrary.substring(tokenHash, 2, 12)
                )
            );
        }
        return tokenHash;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function getTraits(uint256 _traitTypeIndex) internal returns(Trait[] storage) {
        return traitTypes[abi.encodePacked(currentMappingVersion, _traitTypeIndex)];
    }

    /*function setTraits(uint256 _traitTypeIndex, Trait[] memory _traits) internal {
        traitTypes[abi.encodePacked(currentMappingVersion, _traitTypeIndex)] = _traits;
    }*/

    function clearTraits() external onlyOwner {
        currentMappingVersion++;
    }

    /**
     * @dev Recover gas for deleted traits
     * @param _version The version of traits to delete
     * @param _traitTypeIndex The trait type index
     */

    function recoverGas(uint32 _version, uint256 _traitTypeIndex) external onlyOwner {
        require(_version < currentMappingVersion);
        delete(traitTypes[abi.encodePacked(_version, _traitTypeIndex)]);
    }

    /**
     * @dev Add trait types
     * @param _traitTypeIndex The trait type index
     * @param traits to add
     */

    function addTraitTypes(uint256 _traitTypeIndex, Trait[] memory traits)
    public
    onlyOwner
    {
        for(uint i = 0; i < traits.length; i++){
            getTraits(_traitTypeIndex).push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].traitLayout,
                    traits[i].traitColors
                )
            );
        }
        return;
    }

    /**
     * @dev Add to a trait type
     * @param _traitTypeIndex The trait type index
     * @param _traitIndex The trait index
     * @param traitLayout to add
     */

    function addTraitLayoutChunk(uint256 _traitTypeIndex, uint256 _traitIndex, string memory traitLayout)
    public
    onlyOwner
    {
        Trait storage oldTrait = getTraits(_traitTypeIndex)[_traitIndex];
        getTraits(_traitTypeIndex)[_traitIndex] = Trait(
            oldTrait.traitName,
            oldTrait.traitType,
            string(abi.encodePacked(oldTrait.traitLayout,traitLayout)),
            oldTrait.traitColors
        );
        return;
    }

    /**
     * @dev Sets the seeds ERC20 address
     * @param _seedsAddress The seed address
     */

    function setSeedsAddress(address _seedsAddress) public onlyOwner {
        seedsAddress = _seedsAddress;
    }

    /**
     * @dev Withdraws balance
     */

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return "https://www.thefruitnft.com/strawberry.json";
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}
