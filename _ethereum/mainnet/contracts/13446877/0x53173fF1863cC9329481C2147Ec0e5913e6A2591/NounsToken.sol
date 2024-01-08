// SPDX-License-Identifier: GPL-3.0

/// @title The Cool DAO ERC-721 token

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
pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


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

contract CoolNouns is INounsToken, Ownable, ERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    uint256 public price = 25000000000000000; // .02 eth
    uint256 public max_tokens = 2222;
    uint256 public mint_limit= 20;

    string public tokenDescription = 'Nouns are pretty boring, so we made them pretty cool. 8).';

    string public hatSVG = '<rect width="120" height="10" x="50" y="120" fill="#000000"/><rect width="110" height="10" x="170" y="120" fill="#000000"/><rect width="20" height="10" x="50" y="130" fill="#000000"/><rect width="10" height="10" x="70" y="130" fill="#CACACA"/><rect width="10" height="10" x="80" y="130" fill="#000000"/><rect width="10" height="10" x="90" y="130" fill="#CACACA"/><rect width="60" height="10" x="100" y="130" fill="#000000"/><rect width="20" height="10" x="60" y="140" fill="#000000"/><rect width="10" height="10" x="80" y="140" fill="#CACACA"/><rect width="10" height="10" x="90" y="140" fill="#000000"/><rect width="10" height="10" x="100" y="140" fill="#CACACA"/><rect width="50" height="10" x="110" y="140" fill="#000000"/><rect width="20" height="10" x="70" y="150" fill="#000000"/><rect width="10" height="10" x="90" y="150" fill="#CACACA"/><rect width="10" height="10" x="100" y="150" fill="#000000"/><rect width="10" height="10" x="110" y="150" fill="#CACACA"/><rect width="30" height="10" x="120" y="150" fill="#000000"/><rect width="60" height="10" x="80" y="160" fill="#000000"/><rect width="10" height="20" x="170" y="130" fill="#000000"/><rect width="10" height="20" x="180" y="140" fill="#000000"/><rect width="10" height="20" x="190" y="150" fill="#000000"/><rect width="60" height="10" x="190" y="160" fill="#000000"/><rect width="10" height="10" x="180" y="130" fill="#CACACA"/><rect width="10" height="10" x="190" y="130" fill="#000000"/><rect width="10" height="10" x="200" y="130" fill="#CACACA"/><rect width="70" height="10" x="210" y="130" fill="#000000"/><rect width="10" height="10" x="190" y="140" fill="#CACACA"/><rect width="10" height="10" x="200" y="140" fill="#000000"/><rect width="10" height="10" x="210" y="140" fill="#CACACA"/><rect width="50" height="10" x="220" y="140" fill="#000000"/><rect width="10" height="10" x="200" y="150" fill="#CACACA"/><rect width="10" height="10" x="210" y="150" fill="#000000"/><rect width="10" height="10" x="220" y="150" fill="#CACACA"/><rect width="30" height="10" x="230" y="150" fill="#000000"/>';

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

    constructor() ERC721('CoolNouns', 'COOL') {
        // Populate `clothingList`
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

        require (num_tokens<=mint_limit,"minted too many");

        require(num_tokens+totalSupply()<=max_tokens,"exceeds maximum tokens");

        require(msg.value>=num_tokens*price,"not enough ethers sent");

        for (uint256 x=0;x<num_tokens;x++) {
            _mintTo(msg.sender, _currentNounId++);
            _tokenIdTracker.increment();
        }
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
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
        string memory name = string(abi.encodePacked('CoolNounsDAO ', NounID));
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
