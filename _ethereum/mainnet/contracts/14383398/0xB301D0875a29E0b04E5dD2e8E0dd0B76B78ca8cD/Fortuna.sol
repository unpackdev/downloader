//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ERC721Upgradeable.sol";

/***
 *
 *
 *    `7MM"""YMM   .g8""8q. `7MM"""Mq. MMP""MM""YMM `7MMF'   `7MF'`7MN.   `7MF'     db
 *      MM    `7 .dP'    `YM. MM   `MM.P'   MM   `7   MM       M    MMN.    M      ;MM:
 *      MM   d   dM'      `MM MM   ,M9      MM        MM       M    M YMb   M     ,V^MM.
 *      MM""MM   MM        MM MMmmdM9       MM        MM       M    M  `MN. M    ,M  `MM
 *      MM   Y   MM.      ,MP MM  YM.       MM        MM       M    M   `MM.M    AbmmmqMA
 *      MM       `Mb.    ,dP' MM   `Mb.     MM        YM.     ,M    M     YMM   A'     VML
 *    .JMML.       `"bmmd"' .JMML. .JMM.  .JMML.       `bmmmmd"'  .JML.    YM .AMA.   .AMMA.
 *
 *
 */

contract Fortuna is OwnableUpgradeable, ERC721Upgradeable {
    uint256 public constant MAX_SUPPLY = 7777;

    uint256 public constant SALE_PRIVATE_PRICE = 0.065 ether;
    uint256 public constant SALE_PUBLIC_PRICE = 0.077 ether;

    uint256 public SALE_PUBLIC_STARTED_AT;
    uint256 public SALE_PRIVATE_STARTED_AT;

    uint256 public supply;

    address private _proxyRegistryAddress;
    address private _verifier;

    string private _baseTokenURI;

    struct TokenMeta {
        address owner;
        uint96 meta;
    }

    mapping(uint256 => TokenMeta) public tokenState;
    uint256[] internal _tokenStateKeys;

    mapping(address => uint16) public tokenOwnerState;

    mapping(address => int16) private _balances;

    mapping(address => bool) private _operators;

    function initialize(address verifier_, address operator_, address proxyRegistryAddress_)
        public
        initializer
    {
        __ERC721_init('Fortuna', 'FRTN');
        __Ownable_init();

        _verifier = verifier_;
        _proxyRegistryAddress = proxyRegistryAddress_;

        _operators[_msgSender()] = true;
        _operators[operator_] = true;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function actualOwnerOf(uint256 tokenId) public view returns (address) {
        if (tokenState[tokenId].owner != address(0)) {
            return tokenState[tokenId].owner;
        }

        address tokenIdOwner = address(uint160(tokenId));
        uint16 tokenIndex = uint16(tokenId >> 160);

        require(tokenOwnerState[tokenIdOwner] != 0, 'Token not minted');
        require(
            tokenIndex < tokenOwnerState[tokenIdOwner],
            'Invalid token index'
        );

        return tokenIdOwner;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner_ != address(0),
            'ERC721: balance query for the zero address'
        );

        return uint16(int16(tokenOwnerState[owner_]) + _balances[owner_]);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return actualOwnerOf(tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (tokenState[tokenId].owner != address(0)) {
            return true;
        }

        address tokenIdOwner = address(uint160(tokenId));
        uint16 tokenIndex = uint16(tokenId >> 160);

        return
            (tokenOwnerState[tokenIdOwner] != 0) &&
            (tokenIndex < tokenOwnerState[tokenIdOwner]);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            ownerOf(tokenId) == from,
            'ERC721: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        require(to != from, "ERC721: can't transfer themself");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (tokenState[tokenId].owner == address(0)) {
            _tokenStateKeys.push(tokenId);
        }

        _balances[from] -= 1;
        _balances[to] += 1;

        tokenState[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return
            ECDSAUpgradeable.recover(
                ECDSAUpgradeable.toEthSignedMessageHash(hash),
                signature
            );
    }

    function _mintTokens(address receiver, uint16 amount) internal {
        require(supply + amount <= MAX_SUPPLY, 'FRTN: supply overflow');

        uint16 tokensAmount = tokenOwnerState[receiver] + amount;

        uint256 ownerBase = uint256(uint160(receiver));

        for (
            uint256 index = tokenOwnerState[receiver];
            index < tokensAmount;
            index++
        ) {
            emit Transfer(address(0), receiver, ownerBase | (index << 160));
        }

        tokenOwnerState[receiver] = tokensAmount;

        supply += amount;
    }

    function _mintBase(
        uint8 mintType,
        uint16 amount,
        uint16 maxAmount,
        uint256 timestamp,
        bytes memory sig
    ) internal {
        require(block.timestamp < timestamp, 'Outdated transaction');

        address sender = _msgSender();

        require(
            tokenOwnerState[sender] + amount <= maxAmount,
            'Mint amount exceeded'
        );

        bytes32 hash = keccak256(abi.encodePacked(mintType, sender, amount, timestamp));

        require(
            _verifier == _recoverSigner(hash, sig),
            'FRTN: invalid signature'
        );

        _mintTokens(sender, amount);
    }

    function mintPresale(
        uint16 amount,
        uint256 timestamp,
        bytes memory sig
    ) public payable {
        require(SALE_PRIVATE_STARTED_AT > 0, 'FRTN: sale should be active');

        require(
            msg.value >= amount * SALE_PRIVATE_PRICE,
            'FRTN: not enough funds for presale'
        );

        _mintBase(0, amount, 6, timestamp, sig);
    }

    function mint(
        uint16 amount,
        uint256 timestamp,
        bytes memory sig
    ) public payable {
        require(SALE_PUBLIC_STARTED_AT > 0, 'FRTN: sale should be active');

        require(
            msg.value >= amount * SALE_PUBLIC_PRICE,
            'FRTN: not enough funds for sale'
        );

        _mintBase(1, amount, 12, timestamp, sig);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner_, address operator_)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator_) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return supply;
    }

    /* onlyOwner */

    modifier onlyOperator() {
        require(_operators[_msgSender()] == true, 'Caller is not the operator');
        _;
    }

    function setOperator(address operatorAddress, bool value) public onlyOwner {
        _operators[operatorAddress] = value;
    }

    function setVerifier(address verifier_) external onlyOwner {
        _verifier = verifier_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setState(
        bool publicSaleState_,
        bool privateSaleState_
    ) external onlyOwner {
        SALE_PUBLIC_STARTED_AT = publicSaleState_ ? block.timestamp : 0;

        SALE_PRIVATE_STARTED_AT = privateSaleState_ ? block.timestamp : 0;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success, ) = _msgSender().call{value: amount}('');
        require(success, 'Withdraw failed');
    }

    function withdrawAll() external onlyOwner {
        withdraw(address(this).balance);
    }

    function mintForWallet(address wallet, uint16 amount) external onlyOperator {
        address receiver = wallet == address(0) ? _msgSender() : wallet;

        _mintTokens(receiver, amount);
    }

    function mintForWalletBatch(
        address[] calldata wallets,
        uint16[] calldata amounts
    ) external onlyOwner {
        require(wallets.length == amounts.length, 'Mismatched arrays');

        for (uint256 i; i < wallets.length; i++) {
            _mintTokens(wallets[i], amounts[i]);
        }
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
