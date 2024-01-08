// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Strings.sol";

contract WilyWolves is
    ERC721Enumerable,
    VRFConsumerBase,
    PaymentSplitter,
    Pausable,
    Ownable
{
    using Address for address;
    using Strings for uint256;

    uint256 public constant NUM_RESERVED = 100; // For team, giveaways, and promos
    uint256 public constant MAX_SUPPLY = 10000;

    address public teamAddress;
    string public provenanceHash;
    string public baseURI_;
    bool public revealed;
    bool public preminted;
    uint256 public mintPrice = 0.04 ether;
    uint256 public maxMintPerTx = 10;

    uint256 internal _tokenOffset;
    uint256 internal _linkFee;
    bytes32 internal _linkKeyHash;

    constructor(
        string memory unrevealedURI,
        address vrfCoordinator,
        address linkToken,
        bytes32 linkKeyHash,
        uint256 linkFee,
        address[] memory payees,
        uint256[] memory shares_,
        address teamAddress_
    )
        ERC721("WilyWolves", "WW")
        VRFConsumerBase(vrfCoordinator, linkToken)
        PaymentSplitter(payees, shares_)
        Ownable()
        Pausable()
    {
        baseURI_ = unrevealedURI;

        _linkKeyHash = linkKeyHash;
        _linkFee = linkFee;

        teamAddress = teamAddress_;

        _pause();
    }

    function publicMint(uint256 amount)
        public
        payable
        whenNotPaused
        isValidPayment(amount)
        validPublicTxLimit(amount)
    {
        _mintAmount(amount, msg.sender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Query for nonexistent token");
        if (!revealed) {
            return _baseURI();
        }
        uint256 offsetTokenId = ((tokenId + _tokenOffset) % MAX_SUPPLY);
        return string(abi.encodePacked(_baseURI(), offsetTokenId.toString()));
    }

    function ownerMint(uint256 amount) public onlyOwner whenNotRevealed {
        _mintAmount(amount, msg.sender);
    }

    function ownerStartSale() public onlyOwner {
        require(
            bytes(provenanceHash).length > 0,
            "Provenance needed before sale"
        );
        _unpause();
    }

    function ownerPauseSale() public onlyOwner {
        _pause();
    }

    function ownerSetMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function ownerSetMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    // @notice Revealed baseURI must end in /
    function ownerSetBaseURI(string memory _newBaseURI)
        public
        onlyOwner
        whenNotRevealed
    {
        baseURI_ = _newBaseURI;
    }

    function ownerSetProvenanceHash(string memory _provenanceHash)
        public
        onlyOwner
        whenPaused
    {
        require(
            bytes(provenanceHash).length == 0,
            "Provenance hash already set"
        );
        provenanceHash = _provenanceHash;
    }

    function ownerReveal() public onlyOwner whenNotRevealed {
        require(
            LINK.balanceOf(address(this)) >= _linkFee,
            "Insufficient $LINK balance"
        );
        require(
            bytes(provenanceHash).length > 0,
            "Provenance hash must be set"
        );
        requestRandomness(_linkKeyHash, _linkFee);
    }

    function ownerPremint() public onlyOwner {
        require(!preminted, "Can only premint once");
        _mintAmount(NUM_RESERVED, teamAddress);
        preminted = true;
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
        whenNotRevealed
    {
        _tokenOffset = randomNumber;
        revealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function _mintAmount(uint256 amount, address to)
        internal
        whenTokensAvailable(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply());
        }
    }

    modifier isValidPayment(uint256 amount) {
        require(msg.value == (mintPrice * amount), "Invalid Ether amount sent");
        _;
    }

    modifier whenTokensAvailable(uint256 amount) {
        require(
            (totalSupply() + amount) <= MAX_SUPPLY,
            "Exceeds maximum number of tokens"
        );
        _;
    }

    modifier validPublicTxLimit(uint256 amount) {
        require(amount > 0, "Must specify amount");
        require(amount <= maxMintPerTx, "Exceeds the maximum amount");
        _;
    }

    modifier whenNotRevealed() {
        require(!revealed, "Must not be revealed");
        _;
    }
}
