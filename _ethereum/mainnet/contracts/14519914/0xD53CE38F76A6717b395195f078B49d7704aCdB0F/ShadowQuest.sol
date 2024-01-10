//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./ERC721Upgradeable.sol";

interface IHonorToken {
    function updateBalance(
        address wallet,
        uint256 debit,
        uint256 credit
    ) external;

    function mint(address wallet, uint256 amount) external;

    function burn(address wallet, uint256 amount) external;

    function balanceOf(address wallet) external view returns (uint256);
}

/***
 *     .oooooo..o ooooo   ooooo       .o.       oooooooooo.     .oooooo.   oooooo   oooooo     oooo
 *    d8P'    `Y8 `888'   `888'      .888.      `888'   `Y8b   d8P'  `Y8b   `888.    `888.     .8'
 *    Y88bo.       888     888      .8"888.      888      888 888      888   `888.   .8888.   .8'
 *     `"Y8888o.   888ooooo888     .8' `888.     888      888 888      888    `888  .8'`888. .8'
 *         `"Y88b  888     888    .88ooo8888.    888      888 888      888     `888.8'  `888.8'
 *    oo     .d8P  888     888   .8'     `888.   888     d88' `88b    d88'      `888'    `888'
 *    8""88888P'  o888o   o888o o88o     o8888o o888bood8P'    `Y8bood8P'        `8'      `8'
 *
 *
 *
 *      .oooooo.      ooooo     ooo oooooooooooo  .oooooo..o ooooooooooooo
 *     d8P'  `Y8b     `888'     `8' `888'     `8 d8P'    `Y8 8'   888   `8
 *    888      888     888       8   888         Y88bo.           888
 *    888      888     888       8   888oooo8     `"Y8888o.       888
 *    888      888     888       8   888    "         `"Y88b      888
 *    `88b    d88b     `88.    .8'   888       o oo     .d8P      888
 *     `Y8bood8P'Ybd'    `YbodP'    o888ooooood8 8""88888P'      o888o
 *
 *
 *
 */

contract ShadowQuest is OwnableUpgradeable, ERC721Upgradeable {
    event Move(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed direction
    );

    event LocationChanged(
        uint8 indexed locationIdFrom,
        uint8 indexed locationIdTo,
        uint256 amount
    );

    uint256 public constant MAX_GEN0_SUPPLY = 9996;
    uint256 public constant MAX_GEN1_SUPPLY = 18000;

    uint256 public constant SALE_PRIVATE_PRICE = 0.075 ether;
    uint256 public constant SALE_PUBLIC_PRICE = 0.08 ether;

    uint256 public SALE_PUBLIC_STARTED_AT;
    uint256 public SALE_PRIVATE_STARTED_AT;
    uint256 public SALE_PRIVATE_MAX_SUPPLY;

    uint256 public gen0Supply;
    uint256 public gen1Supply;

    string public provenanceHash;

    IHonorToken public honorContract;

    address private _proxyRegistryAddress;
    address private _verifier;

    string private _baseTokenURI;

    struct TokenMeta {
        address owner;
        uint32 movedAt;
        uint8 location;
        uint56 meta;
    }

    mapping(uint256 => TokenMeta) public tokenState;
    uint256[] internal _tokenStateKeys;

    mapping(address => uint16) public _tokenOwnerState;

    mapping(address => int16) private _balances;

    uint256 public locationsBalance;

    uint256[] public samsarIds;

    mapping(address => uint256) public honrDeposited;
    mapping(address => uint256) public honrWithdrawn;

    function initialize(address verifier_, address proxyRegistryAddress_)
        public
        initializer
    {
        __ERC721_init('ShadowQuest', 'SQ');
        __Ownable_init();

        _verifier = verifier_;
        _proxyRegistryAddress = proxyRegistryAddress_;

        SALE_PRIVATE_MAX_SUPPLY = 3000;
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

    function isOnArena(uint256 tokenId) internal view returns (bool) {
        return tokenState[tokenId].location > 0;
    }

    function actualOwnerOf(uint256 tokenId) public view returns (address) {
        if (tokenState[tokenId].owner != address(0)) {
            return tokenState[tokenId].owner;
        }

        address tokenIdOwner = address(uint160(tokenId));
        uint16 tokenIndex = uint16(tokenId >> 160);

        require(_tokenOwnerState[tokenIdOwner] != 0, 'SQ: not minted');
        require(
            tokenIndex < _tokenOwnerState[tokenIdOwner],
            'SQ: invalid index'
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

        if (owner_ == address(this)) {
            return locationsBalance;
        }

        return uint16(int16(_tokenOwnerState[owner_]) + _balances[owner_]);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (isOnArena(tokenId)) {
            return address(this);
        }

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
            (_tokenOwnerState[tokenIdOwner] != 0) &&
            (tokenIndex < _tokenOwnerState[tokenIdOwner]);
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

    event MintGen1(
        address indexed owner,
        uint256 indexed nonce,
        uint16 mintedAmount
    );

    event Steal(
        address indexed owner,
        address indexed samsarOwner,
        uint256 indexed samsarId,
        uint256 tokenId
    );

    function mintGen1(
        uint16 expectedAmount,
        uint256[] calldata samsarIds_,
        uint256 nonce,
        uint256 timestamp,
        bytes memory sig
    ) external {
        address sender = _msgSender();

        require(uint160(sender) == uint160(nonce), 'nonce mismatch');

        uint16 tokenAmount = _tokenOwnerState[sender];

        uint16 amount = expectedAmount - tokenAmount;
        uint16 stolen = uint16(samsarIds_.length);

        require(
            amount > 0 && amount <= 10 && stolen <= amount,
            'SQ: invalid amount'
        );

        require(
            gen1Supply + amount < MAX_GEN1_SUPPLY,
            'SQ: gen1 supply exceeded'
        );

        require(block.timestamp < timestamp, 'SQ: outdated transaction');

        bytes32 hash = keccak256(
            abi.encodePacked(
                sender,
                expectedAmount,
                samsarIds_,
                nonce,
                timestamp
            )
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        gen1Supply += amount;

        uint16 minted = amount - stolen;

        for (uint256 index; index < stolen; index++) {
            address samsarOwner = actualOwnerOf(samsarIds_[index]);

            uint256 tokenId = uint256(uint160(samsarOwner)) |
                (uint256(_tokenOwnerState[samsarOwner]) << 160);

            _tokenOwnerState[samsarOwner] += 1;

            emit Transfer(address(0), samsarOwner, tokenId);

            emit Steal(sender, samsarOwner, samsarIds_[index], tokenId);
        }

        uint256 ownerBase = uint256(uint160(sender));

        for (uint256 index; index < minted; index++) {
            emit Transfer(
                address(0),
                sender,
                ownerBase | (uint256(_tokenOwnerState[sender] + index) << 160)
            );
        }

        emit MintGen1(sender, nonce, minted);

        if (minted > 0) {
            _tokenOwnerState[sender] += minted;
        }
    }

    function move(
        uint8 locationIdFrom,
        uint8 locationIdTo,
        uint256[] calldata tokenIds,
        /**
         * nation, notIterable, samsarNotIterable
         */
        uint256[] calldata tokenMeta,
        uint256 timestamp,
        bytes memory sig
    ) external {
        require(block.timestamp < timestamp, 'SQ: outdated transaction');

        address sender = _msgSender();

        bytes32 hash = keccak256(
            abi.encodePacked(
                sender,
                locationIdFrom,
                locationIdTo,
                tokenIds,
                tokenMeta,
                timestamp
            )
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        for (uint256 index; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];

            require(
                actualOwnerOf(tokenId) == sender,
                'SQ: not owner of the token'
            );

            TokenMeta storage _tokenMeta = tokenState[tokenId];

            require(
                _tokenMeta.location == locationIdFrom,
                'SQ: incorrect location'
            );

            if (uint8(tokenMeta[index] >> 8) == 1) {
                _tokenStateKeys.push(tokenId);
            }

            if (uint8(tokenMeta[index] >> 16) == 1) {
                samsarIds.push(tokenId);
            }

            tokenState[tokenId] = TokenMeta({
                owner: sender,
                movedAt: uint32(block.timestamp),
                location: locationIdTo,
                meta: uint8(tokenMeta[index])
            });

            if (locationIdTo == 0) {
                emit Transfer(address(this), sender, tokenId);
            } else if (locationIdFrom == 0) {
                emit Transfer(sender, address(this), tokenId);
            }
        }

        uint256 tokensAmount = tokenIds.length;

        if (locationIdFrom == 0) {
            locationsBalance += tokensAmount;
        } else if (locationIdTo == 0) {
            locationsBalance -= tokensAmount;
        }

        emit LocationChanged(locationIdFrom, locationIdTo, tokensAmount);
    }

    event HonrWithdraw(
        address indexed wallet,
        uint256 indexed nonce,
        uint256 amount
    );

    function honrWithdraw(
        uint256 amount,
        uint256 expectedAmount,
        uint256 nonce,
        uint256 timestamp,
        bytes memory sig
    ) external {
        address sender = _msgSender();

        require(uint160(sender) == uint160(nonce), 'nonce mismatch');

        bytes32 hash = keccak256(
            abi.encodePacked(sender, amount, expectedAmount, nonce, timestamp)
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        require(
            honrWithdrawn[sender] + amount == expectedAmount,
            'SQ: invalid transaction'
        );

        honorContract.mint(sender, amount);

        honrWithdrawn[sender] += amount;

        emit HonrWithdraw(sender, nonce, amount);
    }

    event HonrDeposit(address indexed wallet, uint256 amount);

    function honrDeposit(
        uint256 amount,
        uint256 timestamp,
        bytes memory sig
    ) external {
        address sender = _msgSender();

        bytes32 hash = keccak256(abi.encodePacked(sender, amount, timestamp));

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        honorContract.burn(sender, amount);

        honrDeposited[sender] += amount;

        emit HonrDeposit(sender, amount);
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
        return gen0Supply + gen1Supply - locationsBalance;
    }

    struct TokenData {
        address owner;
        uint8 location;
        uint32 movedAt;
        uint56 meta;
        uint256 tokenId;
    }

    function sliceTokenStateArray(
        TokenData[] memory arr,
        uint256 start,
        uint256 length
    ) internal pure returns (TokenData[] memory) {
        TokenData[] memory result = new TokenData[](length);

        for (uint256 index; index < length; index++) {
            result[index] = arr[start + index];
        }

        return result;
    }

    function getSamsarTokens() external view returns (uint256[] memory) {
        return samsarIds;
    }

    function getTokenStateKeys() external view returns (uint256[] memory) {
        return _tokenStateKeys;
    }

    /**
     * @dev location_ == -1 – any location
     */
    function getOwnerTokens(address owner_, int8 location_)
        public
        view
        returns (TokenData[] memory)
    {
        require(
            owner_ != address(0),
            'ERC721: balance query for the zero address'
        );

        uint256 balance = balanceOf(owner_);

        TokenData[] memory ownedTokens = new TokenData[](balance);

        uint256 ownerBase = uint256(uint160(owner_));
        uint256 mintedAmount = _tokenOwnerState[owner_];
        uint256 resultIndex;

        for (uint256 index; index < mintedAmount; index++) {
            uint256 tokenId = ownerBase | (index << 160);

            TokenMeta storage currentTokenState = tokenState[tokenId];

            if (
                currentTokenState.owner == address(0) &&
                (location_ == -1 || location_ == 0)
            ) {
                ownedTokens[resultIndex++] = TokenData({
                    owner: currentTokenState.owner,
                    location: currentTokenState.location,
                    movedAt: currentTokenState.movedAt,
                    meta: currentTokenState.meta,
                    tokenId: tokenId
                });
            } else if (currentTokenState.owner == owner_) {
                if (
                    location_ == -1 ||
                    uint8(location_) == currentTokenState.location
                ) {
                    ownedTokens[resultIndex++] = TokenData({
                        owner: currentTokenState.owner,
                        location: currentTokenState.location,
                        movedAt: currentTokenState.movedAt,
                        meta: currentTokenState.meta,
                        tokenId: tokenId
                    });
                }
            }
        }

        for (uint256 index = 0; index < _tokenStateKeys.length; index++) {
            if (resultIndex == balance) {
                break;
            }

            uint256 tokenId = _tokenStateKeys[index];

            if (tokenState[tokenId].owner != owner_) {
                continue;
            }

            address tokenIdOwner = address(uint160(tokenId));

            if (tokenIdOwner == owner_) {
                continue;
            }

            if (
                location_ == -1 ||
                tokenState[tokenId].location == uint8(location_)
            ) {
                TokenMeta storage currentTokenState = tokenState[tokenId];

                ownedTokens[resultIndex++] = TokenData({
                    owner: currentTokenState.owner,
                    location: currentTokenState.location,
                    movedAt: currentTokenState.movedAt,
                    meta: currentTokenState.meta,
                    tokenId: tokenId
                });
            }
        }

        return sliceTokenStateArray(ownedTokens, 0, resultIndex);
    }

    /* OwnerOnly */

    function setVerifier(address verifier_) external onlyOwner {
        _verifier = verifier_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function withdraw(uint256 amount) public onlyOwner {
        (bool success, ) = _msgSender().call{value: amount}('');
        require(success, 'Withdraw failed');
    }

    function withdrawAll() external onlyOwner {
        withdraw(address(this).balance);
    }

    function setHonorContract(IHonorToken honorContract_) external onlyOwner {
        honorContract = honorContract_;
    }

    function setLocationsBalance(uint256 amount) external onlyOwner {
        locationsBalance = amount;
    }

    function pushTokenStateKeys(uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        uint256 tokensAmount = tokenIds.length;
        for (uint256 index; index < tokensAmount; index++) {
            _tokenStateKeys.push(tokenIds[index]);
        }
    }

    function _mintGen0(address sender, uint16 amount) internal {
        require(
            gen0Supply + amount <= MAX_GEN0_SUPPLY,
            'SQ: gen0 supply overflow'
        );

        uint16 tokensAmount = _tokenOwnerState[sender] + amount;

        uint256 ownerBase = uint256(uint160(sender));

        for (
            uint256 index = _tokenOwnerState[sender];
            index < tokensAmount;
            index++
        ) {
            emit Transfer(address(0), sender, ownerBase | (index << 160));
        }

        _tokenOwnerState[sender] = tokensAmount;

        gen0Supply += amount;
    }

    function mintReserved(address wallet, uint16 amount) external onlyOwner {
        address receiver = wallet == address(0) ? _msgSender() : wallet;

        _mintGen0(receiver, amount);
    }

    function emitFalseMints(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 index; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            address tokenIdOwner = address(uint160(tokenId));

            require(_exists(tokenId), 'ERC721: non-existent token');

            if (tokenState[tokenId].owner != address(0)) {
                continue;
            }

            emit Transfer(address(0), tokenIdOwner, tokenId);
        }
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
