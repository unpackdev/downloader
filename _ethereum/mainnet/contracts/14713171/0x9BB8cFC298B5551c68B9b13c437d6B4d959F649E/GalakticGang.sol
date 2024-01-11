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

import "./Counters.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract GalakticGang is ERC721Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using Counters for Counters.Counter;

    uint256 public whitelistStart; // white list start time
    uint256 public start; // Start time
    uint256 public constant MAX_SUPPLY = 5475; // Max public tokens
    uint256 public constant GIFT_SUPPLY = 80; // Gift supply
    uint256 public price; // Price of each tokens
    string public baseTokenURI; // Placeholder during mint
    string public revealedTokenURI; // Revealed URI

    uint256 limitPerMint; // # of tokens a user can buy in a single tx
    uint256 limitPerAddress; // # of tokens a user can buy per address
    mapping(address => uint256) public purchased; // # of bought per address
    Counters.Counter private counter;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /** @notice whitelist mint day before public */
    function whitelistMint(
        bytes memory signature,
        uint256 amount,
        uint256 wlA
    ) external payable notContract {
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
                counter.increment();
                _mint(msg.sender, totalSupply());
            }
        }
    }

    /** @notice Public mint day after whitelist */
    function publicMint(uint256 amount) external payable notContract {
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
                counter.increment();
                _mint(msg.sender, totalSupply());
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
                counter.increment();
                _mint(to, totalSupply());
            }
        }
    }

    /** @notice Mint first item for OS collection */
    function mintFirst() external onlyOwner {
        require(totalSupply() == 0, 'Mint: First already minted');

        counter.increment();
        _mint(owner(), totalSupply());
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

    /** @notice Set blacklisted address */
    function setBlacklist(address forWho, bool bl) external onlyOwner {
        blacklist[forWho] = bl;
    }

    /** @notice Set whitelisted address to buy from blacklisted addresses */
    function setWhitelist(address forWho, bool wl) external onlyOwner {
        whitelist[forWho] = wl;
    }

    /** @notice this should suffice for Enumerable with only 5555 tokens */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);

        uint256[] memory ids = new uint256[](balance);
        uint256 length = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                ids[length] = i;
                length++;
            }
        }

        return ids;
    }

    /** @notice Withdraw Ethereum */
    function withdraw(address to) external {
        require(
            msg.sender == 0xCe2A22B4b52Fc18e4343cc075e9FD8E6C438286f,
            'Not deployer'
        );
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

    function totalSupply() public view returns (uint256) {
        return counter.current();
    }

    /** Transfer overrides for Blacklisting bot buyers an sellers. */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            (!blacklist[from] && !blacklist[to]) || whitelist[to],
            'Either the to or from is blacklisted from trading Galaktic Gangs'
        );

        super.transferFrom(from, to, tokenId);
    }

    /** Transfer overrides for Blacklisting bot buyers an sellers. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            (!blacklist[from] && !blacklist[to]) || whitelist[to],
            'Either the to or from is blacklisted from trading Galaktic Gangs'
        );

        super.safeTransferFrom(from, to, tokenId);
    }

    /** Transfer overrides for Blacklisting bot buyers an sellers. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            (!blacklist[from] && !blacklist[to]) || whitelist[to],
            'Either the to or from is blacklisted from trading Galaktic Gangs'
        );

        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /** @notice initialize contract */
    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        limitPerMint = 5;
        limitPerAddress = 10;
        baseTokenURI = 'ipfs://QmXggWNhqTCbnccA4tAh5rowWchxd7u5qBae2ezsCBXeZi/placeholder.gif';

        whitelistStart = 1639540800; // Dec 14th 9pm UTC
        start = 1639713600; // Dec 16th 9PM UTC
        price = 0.0777 ether;
    }
}
