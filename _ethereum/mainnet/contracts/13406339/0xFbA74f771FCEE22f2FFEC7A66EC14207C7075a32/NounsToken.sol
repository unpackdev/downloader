// SPDX-License-Identifier: GPL-3.0

/// @title The Fast Food Nouns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░████████████░░░░░░░░░░░ *
 * ░░░░░░██████░█░███░░░░░░░░░░░ *
 * ░░░░███████░█░█░██████░░░░░░░ *
 * ░░░████████░░░░░██████░░░░░░░ *
 * ░░░████████████████████████░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./INounsDescriptor.sol";
import "./INounsSeeder.sol";
import "./INounsToken.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./IProxyRegistry.sol";
import "./Strings.sol";
import "./base64.sol";
import "./console.sol";

contract FastFoodNouns is INounsToken, Ownable, ERC721Enumerable {
    using Strings for uint256;

    uint256 public price = 30000000000000000; // .03 eth
    uint256 public max_tokens = 1000;
    uint256 public mint_limit= 20;

    string public tokenDescription = '"Can I take your order?" Fast Food Nouns work at the drive-thru, and spend all their hard earned cash on new clothes and bling.';

    string public hatSVG = '<rect width="160" height="10" x="80" y="80" fill="#E11833"/><rect width="120" height="10" x="90" y="60" fill="#E11833"/><rect width="100" height="10" x="100" y="50" fill="#E11833"/><rect width="100" height="10" x="100" y="40" fill="#E11833"/><rect width="130" height="10" x="80" y="70" fill="#BD2D24"/><rect width="50" height="10" x="140" y="70" fill="#EED811"/><rect width="10" height="10" x="140" y="60" fill="#EED811"/><rect width="10" height="10" x="150" y="50" fill="#EED811"/><rect width="10" height="10" x="160" y="60" fill="#EED811"/><rect width="10" height="10" x="170" y="50" fill="#EED811"/><rect width="10" height="10" x="180" y="60" fill="#EED811"/>';

    // An array of publicly available clothes (SVG snippets)
    string[] public clothingList;

    // Tracks state of clothing per tokenId. Example: Noun #0 is wearing 3 items
    // of clothing at `clothingList` index 4, 9, and 14. This will represented
    // as `clothingState[0][4,9,14]`.
    mapping (uint256 => uint256[]) public clothingState;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // The Nouns seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal tokenId tracker
    uint256 private _currentNounId;

    // IPFS content hash of contract-level metadata. For OpenSea description.
    string private _contractURIHash = '';

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // Sale status
    bool public sale_active = false;

    // Specifies clothes owner would like to wear. Overwrites existing selections,
    // so always include every items you'd like to wear.
    function wearClothes(uint256 tokenId, uint256[] calldata clothes) public returns (string memory) {
        require (msg.sender == ownerOf(tokenId), "not your Noun");
        clothingState[tokenId] = clothes;
        return 'Updated your clothing';
    }

    // Add clothes to the list of publicly available clothes
    function addClothes(string calldata svgSnippet) public onlyOwner returns (string memory) {
        clothingList.push(svgSnippet);
        return 'Updated clothing list';
    }

    // Replace clothing at a specific index
    function setClothesAtIndex(uint256 index, string calldata svgSnippet) public onlyOwner returns (string memory) {
        clothingList[index] = svgSnippet;
        return 'Updated clothing list';
    }

    // Return the list of clothes selected for a given tokenId
    function getClothesForTokenId(uint256 tokenId) public view returns (uint[] memory) {
        return clothingState[tokenId];
    }

    constructor() ERC721('Fast Food Nouns', 'FFN') {
        // Populate `clothingList` with fast food hat
        clothingList.push(hatSVG);

        // Mainnet addresses
        descriptor = INounsDescriptor(0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63);
        seeder = INounsSeeder(0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515);
        proxyRegistry = IProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

    }

    /**
     * @notice Withdraw contract balance to team.
     */
    function withdrawAll() public {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash. For OpenSea collection description.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    function toggleSale() external onlyOwner {
        sale_active=!sale_active;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint Nouns to sender
     */
    function mint(uint256 num_tokens) external override payable {

        require (sale_active,"sale not active");

        require (num_tokens<=mint_limit,"minted too many");

        require(num_tokens+totalSupply()<=max_tokens,"exceeds maximum tokens");

        require(msg.value>=num_tokens*price,"not enough ethers sent");

        for (uint256 x=0;x<num_tokens;x++) {
            _mintTo(msg.sender, _currentNounId++);
        }
    }

    /**
     * @notice Burn a Noun.
     */
    function burn(uint256 nounId) public override onlyOwner {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    // Let owner update the description that appears for each Fast Food Noun
    // so we can make it better if we need to.
    function updateTokenDescription(string calldata newDescription) public onlyOwner returns (string memory) {
        tokenDescription = newDescription;
        return 'Description updated';
    }

    /**
     * @notice Compose tokenURI for a Noun. Fetches original SVG, adds clothes.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'nonexistent token');
        string memory NounID = tokenId.toString();
        string memory name = string(abi.encodePacked('Fast Food Noun ', NounID));
        string memory description = tokenDescription;

        // Fetch the original SVG (base64 encoded) from Nouns descriptor
        string memory SVG = descriptor.generateSVGImage(seeds[tokenId]);
        // Decode base64 SVG into bytes
        bytes memory decodedSVG = Base64.decode(SVG);
        // Remove the SVG closing tag `</svg>`
        string memory substring = removeLastSVGTag(decodedSVG);
        // Encode substring bytes
        bytes memory finalSVGBytes = abi.encodePacked(substring);
        // Loop through clothes for this tokenId and encode them in
        for (uint256 i = 0; i < clothingState[tokenId].length; i++) {
            uint256 clothingIndexToAdd = clothingState[tokenId][i];
            // Encode the clothing bytes for these clothes
            finalSVGBytes = abi.encodePacked(finalSVGBytes, clothingList[clothingIndexToAdd]);
        }
        // Finally, encode the closing SVG tag in
        finalSVGBytes = abi.encodePacked(finalSVGBytes, '</svg>');
        // Rencode SVG to base64
        string memory encodedFinalSVG = Base64.encode(finalSVGBytes);
        // Compose json string
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', encodedFinalSVG, '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice Set the token URI descriptor.
     */
    function setDescriptor(INounsDescriptor _descriptor) external override onlyOwner {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Set the token seeder.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);
        _mint(to, nounId);
        // Automatically set new mints as wearing the fast food hat
        clothingState[nounId] = [0];
        emit NounCreated(nounId, seed);

        return nounId;
    }

    // Returns SVG string without the closing tag so we can insert more elements
    function removeLastSVGTag(bytes memory svgBytes) internal pure returns (string memory) {
        // This will be length of svgBytes minus length of svg closing tag `</svg>`
        bytes memory result = new bytes(svgBytes.length - 6);
        for(uint i = 0; i < result.length; i++) {
            result[i] = svgBytes[i];
        }
        return string(result);
    }

}