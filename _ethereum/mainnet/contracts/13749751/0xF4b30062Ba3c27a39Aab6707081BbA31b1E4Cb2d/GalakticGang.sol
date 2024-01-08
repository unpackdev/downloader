/**
  ________       .__          __      __  .__           ________                       
 /  _____/_____  |  | _____  |  | ___/  |_|__| ____    /  _____/_____    ____    ____  
/   \  ___\__  \ |  | \__  \ |  |/ /\   __\  |/ ___\  /   \  ___\__  \  /    \  / ___\ 
\    \_\  \/ __ \|  |__/ __ \|    <  |  | |  \  \___  \    \_\  \/ __ \|   |  \/ /_/  >
 \______  (____  /____(____  /__|_ \ |__| |__|\___  >  \______  (____  /___|  /\___  / 
        \/     \/          \/     \/              \/          \/     \/     \//_____/  

Art By: Chris Dyer
Contract By: Travis Delly
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract GalakticGang is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public whitelistStart; // white list start time
    uint256 public start; // Start time
    uint256 constant MAX_SUPPLY = 5475; // Max public tokens
    uint256 constant GIFT_SUPPLY = 80; // Gift supply
    uint256 public price; // Price of each tokens
    string public baseTokenURI; // Placeholder during mint
    string public revealedTokenURI; // Revealed URI

    uint256 limitPerMint; // # of tokens a user can buy in a single tx
    uint256 limitPerAddress; // # of tokens a user can buy per address
    mapping(address => uint256) public purchased; // # of bought per address

    /** @notice whitelist mint day before public */
    function whitelistMint(
        bytes memory signature,
        uint256 amount,
        uint256 wlA
    ) external payable {
        // Wait until whitelist start
        require(
            whitelistStart <= block.timestamp,
            'Mint: Whitelist sale not yet started'
        );

        // Total supply must be less then max supply
        require(totalSupply() < MAX_SUPPLY, 'Mint: All tokens minted');

        // Check ethereum paid
        require(
            price * amount <= msg.value,
            "Mint: ETH amount is insufficient, don't cheap out on us!"
        );

        // Ensure whitelist
        bytes32 messageHash = sha256(abi.encode(msg.sender, wlA));
        require(
            ECDSAUpgradeable.recover(messageHash, signature) == owner(),
            'Mint: Invalid Signature, are you whitelisted bud?'
        );

        // Stop greedy people
        purchased[msg.sender] += amount;
        require(
            purchased[msg.sender] <= wlA,
            "Mint: Don't be greedy share the love!"
        );

        // Mint time!
        for (uint256 i = 0; i < amount; i++) {
            // The last user can send an amount of whatever they like, but will only get as many until all minted.
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, totalSupply());
            }
        }
    }

    /** @notice Public mint day after whitelist */
    function publicMint(uint256 amount) external payable {
        // Wait until public start
        require(start <= block.timestamp, 'Mint: Public sale not yet started');

        // Ensure amount is greater then 0 and less then limitPerMint
        require(
            amount > 0 && amount <= limitPerMint,
            'Mint: Can only mint so many at a time fren'
        );

        // Total supply must be less then max supply
        require(totalSupply() < MAX_SUPPLY, 'Mint: All tokens minted');

        // Check ethereum paid
        require(
            price * amount <= msg.value,
            "Mint: ETH amount is insufficient, don't cheap out on us!"
        );

        // Stop greedy people
        purchased[msg.sender] += amount;
        require(
            purchased[msg.sender] <= limitPerAddress,
            "Mint: Don't be greedy share the love!"
        );

        // Mint time!
        for (uint256 i = 0; i < amount; i++) {
            // The last user can send an amount of whatever they like, but will only get as many until all minted.
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, totalSupply());
            }
        }
    }

    /** @notice Gift mints after all minted */
    function mintGift(address to, uint256 amount) external onlyOwner {
        require(totalSupply() >= MAX_SUPPLY, 'Mint: No gifts until all minted');

        uint256 maxPlusGift = MAX_SUPPLY + GIFT_SUPPLY;
        require(totalSupply() < maxPlusGift, 'Mint: All minted');

        for (uint256 i = 0; i < amount; i++) {
            // The last user can send an amount of whatever they like, but will only get as many until all minted.
            if (totalSupply() < maxPlusGift) {
                _safeMint(to, totalSupply());
            }
        }
    }

    /** @notice Mint first item for OS collection */
    function mintFirst() external onlyOwner {
        require(totalSupply() == 0, 'Mint: First already minted');
        _safeMint(owner(), totalSupply());
    }

    /** @notice Set Base URI */
    function setWhitelistStart(uint256 time) external onlyOwner {
        whitelistStart = time;
    }

    /** @notice Set Base URI */
    function setStart(uint256 time) external onlyOwner {
        start = time;
    }

    /** @notice Set Base URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setRevealedTokenUri(string memory uri) external onlyOwner {
        revealedTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setLimitPerMint(uint256 limit) external onlyOwner {
        limitPerMint = limit;
    }

    /** @notice Set Reveal URI */
    function setLimitPerAddress(uint256 limit) external onlyOwner {
        limitPerAddress = limit;
    }

    /** @notice Set Reveal URI */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /** @notice Make it easier to get token id of user */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 idx = 0; idx < tokenCount; idx++) {
            result[idx] = tokenOfOwnerByIndex(owner, idx);
        }
        return result;
    }

    /** @notice Withdraw Ethereum */
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;

        safeTransferETH(to, balance);
    }

    /** Utility Function */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** @notice Image URI */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), 'Token does not exist');

        // @dev Convert string to bytes so we can check if it's empty or not.
        return
            bytes(revealedTokenURI).length > 0
                ? string(abi.encodePacked(revealedTokenURI, tokenId.toString()))
                : baseTokenURI;
    }

    /** @notice initialize contract */
    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __ERC721Enumerable_init();

        limitPerMint = 5;
        limitPerAddress = 10;
        baseTokenURI = 'https://gateway.pinata.cloud/ipfs/QmV2y7JXDSiNttvanG51nXir8LqGGCw9cAkJ5ujkRJwbBm/GG-written-red.png';

        whitelistStart = 1639440000; // Dec 14th 5PM UTC
        start = 1639699200; // Dec 15th 7PM UTC
        price = 0.0777 ether;
    }
}
