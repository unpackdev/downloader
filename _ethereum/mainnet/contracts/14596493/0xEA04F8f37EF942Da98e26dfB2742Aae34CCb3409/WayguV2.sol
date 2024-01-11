// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract WagyuV2 is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard
{
    using Address for address;
    using SafeMath for uint256;

    event Airdrop(address[] addresses, uint256 amount);
    event AssignAirdropAddress(address indexed _address);
    event AssignBaseURI(string _value);
    event AssignDefaultURI(string _value);
    event AssignRevealBlock(uint256 _blockNumber);
    event Purchased(
        address indexed account,
        uint256 indexed index
    );
    event MintAttempt(address indexed account, bytes data);
    event PermanentURI(string _value, uint256 indexed _id);
    event WithdrawNonPurchaseFund(uint256 balance);

    PaymentSplitter private _splitter;

    struct revenueShareParams {
        address[] payees;
        uint256[] shares;
    }

    uint256 public revealBlock = 0;
    uint256 public maxSaleCapped = 1;

    string public _defaultURI;
    string public _tokenBaseURI;
    mapping(address => bool) private _airdropAllowed;
    mapping(address => uint256) public purchaseCount;

    uint256 PublicSalePrice = 1.8 ether;
    uint256 maxSupply = 1000;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
    }

    modifier airdropRoleOnly() {
        require(_airdropAllowed[msg.sender], "Only airdrop role allowed.");
        _;
    }

    modifier shareHolderOnly() {
        require(_splitter.shares(msg.sender) > 0, "not a shareholder");
        _;
    }

    function mintToken(uint256 amount)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(msg.sender == tx.origin, "Contract is not allowed.");
        require(msg.value >= PublicSalePrice*amount, "Send more ether");
        _mintToken(msg.sender, amount);
        payable(owner()).transfer(msg.value);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
        emit AssignBaseURI(baseURI);
    }

    function setDefaultURI(string memory defaultURI) external onlyOwner {
        _defaultURI = defaultURI;
        emit AssignDefaultURI(defaultURI);
    }

    function tokenBaseURI() external view returns (string memory) {
        return _tokenBaseURI;
    }

    function isRevealed() public view returns (bool) {
        return revealBlock > 0 && block.number > revealBlock;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId <= totalSupply(), "Token not exist.");

        return
            isRevealed()
                ? string(abi.encodePacked(_tokenBaseURI, tokenId, ".json"))
                : _defaultURI;
    }

    function availableForSale() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function release(address payable account) external virtual shareHolderOnly {
        require(
            msg.sender == account || msg.sender == owner(),
            "Release: no permission"
        );

        _splitter.release(account);
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            purchaseCount[addr] += 1;
            if (tokenIndex < maxSupply) {
                _safeMint(addr, tokenIndex + 1);
                emit Purchased(addr, tokenIndex);
            }
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}