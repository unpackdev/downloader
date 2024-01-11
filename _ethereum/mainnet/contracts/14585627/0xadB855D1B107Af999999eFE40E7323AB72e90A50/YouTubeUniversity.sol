// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./SignedMinting.sol";

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./Strings.sol";

// fancyrats.eth
contract YouTubeUniversity is ERC721A, Ownable, PaymentSplitter, SignedMinting {
    using Address for address;
    using Strings for string;

    // Sale Info
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant TEAM_RESERVED = 200;

    uint256 public salePrice = 0.1 ether; //
    uint256 public presalePrice = 0.1 ether; //
    uint256 public txLimit = 5; //

    // Metadata
    string public baseURI;
    string public provenanceHash;
    bool public metadataFrozen;

    // State
    address public developer;
    address public premintAddress;
    bool public preminted;
    enum SaleState {
        CLOSED,
        PRESALE,
        PUBLIC
    }
    SaleState public saleState;
    bool public signatureRequired;

    constructor(
        address owner_,
        address premintAddress_,
        address signer_,
        string memory tokenName_,
        string memory tokenSymbol_,
        address[] memory payees_,
        uint256[] memory shares_
    )
        ERC721A(tokenName_, tokenSymbol_)
        PaymentSplitter(payees_, shares_)
        SignedMinting(signer_)
        Ownable()
    {
        require(owner_ != address(0));
        require(premintAddress_ != address(0));
        require(signer_ != address(0));

        developer = _msgSender();
        _transferOwnership(owner_);

        premintAddress = premintAddress_;
    }

    function mint(
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) public payable {
        require(saleState != SaleState.CLOSED);
        require(!signatureRequired || validateSignature(_signature, _to));
        uint256 price = saleState == SaleState.PUBLIC
            ? salePrice
            : presalePrice;
        require(msg.value == price * _amount, "Invalid Payment");
        require(_amount <= txLimit, "Tx Limit");
        _mint(_to, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function freezeMetadata() public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        metadataFrozen = true;
    }

    function setProvenanceHash(string calldata _hash) public onlyAuthorized {
        require(!metadataFrozen, "Metadata is frozen");
        require(bytes(provenanceHash).length == 0, "Hash already set");
        provenanceHash = _hash;
    }

    function setBaseURI(string calldata __baseURI) public onlyAuthorized {
        require(!metadataFrozen, "Metadata Frozen");
        baseURI = __baseURI;
    }

    function premint() public onlyAuthorized {
        require(!preminted);
        _mint(premintAddress, TEAM_RESERVED);
        preminted = true;
    }

    function setSignatureRequired(bool _signatureRequired)
        public
        onlyAuthorized
    {
        signatureRequired = _signatureRequired;
    }

    function adminMint(address _to, uint256 _amount) public onlyAuthorized {
        _mint(_to, _amount);
    }

    function setMintSigner(address _signer) public onlyAuthorized {
        _setMintingSigner(_signer);
    }

    function setSaleState(SaleState _saleState) public onlyAuthorized {
        require(preminted);
        saleState = _saleState;
    }

    function setSalePrice(uint256 _salePrice) public onlyAuthorized {
        salePrice = _salePrice;
    }

    function setPresalePrice(uint256 _presalePrice) public onlyAuthorized {
        presalePrice = _presalePrice;
    }

    function setTxLimit(uint256 _TxLimit) public onlyAuthorized {
        txLimit = _TxLimit;
    }

    function setPremintAddress(address _premintAddress) public onlyAuthorized {
        require(!preminted);
        premintAddress = _premintAddress;
    }

    // Private/Internal
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _mint(address _to, uint256 amount) private {
        require(_to != address(0), "Cannot mint to 0x0");
        require(amount > 0, "Amount cannot be 0");
        require(amount + totalSupply() <= MAX_SUPPLY, "Sold out");
        _safeMint(_to, amount);
    }

    // Modifiers
    modifier onlyAuthorized() {
        checkAuthorized();
        _;
    }

    function checkAuthorized() private view {
        require(
            _msgSender() == owner() || _msgSender() == developer,
            "Unauthorized"
        );
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "Contracts cannot mint");
        _;
    }
}
