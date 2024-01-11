//**************************************************************
//           _______             _______  _______  _______
// |\     /|(  ___  )|\     /|  (  ___  )(  ____ )(  ____ \
// | )   ( || (   ) |( \   / )  | (   ) || (    )|| (    \/
// | (___) || (___) | \ (_) /   | (___) || (____)|| (__
// |  ___  ||  ___  |  \   /    |  ___  ||  _____)|  __)
// | (   ) || (   ) |   ) (     | (   ) || (      | (
// | )   ( || )   ( |   | |     | )   ( || )      | (____/\
// |/     \||/     \|   \_/     |/     \||/       (_______/
//**************************************************************

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

contract HayApe is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 9999;
    uint256 public constant TOKENS_PER_RANGE = 1000;

    uint256 public constant START_PRICE = 0.07 ether;
    uint256 public constant PRICE_INCREMENT_PER_RANGE = 0.005 ether;

    uint256 public constant MAX_MINT_PER_TX = 5;

    bool public publicMintingOpen = false;
    bool public whitelistMintintgOpen = false;

    Counters.Counter private currentTokenId;

    // Merkle tree root hash, used for whitelisting 
    bytes32 public merkleRoot =
        0x7f65c783ece3fea6555a5ff9a57c1d59b9cac547060a7eeac8bda34ac1f923ab;
    mapping(address => bool) public whitelistClaimed;

    // Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor() ERC721("HayApe NFT", "HAYAPE") {
        baseTokenURI = "";
    }

    // Get the current price range based on tokenId
    function _getRange(uint256 tokenId) private pure returns (uint256) {
        uint256 currRange = tokenId.div(TOKENS_PER_RANGE);
        return currRange;
    }

    // Get different stats and counts (used by a web dApp)
    function getStats()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        uint256 currentPrice = getPrice(1);
        uint256 currentRange = getCurrentRange();
        uint256 maxRanges = totalRanges();
        bool mintingAllowed = publicMintingOpen;

        return (
            TOTAL_SUPPLY,
            currentTokenId.current(),
            START_PRICE,
            currentPrice,
            PRICE_INCREMENT_PER_RANGE,
            currentRange,
            maxRanges,
            TOKENS_PER_RANGE,
            mintingAllowed
        );
    }

    // Returns total supply, max tokens that could be minted.
    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    // Return currently minted tokens available.
    function currentSupply() public view returns (uint256) {
        uint256 total = currentTokenId.current();
        return total;
    }

    // Max price ranges based on total supply and tokens per range.
    function totalRanges() public pure returns (uint256) {
        uint256 count = TOTAL_SUPPLY.div(TOKENS_PER_RANGE);
        return count;
    }

    // Get a price by a range number
    function getPriceByRange(uint256 range) public pure returns (uint256) {
        return START_PRICE.add(range.mul(PRICE_INCREMENT_PER_RANGE));
    }

    // Get current range, for the next token minted
    function getCurrentRange() public view returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        return _getRange(tokenId);
    }

    // Get price based on how many tokens to be minted.
    function getPrice(uint256 count) public view returns (uint256) {
        uint256 tokenId = currentTokenId.current();

        uint256 finalTokenId = tokenId.add(count);
        require(finalTokenId < TOTAL_SUPPLY, "Max supply reached");

        uint256 currRange = _getRange(tokenId);

        uint256 currRangeMax = TOKENS_PER_RANGE.add(
            currRange.mul(TOKENS_PER_RANGE)
        ) - 1;

        if (finalTokenId <= currRangeMax) {
            uint256 price = getPriceByRange(currRange);
            return price.mul(count);
        }

        uint256 nextRange = _getRange(finalTokenId);

        uint256 tokensInNextRange = finalTokenId.sub(currRangeMax);
        uint256 tokensInCurrRange = count.sub(tokensInNextRange);

        uint256 priceInCurrRange = getPriceByRange(currRange);
        uint256 priceInNextRange = getPriceByRange(nextRange);

        uint256 totalInCurrentRange = priceInCurrRange.mul(tokensInCurrRange);
        uint256 totalInNextRange = priceInNextRange.mul(tokensInNextRange);

        uint256 totalPrice = totalInCurrentRange.add(totalInNextRange);

        return totalPrice;
    }

    // List all tokens owned by the address.
    function getTokensByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory tokens = new uint256[](count);

        uint256 max = currentTokenId.current();
        uint256 _currIndex = 0;

        for (uint256 i = 1; i <= max; i++) {
            if (ownerOf(i) == owner) {
                tokens[_currIndex] = i;
                _currIndex = _currIndex.add(1);
            }
        }
        return tokens;
    }

    // Mint a token only when publicMintingOpen = true
    function mintTo(address recipient, uint256 count) public payable {
        require(
            publicMintingOpen == true && whitelistMintintgOpen == false,
            "Public minting is not open right now!"
        );
        require(count >= 1, "Must mint at least 1 token");
        require(
            count <= MAX_MINT_PER_TX,
            "Cannot mint more than max mint per transaction"
        );

        uint256 tokenId = currentTokenId.current();

        require(tokenId.add(count) < TOTAL_SUPPLY, "Max supply reached");

        uint256 price = getPrice(count);

        require(
            msg.value == price,
            "Transaction value did not equal to the total mint price"
        );

        for (uint8 i = 0; i < count; i++) {
            currentTokenId.increment();
            uint256 newItemId = currentTokenId.current();
            _safeMint(recipient, newItemId);
        }
    }

    // Mint token only when whitelistMintintgOpen = true
    function whitelistMintTo(
        address recipient,
        uint256 count,
        bytes32[] calldata proof
    ) public payable {
        require(
            publicMintingOpen == false && whitelistMintintgOpen == true,
            "whitelistMintintgOpen minting is not open right now!"
        );
        require(!whitelistClaimed[recipient], "Already minted");
        require(isWhitelisted(recipient, proof), "Not whitelisted");

        require(count >= 1, "Must mint at least 1 token");
        require(
            count <= MAX_MINT_PER_TX,
            "Cannot mint more than max mint per transaction"
        );

        uint256 tokenId = currentTokenId.current();

        require(tokenId.add(count) < TOTAL_SUPPLY, "Max supply reached");

        uint256 price = getPrice(count);

        require(
            msg.value == price,
            "Transaction value did not equal to the total mint price"
        );

        for (uint8 i = 0; i < count; i++) {
            currentTokenId.increment();
            uint256 newItemId = currentTokenId.current();
            _safeMint(recipient, newItemId);
        }

        whitelistClaimed[recipient] = true;
    }

    // Mint token used only by admins
    function adminMintTo(address recipient, uint256 count) public onlyOwner {
        uint256 tokenId = currentTokenId.current();
        require(tokenId.add(count) < TOTAL_SUPPLY, "Max supply reached");

        for (uint8 i = 0; i < count; i++) {
            currentTokenId.increment();
            uint256 newItemId = currentTokenId.current();
            _safeMint(recipient, newItemId);
        }
    }

    // Enables public minting and disables a whitelist minting
    function enablePublicMinting() public onlyOwner {
        publicMintingOpen = true;
        whitelistMintintgOpen = false;
    }

    // Enables whitelist minting and disables a public minting
    function enableWhitelistMinting() public onlyOwner {
        publicMintingOpen = false;
        whitelistMintintgOpen = true;
    }

    // Stops all minting
    function stopMinting() public onlyOwner {
        publicMintingOpen = false;
        whitelistMintintgOpen = false;
    }

    // Check if the address is included in whitelist, by merkle tree.
    function isWhitelisted(address recipient, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Update the markle root hash
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        require(_merkleRoot != merkleRoot, "Merkle root will be unchanged!");
        merkleRoot = _merkleRoot;
    }

    function withdraw(address payable payee, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance must be more than 0");
        require(amount > 0, "Amount must be more than 0");
        require(amount <= balance, "Amount is more than balance");
        payee.transfer(amount);
    }

    function withdrawAll(address payable payee) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance must be more than 0");
        payee.transfer(balance);
    }
}
