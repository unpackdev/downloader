// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721.sol";

contract HappyBunnies is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

    modifier mintingStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "You are too early"
        );
        _;
    }

    modifier callerNotAContract() {
        require(
            tx.origin == msg.sender,
            "The caller can only be a user and not a contract"
        );
        _;
    }

    // 7777 total NFTs
    uint256 public totalBunnies = 7777;

    // Each transaction allows the user to mint only 27 NFTs. One user can't mint more than 177 NFTs.
    uint256 private maxBunniesPerWallet = 177;
    uint256 private maxBunniesPerTransaction = 27;

    // Setting Mint date to 3pm UTC, 03/09/2021
    uint256 private startMintDate = 1630681200;

    // Price per NFT: 0.07 ETH
    uint256 private bunnyPrice = 70000000000000000;

    uint256 private totalMintedBunnies = 0;

    uint256 public premintCount = 277;

    bool public premintingComplete = false;

    // IPFS base URI for NFT metadata for OpenSea
    string private baseURI = "https://ipfs.io/ipfs/QmSRkmEDKWUeHi5FiNpQUBAcCq7rKinhf5Pbu8ZPZNkP8r/";

    // Ledger of NFTs minted and owned by each unique wallet address.
    mapping(address => uint256) private claimedBunniesPerWallet;

    uint16[] availableBunnies;

    constructor() ERC721("Happy Bunnies", "BUNNY") {
        addAvailableBunnies();
    }

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract to the address of the owner.
     */
    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Sets the mint price for each bunny
     */
    function setBunnyPrice(uint256 _bunnyPrice) external onlyOwner {
        bunnyPrice = _bunnyPrice;
    }

    /**
     * @dev Adds all bunnies to the available list.
     */
    function addAvailableBunnies() internal onlyOwner {
        for (uint16 i = 0; i <= 7776; i++) {
            availableBunnies.push(i);
        }
    }

    /**
     * @dev Prem
     */
    function premintBunnies() external onlyOwner {
        require(!premintingComplete, "You can only premint the bunnies once");
        require(
            availableBunnies.length >= premintCount,
            "No bunnies left to be claimed"
        );
        totalMintedBunnies += premintCount;

        for (uint256 i; i < premintCount; i++) {
            _mint(msg.sender, getBunnyToBeClaimed());
        }
        premintingComplete = true;
    }

    // END ONLY OWNER FUNCTIONS

    /**
     * @dev Claim up to 27 bunnies at once
     */
    function mintBunnies(uint256 amount)
        external
        payable
        callerNotAContract
        mintingStarted
    {
        require(
            msg.value >= bunnyPrice * amount,
            "Not enough Ether to claim the bunnies"
        );

        require(
            claimedBunniesPerWallet[msg.sender] + amount <= maxBunniesPerWallet,
            "You cannot claim more bunnies"
        );

        require(
            availableBunnies.length >= amount,
            "No bunnies left to be claimed"
        );

        require(
            amount <= maxBunniesPerTransaction,
            "Max 27 per tx"
        );

        uint256[] memory tokenIds = new uint256[](amount);

        claimedBunniesPerWallet[msg.sender] += amount;
        totalMintedBunnies += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getBunnyToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns how many bunnies are still available to be claimed
     */
    function getAvailableBunnies() external view returns (uint256) {
        return availableBunnies.length;
    }

    /**
     * @dev Returns the claim price
     */
    function getBunnyPrice() external view returns (uint256) {
        return bunnyPrice;
    }

    /**
     * @dev Returns the minting start date
     */
    function getMintingStartDate() external view returns (uint256) {
        return startMintDate;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedBunnies;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available bunny to be claimed
     */
    function getBunnyToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableBunnies.length);
        uint256 tokenId = uint256(availableBunnies[random]);

        availableBunnies[random] = availableBunnies[
            availableBunnies.length - 1
        ];
        availableBunnies.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableBunnies.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
