// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Charcuterie is ERC721, Ownable, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");

    uint256 public constant unit_cost = 0.059 ether; // cost of one charcuterie
    uint256 public constant max_supply = 6200; // amount of tokens to public

    uint256 public transaction_limit = 25; // mint limit per transaction

    uint256 public reserved = 200; // reserved for team/marketing

    bool public paused_sale = true;
    bool public paused_pre_sale = true;
    string private _baseTokenURI =
        "ipfs://QmXWD3zUoUCVK1c4xL862XHz6Gnqz5hsdhgg4T5MQgfqcY/";
    address public poe_address = 0x5945bAF9272e0808165aDea61b932eC1604FB161;

    address private constant deposit =
        0xaD2Dca2E9Ff750d51b3f31Ca13343763C67C3BCe;

    modifier saleNotPaused() {
        require(!paused_sale, "Charcuterie: mint is paused");
        _;
    }

    modifier preSaleNotPaused() {
        require(!paused_pre_sale, "Charcuterie: pre sale is paused");
        _;
    }

    modifier preSaleAllowedAccount() {
        require(
            hasRole(WHITE_LIST_ROLE, msg.sender) ||
                IERC20(poe_address).balanceOf(msg.sender) == 1,
            "Charcuterie: account is not allowed to pre mint"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    fallback() external payable {}

    receive() external payable {}

    function toggleSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused_sale = !paused_sale;
    }

    function togglePreSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused_pre_sale = !paused_pre_sale;
    }

    function mint(uint256 num) public payable saleNotPaused {
        require(
            _tokenSupply.current() + num <= max_supply - reserved,
            "Charcuterie: Exceeds max supply"
        );
        require(
            msg.value >= unit_cost * num,
            "Charcuterie: Ether sent is less than unit_cost * num"
        );
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function preMint(uint256 num)
        public
        payable
        preSaleNotPaused
        preSaleAllowedAccount
    {
        require(
            _tokenSupply.current() + num <= max_supply - reserved,
            "Charcuterie: Exceeds max supply"
        );
        require(
            num <= transaction_limit,
            "Charcuterie: Exceeds transaction limit"
        );
        require(
            msg.value >= unit_cost * num,
            "Charcuterie: Ether sent is less than unit_cost * num"
        );
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
    }

    function adminMint(uint256 num) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(num <= reserved, "Charcuterie: Exceeds reserved supply");
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }
        reserved = reserved - num;
    }

    function batchWhitelist(address[] calldata _addresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            grantRole(WHITE_LIST_ROLE, _addresses[i]);
        }
    }

    function setBaseURI(string memory baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI;
    }

    function setPOEAddress(address _poe_address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        poe_address = _poe_address;
    }

    function withdraw() public onlyOwner {
        payable(deposit).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Charcuterie: URI query for nonexistent token"
        );

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
                : "";
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}
