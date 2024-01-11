// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract PartnerNFT is
    ERC721PresetMinterPauserAutoIdUpgradeable,
    ReentrancyGuardUpgradeable
{
    enum Kind {
        Partner,
        Sponsor
    }

    enum Generation {
        ZERO,
        ONE,
        TWO,
        THREE
    }

    enum Status {
        INACTIVE,
        WHITELIST,
        PUBLIC,
        ENDED
    }

    string public baseTokenURI; // base uri of the metadata url
    uint256 public generation; // The generation of the nft
    uint256 public kind; // The kind of nft - partner or sponsor
    uint256 public maxSupply; // total tokens allowed on the contract
    uint256 public maxMintQuantity; // Max mint amount per tx
    uint256 public price; // price per nft
    Status public status; // minting status of contract
    bytes32 public merkleRoot; // merkle root for whitelist proof

    // whitelist related
    uint256 public wlPrice; // whitelist price per nft
    mapping(address => uint256) private _whitelist;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _generation,
        uint256 _kind
    ) public initializer {
        super.initialize(_name, _symbol, _baseTokenURI);
        __ReentrancyGuard_init_unchained();
        baseTokenURI = _baseTokenURI;
        generation = _generation;
        kind = _kind;
        maxMintQuantity = 20;
        maxSupply = 5075;
        status = Status.INACTIVE;
        merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;

        price = (1 ether * 2) / 10; // .2 eth for MAINNET
        wlPrice = (1 ether * 15) / 100; // .15 eth for MAINNET
    }

    /**
     * @dev Set status of contract for minting
     */
    function setStatus(Status _status) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender must have admin role to change status"
        );
        status = _status;
    }

    /**
     * @dev Set merkleRoot generated for whitelist addresses
     */
    function setMerkleRoot(bytes32 _merkleRoot) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender must have admin role to change merkleRoot"
        );
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Internal helper method
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Changes the baseUri of the tokens
     *
     * - overridable
     */
    function setBaseUri(string memory _baseUri) public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender must have admin role to change base uri"
        );
        baseTokenURI = _baseUri;
    }

    /**
     * @dev We take the baseURI and concat the tokenID - this is the method that opensea and such will use to grab the metadata url from
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory base = _baseURI();

        return string(abi.encodePacked(base, Strings.toString(_tokenId)));
    }

    /**
     * OVERRIDE to keep people from using
     */
    function mint(address to) public virtual override {
        revert("Unsupported method");
    }

    /**
     * @dev - public method to mint token(s)
     */
    function mintNFT(uint256 _quantity) public payable virtual nonReentrant {
        require(status == Status.PUBLIC, "Public minting period is not active");

        uint256 amount = price * _quantity;
        require(msg.value == amount, "Incorrect amount of eth sent");

        require(_quantity > 0, "Quantity must be a positive non-zero number");

        require(
            _quantity <= maxMintQuantity,
            "Mint quantity greater than allowed batch limit"
        );

        uint256 supply = totalSupply();
        require(!paused(), "Cannot mint on a paused contract");
        require(
            supply + _quantity <= maxSupply,
            "Minting would exceed max supply"
        );

        for (uint256 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * @dev - whitelisted method to mint token(s)
     */
    function wlMintNFT(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
        payable
        virtual
        nonReentrant
    {
        require(
            status == Status.WHITELIST,
            "Whitelist minting period is not active"
        );

        require(_quantity > 0, "Quantity must be a positive non-zero number");

        require(
            _quantity <= maxMintQuantity,
            "Mint quantity greater than allowed batch limit"
        );

        require(
            merkleRoot !=
                0x0000000000000000000000000000000000000000000000000000000000000000,
            "merkleRoot not set - unable to verify whitelisted participants"
        );

        // Verify merkle tree using provided parameters
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Address is not whitelisted"
        );

        uint256 prev = _whitelist[msg.sender];
        require(
            prev + _quantity <= maxMintQuantity,
            "Exceeded allowed aggregate total for whitelist of 20"
        );

        uint256 amount = wlPrice * _quantity;
        require(msg.value == amount, "Incorrect amount of eth sent");

        uint256 supply = totalSupply();
        require(!paused(), "Cannot mint on a paused contract");
        require(
            supply + _quantity <= maxSupply,
            "Minting would exceed max supply"
        );

        for (uint256 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, supply + i);
        }

        _whitelist[msg.sender] = prev + _quantity;
    }

    /**
     * @dev Withdraw eth from the contract
     * - Withdraw eth from the contract
     * - Transfer eth to the sender
     */
    function withdraw() public payable nonReentrant {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Sender must have admin role to withdraw"
        );

        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        address payable to = payable(msg.sender);
        to.transfer(balance);
    }
}
