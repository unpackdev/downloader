// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./draft-EIP712.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

struct TokenRemainingEntry {
    address account;
    uint256 balance;
    bool isSet;
}

contract RetroPawz is ERC721, EIP712, ERC721Enumerable, AccessControl, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(bytes => TokenRemainingEntry) public remainingTokensForVoucher;

    string public PROVENANCE;

    uint256 public constant MAX_PURCHASE_ALLOW = 20;

    uint256 public collectionSize;

    uint256 public salePrice = 50000000000000000;

    string private baseUri;

    bool public saleIsActive = false;

    bool public isAllowListActive = false;

    bool public isRedeemActive = false;

    mapping(address => uint8) private _allowList;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _collectionSize,
        string memory _baseUri
    ) ERC721(name, symbol) EIP712(name, "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        collectionSize = _collectionSize;
        baseUri = _baseUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getSalePrice() public view returns (uint256) {
        return salePrice;
    }

    function setSalePrice(uint256 _salePrice) public onlyOwner {
        require(_salePrice > 0, "Sale price must be greather than 0");
        salePrice = _salePrice;
    }

    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setCollectionSize(uint256 _collectionSize) public onlyOwner {
        require(
            collectionSize > totalSupply(),
            "The collection size can't be less than the total supply"
        );

        collectionSize = _collectionSize;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setSaleState(bool newState) public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleIsActive = newState;
    }

    function setRedeemActive(bool newState)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isRedeemActive = newState;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserve(uint256 n) public onlyOwner {
        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender);
        }
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(
            numberOfTokens <= _allowList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= collectionSize,
            "Purchase would exceed max tokens"
        );
        require(
            salePrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function sale(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active to mint tokens");
        require(
            numberOfTokens <= MAX_PURCHASE_ALLOW,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= getCollectionSize(),
            "Purchase would exceed max supply"
        );
        require(
            numberOfTokens * getSalePrice() <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function redeem(
        uint256 numberOfTokens,
        uint256 tokenAmountInSignature,
        bytes calldata signature
    ) external {
        uint256 ts = totalSupply();

        require(isRedeemActive, "Redeem is not available at the moment");

        require(
            _verify(_hash(msg.sender, tokenAmountInSignature), signature),
            "Invalid signature"
        );
        require(_verifyVoucherHasBalance(signature), "No tokens remaining");
        require(ts + 1 <= getCollectionSize(), "Sold out!");
        require(
            numberOfTokens <= MAX_PURCHASE_ALLOW,
            "Can only mint 20 tokens at a time"
        );
        require(
            ts + numberOfTokens <= getCollectionSize(),
            "Purchase would exceed max supply"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }

        _updateRemainingTokensForAccount(
            signature,
            msg.sender,
            numberOfTokens,
            tokenAmountInSignature
        );
    }

    function _hash(address account, uint256 tokenCount)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("RetroPawz(uint tokenCount,address account)"),
                        tokenCount,
                        account
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, ECDSA.recover(digest, signature));
    }

    function _verifyVoucherHasBalance(bytes calldata signature)
        internal
        view
        returns (bool)
    {
        if (!remainingTokensForVoucher[signature].isSet) {
            // If the entry doesn't exists, that means that the user hasn't
            // redeem a token assuming that the signature was valid
            return true;
        }

        return remainingTokensForVoucher[signature].balance > 0;
    }

    function _updateRemainingTokensForAccount(
        bytes calldata signature,
        address account,
        uint256 numberOfTokens,
        uint256 tokenAmountInSignature
    ) internal {
        if (!remainingTokensForVoucher[signature].isSet) {
            remainingTokensForVoucher[signature].balance =
                tokenAmountInSignature -
                numberOfTokens;
            remainingTokensForVoucher[signature].isSet = true;
            remainingTokensForVoucher[signature].account = account;
        } else {
            remainingTokensForVoucher[signature].balance -= numberOfTokens;
        }
    }

    function _safeMint(address to) private {
        require(
            totalSupply() < getCollectionSize(),
            "Minting will exceed the max supply"
        );

        uint256 currentTokenId = _tokenIdCounter.current();
        _safeMint(to, currentTokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
