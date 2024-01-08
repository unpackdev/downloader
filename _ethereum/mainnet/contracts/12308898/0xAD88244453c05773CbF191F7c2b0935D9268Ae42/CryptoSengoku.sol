// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CryptoSengoku is Context, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    address[] public accountOwnersByTokens;

    uint256 public MAX_HERO_SUPPLY = 71;

    // Unique Edition
    struct UniqueEdition {
        address originalAddress;
        address currentAddress;
        uint256 date;
        uint256 serie;
        uint256 tokenId;
    }
    uint256 public uniqueEditionPrice = 5000000000000000000;
    mapping(uint256 => UniqueEdition) uniqueEditionOwners;
    mapping(address => bool) uniqueEditionOwnersReceiver;
    address[] uniqueEditionLog;

    event onUserBuysUniqueEdition(address, uint256, string);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        accountOwnersByTokens = new address[](MAX_HERO_SUPPLY);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function updateBaseURI(string memory prefix) public onlyOwner {
        _baseTokenURI = prefix;
    }

    // Help to connect accounts with tokenId
    function setAccountOwnerInTokenId(address owner, uint256 tokenId) private {
        accountOwnersByTokens[tokenId] = owner;
    }

    function getAccountOwnerOfTokenIndex()
        public
        view
        returns (address[] memory)
    {
        return accountOwnersByTokens;
    }

    function mint(address to) public virtual onlyOwner {
        require(
            _tokenIdTracker.current() < MAX_HERO_SUPPLY,
            "All base supply were minted"
        );
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Reward functionality allows users to buy and mint
     *  (just one per address) an extra token
     *   when all base heroes were deployed
     */
    function buyUniqueEdition() public payable {
        require(
            !uniqueEditionOwnersReceiver[_msgSender()],
            "This account arleady got an Unique Edition"
        );
        require(
            (totalSupply() - uniqueEditionLog.length) >= MAX_HERO_SUPPLY,
            "Still min. amount of token to mint"
        );
        require(
            msg.value >= uniqueEditionPrice,
            "The amount is lower than price"
        );

        uint256 currentSerie = requireNextSerie();
        uint256 currentTokenId = _tokenIdTracker.current();

        uniqueEditionOwners[currentTokenId].originalAddress = _msgSender();
        uniqueEditionOwners[currentTokenId].currentAddress = _msgSender();
        uniqueEditionOwners[currentTokenId].date = block.timestamp;
        uniqueEditionOwners[currentTokenId].serie = currentSerie;
        uniqueEditionOwners[currentTokenId].tokenId = currentTokenId;
        uniqueEditionOwnersReceiver[_msgSender()] = true;

        // increase accountOwnersByTokens
        accountOwnersByTokens.push(_msgSender());

        mintUniqueEdition(_msgSender());

        emit onUserBuysUniqueEdition(
            _msgSender(),
            currentSerie,
            "New unique edition was released"
        );
    }

    function mintUniqueEdition(address to) private {
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function setUniqueEditionPrice(uint256 newPrice) public onlyOwner {
        uniqueEditionPrice = newPrice;
    }

    function getUniqueEditionByTokenId(uint256 tokenId)
        public
        view
        returns (UniqueEdition memory)
    {
        require(isUniqueEdition(tokenId), "This tokenId is not Unique Edition");
        return uniqueEditionOwners[tokenId];
    }

    function requireNextSerie() private returns (uint256) {
        uniqueEditionLog.push(_msgSender());
        return uniqueEditionLog.length;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        setAccountOwnerInTokenId(to, tokenId);
        if (isUniqueEdition(tokenId)) {
            uniqueEditionOwners[tokenId].currentAddress = to;
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isUniqueEdition(uint256 tokenId) public view returns (bool) {
        return tokenId >= MAX_HERO_SUPPLY ? true : false;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function sendBalance(address payable to, uint256 amount) public onlyOwner {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = to.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}
