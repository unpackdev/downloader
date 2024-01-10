// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.2

/****************************************************************************
    Wiggles NFT Collection

      Genesis Phase - 555 Supply
      Total - 5555 Supply

    Welcome to Wiggle World

    Written by Oliver Straszynski
    https://github.com/broliver12/
****************************************************************************/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Wiggles is Ownable, ERC721A, ReentrancyGuard {
    // Control Params
    bool public isGenesis = true;
    bool private genesisRevealed;
    bool private revealed;
    string private baseURI;
    string private notRevealedURI;
    string private baseExtension = '.json';
    uint256 private numBackgrounds = 5;
    bool public freeWhitelistEnabled;
    bool public paidWhitelistEnabled;
    bool public publicMintEnabled;
    uint256 public immutable genesisDevCutoff;
    uint256 public immutable totalDevSupply;
    uint256 public immutable totalCollectionSize;
    uint256 public immutable genesisCollectionSize;

    // Mint Limits
    uint256 public maxMintsOg = 2;
    uint256 public ogWlMints = 1;
    uint256 public maxMintsWhitelist = 3;
    uint256 public maxMints = 20;

    // Price
    uint256 public unitPrice = 0.02 ether;

    // TOTAL supply for devs, marketing, friends, family
    uint256 private remainingDevSupply = 55;

    // Map of wallets => slot counts
    mapping(address => uint256) public genesisOg;
    mapping(address => uint256) public genesisWhitelist;
    mapping(address => uint256) public freeWhitelist;
    mapping(address => uint256) public paidWhitelist;

    // Constructor
    constructor() ERC721A('Wiggles', 'Wiggles') {
        // Set collection size
        genesisCollectionSize = 555;
        totalCollectionSize = 5555;
        // Set dev supply
        // 15 for Genesis Phase
        // 55 total
        genesisDevCutoff = 40;
        totalDevSupply = remainingDevSupply;
    }

    // Ensure caller is a wallet
    modifier isWallet() {
        require(tx.origin == msg.sender, 'Cant be a contract');
        _;
    }

    // Ensure there's enough supply to mint the quantity
    modifier enoughSupply(uint256 quantity) {
        if (isGenesis) {
            require(totalSupply() + quantity <= genesisCollectionSize, 'reached genesis supply');
        } else {
            require(totalSupply() + quantity <= totalCollectionSize, 'reached max supply');
        }
        _;
    }

    // Mint function for OG sale
    // Caller MUST be OG-Whitelisted to use this function!
    function freeWhitelistMint() external isWallet enoughSupply(maxMintsOg) {
        require(freeWhitelistEnabled, 'OG sale not enabled');
        if (isGenesis) {
            require(genesisOg[msg.sender] >= maxMintsOg, 'Not a wiggle world OG');
            genesisOg[msg.sender] = genesisOg[msg.sender] - maxMintsOg;
        } else {
            require(freeWhitelist[msg.sender] >= maxMintsOg, 'Not a wiggle world OG');
            freeWhitelist[msg.sender] = freeWhitelist[msg.sender] - maxMintsOg;
        }
        _safeMint(msg.sender, maxMintsOg);
    }

    // Mint function for whitelist sale
    // Requires minimum ETH value of unitPrice * quantity
    // Caller MUST be whitelisted to use this function!
    function paidWhitelistMint(uint256 quantity) external payable isWallet enoughSupply(quantity) {
        require(paidWhitelistEnabled, 'Whitelist sale not enabled');
        require(msg.value >= quantity * unitPrice, 'Not enough ETH');
        if (isGenesis) {
            require(genesisWhitelist[msg.sender] >= quantity, 'No whitelist mints left');
            genesisWhitelist[msg.sender] = genesisWhitelist[msg.sender] - quantity;
        } else {
            require(paidWhitelist[msg.sender] >= quantity, 'No whitelist mints left');
            paidWhitelist[msg.sender] = paidWhitelist[msg.sender] - quantity;
        }
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * unitPrice);
    }

    // Mint function for public sale
    // Requires minimum ETH value of unitPrice * quantity
    function publicMint(uint256 quantity) external payable isWallet enoughSupply(quantity) {
        require(publicMintEnabled, 'Minting not enabled');
        require(quantity <= maxMints, 'Illegal quantity');
        require(numberMinted(msg.sender) + quantity <= maxMints, 'Cant mint that many');
        require(msg.value >= quantity * unitPrice, 'Not enough ETH');
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * unitPrice);
    }

    // Mint function for developers (owner)
    // Mints a maximum of 20 NFTs to the recipient
    // Used for devs, marketing, friends, family
    // Capped at 55 mints total
    function devMint(uint256 quantity, address recipient)
        external
        onlyOwner
        enoughSupply(quantity)
    {
        if (isGenesis) {
            require(remainingDevSupply - quantity >= genesisDevCutoff, 'No dev supply (genesis)');
        } else {
            require(remainingDevSupply - quantity >= 0, 'Not enough dev supply');
        }
        require(quantity <= maxMints, 'Illegal quantity');
        require(numberMinted(recipient) + quantity <= maxMints, 'Cant mint that many (dev)');
        remainingDevSupply = remainingDevSupply - quantity;
        _safeMint(recipient, quantity);
    }

    // Returns the correct URI for the given tokenId based on contract state
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'Nonexistent token');
        if (
            (tokenId < genesisCollectionSize && genesisRevealed == false) ||
            (tokenId >= genesisCollectionSize && revealed == false)
        ) {
            return
                bytes(notRevealedURI).length > 0
                    ? string(
                        abi.encodePacked(
                            notRevealedURI,
                            Strings.toString(tokenId % numBackgrounds),
                            baseExtension
                        )
                    )
                    : '';
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension))
                : '';
    }

    // Set Price for Whitelist & Public Mint.
    // Should only be called once,
    // To change price between genesis and second mint.
    function setPrice(uint256 _price) external onlyOwner {
        unitPrice = _price;
    }

    // Update relevant mint format variables.
    // Should only be called once,
    // To change price between genesis and second mint.
    function updateMintFormat(
        uint256 _ogSlots,
        uint256 _ogWlSlots,
        uint256 _wlSlots,
        uint256 _maxMints,
        uint256 _numBackgrounds
    ) external onlyOwner {
        maxMintsOg = _ogSlots;
        ogWlMints = _ogWlSlots;
        maxMintsWhitelist = _wlSlots;
        maxMints = _maxMints;
        numBackgrounds = _numBackgrounds;
    }

    // Evolves the contract from Genesis phase
    function evolve() external onlyOwner {
        isGenesis = false;
    }

    // Change base metadata URI
    // Only will be called if something fatal happens to initial base URI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // Only will be called if something fatal happens to initial base URI
    function setBaseExtension(string calldata _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    // Sets URI for pre-reveal art metadata
    function setNotRevealedURI(string calldata _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    // Set the mint state
    function setMintState(uint256 _state) external onlyOwner {
        if (_state == 1) {
            freeWhitelistEnabled = true;
        } else if (_state == 2) {
            paidWhitelistEnabled = true;
        } else if (_state == 3) {
            publicMintEnabled = true;
        } else {
            freeWhitelistEnabled = false;
            paidWhitelistEnabled = false;
            publicMintEnabled = false;
        }
    }

    // Set revealed to true (displays baseURI instead of notRevealedURI on opensea)
    function reveal(bool _revealed) external onlyOwner {
        if (isGenesis) {
            genesisRevealed = _revealed;
        } else {
            genesisRevealed = _revealed;
            revealed = _revealed;
        }
    }

    // Seed the appropriate whitelist
    function setWhitelist(address[] calldata addrs, bool isOG) external onlyOwner {
        if (isOG) {
            for (uint256 i = 0; i < addrs.length; i++) {
                if (isGenesis) {
                    genesisOg[addrs[i]] = maxMintsOg;
                    genesisWhitelist[addrs[i]] = ogWlMints;
                } else {
                    freeWhitelist[addrs[i]] = maxMintsOg;
                    paidWhitelist[addrs[i]] = ogWlMints;
                }
            }
        } else {
            for (uint256 i = 0; i < addrs.length; i++) {
                if (isGenesis) {
                    genesisWhitelist[addrs[i]] = maxMintsWhitelist;
                } else {
                    paidWhitelist[addrs[i]] = maxMintsWhitelist;
                }
            }
        }
    }

    // Returns the amount the address has minted
    function numberMinted(address minterAddr) public view returns (uint256) {
        return _numberMinted(minterAddr);
    }

    // Returns the ownership data for the given tokenId
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    // Withdraw entire contract value to owners wallet
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }

    // Refunds extra ETH if minter sends too much
    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}
