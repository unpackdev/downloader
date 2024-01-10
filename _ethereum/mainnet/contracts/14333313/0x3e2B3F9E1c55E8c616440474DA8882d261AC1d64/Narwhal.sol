// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./AccessControl.sol";
import "./AccessControlEnumerable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Narwhal is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC721URIStorage,
    IERC2981
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    address private _receiver;
    uint256 private _fee;
    string private constant INVALID_PERMISSION = "Invalid permissions";

    bool public saleIsActive = false;

    uint256 public constant mintPrice = 10000000000000000; //0.01 ETH
    uint96 constant _FEE_DENOMINATOR = 10000;

    uint256 public constant MAX_PURCHASE = 10;

    uint256 public MAX_SUPPLY;

    /**
     * @dev Emitted when the sale status change as bool `status`.
     */
    event SaleStatusChange(bool indexed state);

    /**
     * @dev Emitted when new token is minted for `owner` with id `tokenId`.
     */
    event Mint(address indexed owner, uint256 indexed tokenId);

    constructor(uint256 maxNftSupply, uint256 fee)
        ERC721("Marvellous Narwhals", "Narwhals")
    {
        _baseTokenURI = "https://api.narwhallous.com/metadata/";

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAWAL_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _receiver = address(this); // is always the contract itself
        _fee = fee; // sets the default fee %
        MAX_SUPPLY = maxNftSupply;
    }

    /**
     * Internal function to mint a new token with the correct metadata
     */
    function _mintToken(address to) private {
        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(to, newTokenId);
        _setTokenURI(
            newTokenId,
            string(abi.encodePacked(Strings.toString(newTokenId), ".json"))
        );
        _tokenIdTracker.increment();
        emit Mint(to, newTokenId);
    }

    /**
     * Allow DEFAULT admins to reserve some tokens
     */
    function reserve(uint256 units) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        uint256 i;
        for (i = 0; i < units; i++) {
            _mintToken(_msgSender());
        }
        if (totalSupply() > MAX_SUPPLY) {
            MAX_SUPPLY = totalSupply(); // set a new max then
        }
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        saleIsActive = !saleIsActive;
        emit SaleStatusChange(saleIsActive);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setRoyaltyFee(uint256 fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        require(fee <= _FEE_DENOMINATOR, "royalty fee will exceed salePrice");
        _fee = fee;
    }

    function setMaxSupply(uint256 newMax) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        require(
            newMax > totalSupply(),
            "New Max would be smaller than current supply"
        );
        MAX_SUPPLY = newMax;
    }

    function setBaseURI(string memory newBaseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        _baseTokenURI = newBaseURI;
    }

    function withdraw(address payable to, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        require(
            hasRole(WITHDRAWAL_ROLE, to),
            "Adress we are sending to must have WITHDRAWAL role, this is to avoid typos"
        );
        uint256 balance = address(this).balance;
        require(
            amount <= balance,
            "Withdraw would exceed amount available in balance"
        );
        to.transfer(balance);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Can only mint 10 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );
        require(
            mintPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintToken(_msgSender());
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 amount = (salePrice * _fee) / _FEE_DENOMINATOR;
        return (_receiver, amount);
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), INVALID_PERMISSION);
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), INVALID_PERMISSION);
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    fallback() external payable {}
    receive() external payable {}
}
