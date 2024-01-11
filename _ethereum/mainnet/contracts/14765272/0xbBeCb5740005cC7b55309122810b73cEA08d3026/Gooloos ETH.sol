// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./draft-EIP712.sol";

contract Gooloos is ERC721Enumerable, EIP712, Ownable {
    using Counters for Counters.Counter;

    uint public constant MAX_SUPPLY = 9900;
    uint public constant NORMAL_UNIT_PRICE = 0.03 ether;
    uint public constant WHITELIST_UNIT_PRICE = 0.00 ether;

    address private constant _SIGNER_PUBLIC_KEY = 0x5714410d6D3ECE9b78CEF0E70b8aE92b379b8136;
    mapping(address => bool) private _usedWhitelistedAccounts;
    Counters.Counter private _tokenIdCounter;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721("Gooloos", "GLOO") EIP712("Gooloos", "1.0.0") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(amount > 0, "invalid amount");
        require(msg.value == amount * NORMAL_UNIT_PRICE, "invalid mint price");
        require(amount + totalSupply() <= MAX_SUPPLY, "amount exceeds max supply");

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender);
        }
    }

    function whitelistMint(uint amount, bytes calldata signature) external payable {
        require(_recoverAddress(msg.sender, amount, signature) == _SIGNER_PUBLIC_KEY, "account is not whitelisted");
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(msg.value == WHITELIST_UNIT_PRICE, "invalid mint price");
        require(!hasUsedWhitelistAccount(msg.sender), "account already used");
        require(amount + totalSupply() <= MAX_SUPPLY, "amount exceeds max supply");

        _usedWhitelistedAccounts[msg.sender] = true;

        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender);
        }
    }

    function hasUsedWhitelistAccount(address account) public view returns (bool) {
        return _usedWhitelistedAccounts[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        super._safeMint(to, tokenId);
    }

    function _hash(address account, uint amount) private view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Gooloos(address account,uint amount)"),
                    account,
                    amount
                )
            )
        );
    }

    function _recoverAddress(address account, uint amount, bytes calldata signature) private view returns (address) {
        return ECDSA.recover(_hash(account, amount), signature);
    }
}