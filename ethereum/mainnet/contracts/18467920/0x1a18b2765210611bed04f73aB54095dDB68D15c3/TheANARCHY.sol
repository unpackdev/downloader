// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract TheANARCHY is ERC721A, AccessControl, Ownable, ERC2981 {
    uint256 public constant MAX_SUPPLY = 1550;
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 public constant MAX_MINT_PER_TX = 5;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    address public constant OWNER = 0x8d31AbE350A5eA254da35A257e2079bD9B44a4E4;

    string public baseURI;
    string public notRevealedURI;
    string public extension = ".json";
    bool public isRevealed = false;

    enum Phase {
        Paused,
        ALSale,
        PublicSale
    }
    Phase public phase = Phase.Paused;

    mapping(address => uint256) public allowList;
    mapping(address => uint256) public presaleMinted;
    uint256 public allowListSum = 0;

    constructor() ERC721A("TheANARCHY", "ANC") Ownable(OWNER) {
        _grantRole(DEFAULT_ADMIN_ROLE, OWNER);
        _grantRole(OPERATOR_ROLE, OWNER);
        _grantRole(OPERATOR_ROLE, _msgSender());

        _setDefaultRoyalty(OWNER, 1000);
    }

    // ----------------------------------------------------------
    // Modifier
    // ----------------------------------------------------------

    modifier canMint(uint256 _quantity) {
        require(tx.origin == _msgSender(), "Caller is a contract");
        require(msg.value >= MINT_PRICE * _quantity, "Not enough eth");
        require(_quantity + totalSupply() <= MAX_SUPPLY, "Exceeds max supply");
        _;
    }

    // ----------------------------------------------------------
    // User functions
    // ----------------------------------------------------------

    function alMint(uint256 _quantity) external payable canMint(_quantity) {
        require(phase == Phase.ALSale, "Wrong phase");
        require(
            _quantity + presaleMinted[_msgSender()] <= allowList[_msgSender()],
            "Exceeds per wallet limit"
        );

        presaleMinted[_msgSender()] += _quantity;
        _safeMint(_msgSender(), _quantity);
    }

    function publicMint(uint256 _quantity) external payable canMint(_quantity) {
        require(phase == Phase.PublicSale, "Wrong phase");
        require(_quantity <= MAX_MINT_PER_TX, "Exceeds per Tx limit");

        _safeMint(_msgSender(), _quantity);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            isRevealed
                ? string(abi.encodePacked(ERC721A.tokenURI(tokenId), extension))
                : notRevealedURI;
    }

    // ----------------------------------------------------------
    // OPERATOR functions
    // ----------------------------------------------------------

    function airdropMint(
        address _to,
        uint256 _quantity
    ) external onlyRole(OPERATOR_ROLE) {
        require(_quantity + totalSupply() <= MAX_SUPPLY, "Exceeds max supply");
        _safeMint(_to, _quantity);
    }

    /**
     * @param _uri Ensure the URI ends with a `/`.
     */
    function setBaseURI(string memory _uri) external onlyRole(OPERATOR_ROLE) {
        baseURI = _uri;
    }

    function setNotRevealedURI(
        string memory _uri
    ) external onlyRole(OPERATOR_ROLE) {
        notRevealedURI = _uri;
    }

    function setExtension(
        string memory _extension
    ) external onlyRole(OPERATOR_ROLE) {
        extension = _extension;
    }

    function setIsRevealed(bool _status) external onlyRole(OPERATOR_ROLE) {
        isRevealed = _status;
    }

    function setPhasePaused() external onlyRole(OPERATOR_ROLE) {
        phase = Phase.Paused;
    }

    function setPhaseALSale() external onlyRole(OPERATOR_ROLE) {
        phase = Phase.ALSale;
    }

    function setPhasePublicSale() external onlyRole(OPERATOR_ROLE) {
        phase = Phase.PublicSale;
    }

    function setAllowList(
        address[] calldata _accounts,
        uint256[] calldata _quantities
    ) external onlyRole(OPERATOR_ROLE) {
        require(_accounts.length == _quantities.length, "Length must match");

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 oldQuantity = allowList[account];
            uint256 newQuantity = _quantities[i];

            allowList[account] = newQuantity;

            if (newQuantity > oldQuantity) {
                allowListSum += (newQuantity - oldQuantity);
            } else {
                allowListSum -= (oldQuantity - newQuantity);
            }
        }
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyRole(OPERATOR_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function withdraw() external onlyRole(OPERATOR_ROLE) {
        uint256 sendAmount = address(this).balance;

        address addr1 = payable(0x4b3CCD7cE7C1Ca0B0277800cd938De64214d81F3);
        address addr2 = payable(0x97Db2bB6eF34486620EEB748306C0b3E2C766c3F);
        address addr3 = payable(OWNER);

        uint256 add1Value = (sendAmount * 110) / 1000;
        uint256 add2Value = (sendAmount * 55) / 1000;
        uint256 add3Value = sendAmount - add1Value - add2Value;

        bool success;

        (success, ) = addr1.call{value: add1Value}("");
        require(success, "Transfer failed!");
        (success, ) = addr2.call{value: add2Value}("");
        require(success, "Transfer failed!");
        (success, ) = addr3.call{value: add3Value}("");
        require(success, "Transfer failed!");
    }

    // ----------------------------------------------------------
    // internal functions
    // ----------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ----------------------------------------------------------
    // interface
    // ----------------------------------------------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, AccessControl, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
