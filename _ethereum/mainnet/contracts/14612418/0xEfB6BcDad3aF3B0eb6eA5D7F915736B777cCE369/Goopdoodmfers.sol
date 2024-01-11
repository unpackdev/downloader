// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1
// Chiru Labs ERC721 v3.2.0

/****************************************************************************
    goopdoodmfers

    8008 Supply

    Written by Oliver Straszynski
    https://github.com/broliver12/
****************************************************************************/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

error OwnerIndexOutOfBounds();

contract Goopdoodmfers is ERC721A, Ownable, ReentrancyGuard {
    // Metadata Control
    bool private revealed;
    string private baseURI;
    string private notRevealedURI;
    string private ext = ".json";
    // Mint Control
    bool public whitelistEnabled;
    bool public mintEnabled;
    uint256 public maxMintsWhitelist = 2;
    uint256 public maxMints = 20;
    // Price
    uint256 public price = 0.018 ether;
    // Collection Size
    // Set to 8008 on ln. 58
    uint256 public immutable collectionSize;
    // Supply for devs
    uint256 private remainingDevSupply = 14;
    uint256 public immutable devSupply;
    // Map of wallets => slot counts
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public freeMintsUsed;

    // Goopdoods contract
    address private allowedAddress = 0x2dfF22dcb59D6729Ed543188033CE102f14eF0d1;
    IERC721 goopdoods = IERC721(allowedAddress);
    // Ability to change address
    function setAllowedAddress(address _addr) external onlyOwner {
        allowedAddress = _addr;
        goopdoods = IERC721(_addr);
    }

    // Constructor
    constructor() ERC721A("goopdoodmfers", "goopdoodmfers") {
        // Set collection size
        collectionSize = 8008;
        // Make dev supply public & immutable
        devSupply = remainingDevSupply;
    }

    // Ensure caller is a wallet
    modifier isWallet() {
        require(tx.origin == msg.sender, "Cant be a contract");
        _;
    }

    // Ensure there's enough supply to mint the quantity
    modifier enoughSupply(uint256 quantity) {
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        _;
    }

    // Mint function for whitelist sale
    function whitelistMint(uint256 quantity)
        external
        payable
        isWallet
        enoughSupply(quantity)
    {
        require(whitelistEnabled, "Whitelist sale not enabled");
        require(whitelist[msg.sender] >= quantity, "No whitelist mints left");
        discount(quantity);
        whitelist[msg.sender] = whitelist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
    }

    // Mint function for public sale
    function publicMint(uint256 quantity)
        external
        payable
        isWallet
        enoughSupply(quantity)
    {
        require(mintEnabled, "Minting not enabled");
        require(
            numberMinted(msg.sender) + quantity <= maxMints,
            "Cant mint that many"
        );
        discount(quantity);
        _safeMint(msg.sender, quantity);
    }

    // 1 goop == 1 gdmfer
    function discount(uint256 quantity) private {
        uint256 balance = goopdoods.balanceOf(msg.sender);
        if(balance > 0){
           uint256 freeMintsAvailable = balance - freeMintsUsed[msg.sender];
           if(quantity >= freeMintsAvailable){
             freeMintsUsed[msg.sender] += freeMintsAvailable;
             // If you've got some free mints, you'll pay partial price
             require(msg.value >= (quantity - freeMintsAvailable) * price, "Not enough ETH");
             refundIfOver((quantity - freeMintsAvailable) * price);
           } else {
             freeMintsUsed[msg.sender] += quantity;
             // If you've got enough free mints, all eth paid is refunded.
             refundIfOver(0);
           }
        } else {
          // If you're not a goop owner, you pay full price
          require(msg.value >= quantity * price, "Not enough ETH");
          refundIfOver(quantity * price);
        }
    }

    // Mint function for developers (owner)
    function devMint(address recipient, uint256 quantity)
        external
        onlyOwner
        enoughSupply(quantity)
    {
        require(quantity <= remainingDevSupply, "Not enough dev supply");
        require(quantity <= maxMints, "Illegal quantity");
        remainingDevSupply = remainingDevSupply - quantity;
        _safeMint(recipient, quantity);
    }

    // Returns the correct URI for the given tokenId based on contract state
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        if (!revealed) {
            return notRevealedURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ext
                    )
                )
                : "";
    }

    // Set price for whitelist & public mint
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // Change base metadata URI
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    // Change pre-reveal metadata URI
    function setNotRevealedURI(string calldata _uri)
        external
        onlyOwner
    {
        notRevealedURI = _uri;
    }

    // Change baseURI extension
    function setExt(string calldata _ext)
        external
        onlyOwner
    {
        ext = _ext;
    }

    // Set the mint state
    // 1 - Enable whitelist
    // 2 - Enable public mint
    // 0 - Disable whitelist & public mint
    function setMintState(uint256 _state) external onlyOwner {
        if (_state == 1) {
            whitelistEnabled = true;
        } else if (_state == 2) {
            mintEnabled = true;
        } else {
            whitelistEnabled = false;
            mintEnabled = false;
        }
    }

    // Reveal art
    function reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // Seed whitelist
    function setWhitelist(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = maxMintsWhitelist;
        }
    }

    // Returns the amount the address has minted
    function numberMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }

    // Returns the ownership data for the given tokenId
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    // Withdraw entire contract value to owners wallet
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // Refunds extra ETH if minter sends too much
    function refundIfOver(uint256 _price) private {
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    // While invaluable when called from a read-only context, this function's
    // implementation is by nature NOT gas efficient [O(totalSupply)],
    // and degrades with collection size.
    //
    // Therefore, you typically shouldn't call tokenOfOwnerByIndex() from
    // another contract. Test for your use case.
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256)
    {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Cant get to this line, because maths
        revert();
    }
}
