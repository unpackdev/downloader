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

    mapping(address => uint16) private _tokenOwnerState;

    mapping(address => int16) private _balances;

    function initialize(
        address verifier_,
        address proxyRegistryAddress_
    ) public initializer {
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
        uint16 tokenIndex = uint16(tokenId << 160);

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
        uint16 tokenIndex = uint16(tokenId << 160);

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

    function _mintBase(
        uint16 amount,
        uint16 maxAmount,
        uint256 timestamp,
        bytes memory sig
    ) internal {
        require(block.timestamp < timestamp, 'SQ: outdated transaction');

        address sender = _msgSender();

        require(
            _tokenOwnerState[sender] + amount <= maxAmount,
            'SQ: mint amount exceeded'
        );

        bytes32 hash = keccak256(
            abi.encodePacked(sender, amount, timestamp)
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        _mintGen0(sender, amount);
    }

    function mintPresale(
        uint16 amount,
        uint256 timestamp,
        bytes memory sig
    ) public payable {
        require(SALE_PRIVATE_STARTED_AT > 0, 'SQ: sale should be active');

        require(
            msg.value >= amount * SALE_PRIVATE_PRICE,
            'SQ: not enough funds for presale'
        );

        require(
            gen0Supply + amount <= SALE_PRIVATE_MAX_SUPPLY,
            'SQ: gen0 supply overflow'
        );

        _mintBase(amount, 10, timestamp, sig);
    }

    function mint(
        uint16 amount,
        uint256 timestamp,
        bytes memory sig
    ) public payable {
        require(SALE_PUBLIC_STARTED_AT > 0, 'SQ: sale should be active');

        require(
            msg.value >= amount * SALE_PUBLIC_PRICE,
            'SQ: not enough funds for sale'
        );

        _mintBase(amount, 20, timestamp, sig);
    }

    function random(uint256 nonce, uint256 number)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        nonce,
                        msg.sender
                    )
                )
            ) % number;
    }

    function mintGen1(
        uint16 amount,
        uint256[] calldata samsarIds,
        uint256 timestamp,
        bytes memory sig
    ) external {
        require(
            samsarIds.length == amount && amount <= 10,
            'SQ: invalid amount'
        );

        require(
            gen1Supply + amount < MAX_GEN1_SUPPLY,
            'SQ: gen1 supply exceeded'
        );

        require(block.timestamp < timestamp, 'SQ: outdated transaction');

        address sender = _msgSender();

        uint256 price = 20000 + 4 * gen1Supply;

        require(
            honorContract.balanceOf(sender) >= price * amount,
            'SQ: not enough funds'
        );

        bytes32 hash = keccak256(
            abi.encodePacked(sender, amount, samsarIds, timestamp)
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        uint256 ownerBase = uint256(uint160(sender));

        uint16 tokenAmount = _tokenOwnerState[sender];

        bool stolen = false;

        for (uint16 index; index < amount; index++) {
            uint256 samsarId = samsarIds[index];
            uint256 rand = stolen ? 100 : random(samsarId + index, 100);

            if (rand < 10 && isOnArena(samsarId)) {
                address samsarOwner = actualOwnerOf(samsarId);

                emit Transfer(
                    address(0),
                    sender,
                    uint256(uint160(samsarOwner)) |
                        (_tokenOwnerState[samsarOwner] << 160)
                );

                _tokenOwnerState[samsarOwner] += 1;

                stolen = true;
            } else {
                emit Transfer(
                    address(0),
                    sender,
                    ownerBase | (tokenAmount << 160)
                );

                tokenAmount += 1;
            }
        }

        _tokenOwnerState[sender] = tokenAmount;

        gen1Supply += amount;
    }

    function move(
        uint8 locationId,
        uint256[] calldata tokenIds,
        uint256 timestamp,
        bytes memory sig
    ) external {
        require(block.timestamp < timestamp, 'SQ: outdated transaction');

        address sender = _msgSender();

        bytes32 hash = keccak256(
            abi.encodePacked(sender, locationId, tokenIds, timestamp)
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        for (uint16 index; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];

            require(
                actualOwnerOf(tokenId) == sender,
                'SQ: not owner of the token'
            );

            TokenMeta storage _tokenMeta = tokenState[tokenId];
            uint8 currentLocation = _tokenMeta.location;

            if (tokenState[tokenId].owner == address(0)) {
                _tokenStateKeys.push(tokenId);
            }

            tokenState[tokenId] = TokenMeta({
                owner: sender,
                movedAt: uint32(block.timestamp),
                location: locationId,
                meta: 0
            });

            emit Move(sender, tokenId, currentLocation | (locationId << 8));
        }
    }

    function claim(
        uint256 debit,
        uint256 credit,
        uint256 timestamp,
        bytes memory sig
    ) external {
        address sender = _msgSender();

        bytes32 hash = keccak256(
            abi.encodePacked(sender, debit, credit, timestamp)
        );

        require(
            _verifier == _recoverSigner(hash, sig),
            'SQ: invalid signature'
        );

        honorContract.updateBalance(sender, debit, credit);
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
        return gen0Supply + gen1Supply;
    }

    /**
     * @dev location_ == -1 – any location
     */
    function getOwnerTokens(address owner_, int8 location_)
        public
        view
        returns (uint256[] memory)
    {
        require(
            owner_ != address(0),
            'ERC721: balance query for the zero address'
        );

        uint256 balance = balanceOf(owner_);

        uint256[] memory ownedTokens = new uint256[](balance);

        uint256 ownerBase = uint256(uint160(owner_));
        uint256 mintedAmount = _tokenOwnerState[owner_];
        uint256 resultIndex;

        for (uint256 index; index < mintedAmount; index++) {
            uint256 tokenId = ownerBase | (index << 160);

            if (
                tokenState[tokenId].owner == address(0) &&
                (location_ == -1 || location_ == 0)
            ) {
                ownedTokens[resultIndex++] = tokenId;
            }
        }

        for (uint256 index = 0; index < balance; index++) {
            uint256 tokenId = _tokenStateKeys[index];

            if (
                tokenState[tokenId].owner == owner_ &&
                (location_ == -1 ||
                    int8(tokenState[tokenId].location) == location_)
            ) {
                ownedTokens[resultIndex++] = tokenId;
            }
        }

        uint256[] memory resultToknes = new uint256[](resultIndex);

        for (uint256 index = 0; index < resultIndex; index++) {
            resultToknes[index] = ownedTokens[index];
        }

        return resultToknes;
    }

    function getLocationTime(uint256 tokenId, uint256 timestamp_)
        public
        view
        returns (uint256)
    {
        return timestamp_ - tokenState[tokenId].movedAt;
    }

    function getTrainingGroundHonr(address owner_, uint256 timestamp_)
        public
        view
        returns (uint256)
    {
        uint256[] memory tokens = getOwnerTokens(owner_, 1);
        uint256 honr = 0;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];

            honr += (getLocationTime(tokenId, timestamp_) / 1 hours) * 125;
        }

        return honr;
    }

    /* OwnerOnly */

    function setVerifier(address verifier_) external onlyOwner {
        _verifier = verifier_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setState(
        bool publicSaleState_,
        bool privateSaleState_,
        uint256 maxPresaleSupply_
    ) external onlyOwner {
        SALE_PUBLIC_STARTED_AT = publicSaleState_ ? block.timestamp : 0;

        SALE_PRIVATE_STARTED_AT = privateSaleState_ ? block.timestamp : 0;

        SALE_PRIVATE_MAX_SUPPLY = maxPresaleSupply_;
    }

    function mintReserved(uint16 amount) external onlyOwner {
        address sender = _msgSender();

        _mintGen0(sender, amount);
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
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
