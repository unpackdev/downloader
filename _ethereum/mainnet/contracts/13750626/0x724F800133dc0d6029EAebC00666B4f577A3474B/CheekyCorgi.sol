//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Strings.sol";

import "./CheekyCorgiBase.sol";

contract CheekyCorgi is CheekyCorgiBase
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    function initialize(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        address admin,
        address payable treasury,
        address owner,
        address _adminImplementation
    ) external initializer {
        __ERC721_init(name, symbol);
        __Context_init();
        __AccessControlEnumerable_init();
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ERC721Pausable_init();
        __Ownable_init();

        maxSupply = 8999;
        maxPrivateQuantity = 8;
        privatePrice = 0.02 ether;
        publicPrice = 0.04 ether;
        NAME_CHANGE_PRICE = 100000 ether; // 100,000 $SPLOOT Tokens
        BIO_CHANGE_PRICE = 100000 ether; // 100,000 $SPLOOT Tokens

        baseTokenURI = _baseTokenURI;
        ADMIN = admin;
        TREASURY = treasury;
        transferOwnership(owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(DEFAULT_ADMIN_ROLE, ADMIN);
        _setupRole(TREASURY_ROLE, TREASURY);

        adminImplementation = _adminImplementation;
        /**
        ====================================================================================
        [DANGER] please do not change the order of payment methods, as  USDT, USDC, SHIBA
        ====================================================================================
        */
        PAYMENT_METHODS[0].token = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        PAYMENT_METHODS[0].decimals = 6;
        PAYMENT_METHODS[0].publicPrice = 180 * (10**6);

        PAYMENT_METHODS[1].token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        PAYMENT_METHODS[1].decimals = 6;
        PAYMENT_METHODS[1].publicPrice = 180 * (10**6);

        PAYMENT_METHODS[2].token = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE; // SHIBA INU
        PAYMENT_METHODS[2].decimals = 18;
        PAYMENT_METHODS[2].publicPrice = 5000000 * (10**18);

        PAYMENT_METHODS[3].decimals = 18; // $SPLOOT
        PAYMENT_METHODS[3].publicPrice = 0; // [DANGER] keep it as zero until allow minting by SPLOOT

        Claimables[0].token = 0x91673149FFae3274b32997288395D07A8213e41F; // JunkYard
        Claimables[1].token = 0x4F1B1306E8bd70389d3C413888a61BB41171a0Bc; // ApprovingCorgis
        totalClaimed = 0;
        maxClaimable = 300;
    }

    function claim(address _claimableToken, uint256 _tokenId) external whenNotPaused {
        require(
            block.timestamp >= PUBLIC_SALE_OPEN,
            "claim: Claim not open"
        );
        require(
            totalSupply() < maxSupply,
            "claim: Quantity must be lesser than maxSupply"
        );
        require(
            totalClaimed < maxClaimable,
            "claim: Exceeded over total claimable"
        );
        require(
            !claimedAddresses[msg.sender],
            "claim: Already claimed for the address"
        );

        // 1st: check holdings of UCD ERC20 token
        if (_claimableToken == UCD && claimableUcdHolders[msg.sender]) {
            claimedAddresses[msg.sender] = true;
            totalClaimed ++;
            _mintOne(msg.sender);
            YIELD_TOKEN.updateRewardOnMint(msg.sender, 1);
            return;
        } else if (_claimableToken == UCD) {
            require(false, "Not UCD holder");
        }

        // 2nd: check friendship NFT holdings
        for (uint256 i = 0; i < 2; i++) {
            if (Claimables[i].token != _claimableToken) {
                continue;
            }

            IERC721Enumerable _contract = IERC721Enumerable(Claimables[i].token);
            require(_contract.ownerOf(_tokenId) == msg.sender, "claim: Invalid token");
            require(!Claimables[i].claimed[_tokenId], "claim: Already claimed for the token");

            Claimables[i].claimed[_tokenId] = true;
            claimedAddresses[msg.sender] = true;
            
            totalClaimed ++;
            _mintOne(msg.sender);
            
            YIELD_TOKEN.updateRewardOnMint(msg.sender, 1);
            return;
        }

        // _claimableToken or _tokenId is wrong, and not able to claim with that
        require(false, "Invalid NFT");
    }

    /**
    ====================================================================================
    [DANGER] please do not confuse the _paymentMethodId, and input correctly like below:
    ====================================================================================
    _paymentMethodId:
        0: ETH
        1: USDT
        2: USDC
        3: SHIBA
        4: SPLOOT  [WARNING] SPLOOT will be burnt, not be transferred to treasure.
     */
    function mint(uint256 _quantity, uint256 _paymentMethodId) external payable whenNotPaused {
        require(
            _paymentMethodId < 5,
            "Unsupported token"
        );
        require(
            totalSupply().add(_quantity) <= maxSupply,
            "mint: Quantity must be lesser than maxSupply"
        );
        require(
            _quantity > 0,
            "mint: Quantity must be greater then zero"
        );
        require(
            block.timestamp >= PUBLIC_SALE_OPEN,
            "mint: Public Sale not open"
        );
        if (_paymentMethodId == 0) {
            require(
                msg.value == _quantity * publicPrice,
                "mint: ETH Value incorrect (quantity * publicPrice)"
            );
        } else {
            uint256 _totalPrice = _quantity.mul(PAYMENT_METHODS[_paymentMethodId-1].publicPrice);
            IERC20 _token = IERC20(PAYMENT_METHODS[_paymentMethodId-1].token);
            require(
                _token.balanceOf(msg.sender) >= _totalPrice,
                "mint: Token balance is small"
            );
            require(
                _token.allowance(msg.sender, address(this)) >= _totalPrice,
                "mint: Token is not approved"
            );

            if (_paymentMethodId == 4) {
                require(_totalPrice > 0, "Minting by $SPLOOT not allowed");
                YIELD_TOKEN.burn(msg.sender, _totalPrice);
            } else {
                _token.transferFrom(msg.sender, address(this), _totalPrice);
            }
        }

        for (uint256 i = 0; i < _quantity; i++) {
            _mintOne(msg.sender);
        }
        YIELD_TOKEN.updateRewardOnMint(msg.sender, _quantity);
    }

    // only accepts ETH for private sale
    function privateMint(uint256 _quantity) external payable whenNotPaused {
        require(
            block.timestamp >= PRIVATE_SALE_OPEN,
            "privateMint: Private Sale not open"
        );
        require(
            _privateSaleWhitelist[msg.sender] == true,
            "privateMint: Not Whitelisted for private sale"
        );
        require(
            msg.value == _quantity * privatePrice,
            "privateMint: ETH Value incorrect (quantity * privatePrice)"
        );
        require(
            _quantity > 0,
            "privateMint: Quantity must be greater then zero and lesser than maxPrivateQuantity"
        );
        require(
            _privateQuantity[msg.sender].add(_quantity) <= maxPrivateQuantity,
            "privateMint: Each user should have at most maxPrivateQuantity tokens for private sale"
        );
        require(
            totalSupply().add(_quantity) <= maxSupply,
            "privateMint: Quantity must be lesser than maxSupply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _privateQuantity[msg.sender] += 1;
            _mintOne(msg.sender);
        }
        YIELD_TOKEN.updateRewardOnMint(msg.sender, _quantity);
    }

    function _mintOne(address _owner) internal {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);
        emit Minted(_owner, newItemId);
    }

    // ------------------------- USER FUNCTION ---------------------------
    function getReward() external {
        YIELD_TOKEN.updateReward(msg.sender, address(0));
        YIELD_TOKEN.getReward(msg.sender);
    }

    /// @dev Allow user to change the unicorn bio
    function changeBio(uint256 _tokenId, string memory _bio) public virtual {
        address owner = ownerOf(_tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        YIELD_TOKEN.burn(msg.sender, BIO_CHANGE_PRICE);

        bio[_tokenId] = _bio;
        emit BioChange(_tokenId, _bio);
    }

    /// @dev Allow user to change the unicorn name
    function changeName(uint256 tokenId, string memory newName) public virtual {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(newName) == false, "Name already reserved");

        YIELD_TOKEN.burn(msg.sender, NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        YIELD_TOKEN.updateReward(from, to);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        YIELD_TOKEN.updateReward(from, to);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Get Token URI Concatenated with Base URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    // ----------------------- CALCULATION FUNCTIONS -----------------------
    /// @dev Convert String to lower
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /// @dev Check if name is reserved
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    function isClaimedAlready(uint256 _claimableId, uint256 _tokenId) external view returns (bool) {
        require(_claimableId < 2);
        return Claimables[_claimableId].claimed[_tokenId];
    }

    function isWhitelisted(address _from) public view returns (bool) {
        return _privateSaleWhitelist[_from];
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function tokenNameByIndex(uint256 index)
        public
        view
        returns (string memory)
    {
        return _tokenName[index];
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function getClaimables() external view returns (address[3] memory) {
        address[3] memory _addresses;
        _addresses[0] = Claimables[0].token;
        _addresses[1] = Claimables[1].token;
        _addresses[2] = UCD;

        return _addresses;
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------
    function reserve(uint256 _count) external {
        _count;
        delegateToAdmin();
    }

    function setYieldToken(address _YieldToken) external {
        _YieldToken;
        delegateToAdmin();
    }

    function setProvenanceHash(string memory provenanceHash) external {
        provenanceHash;
        delegateToAdmin();
    }

    function updateBaseURI(string memory newURI) external {
        newURI;
        delegateToAdmin();
    }

    function updateMaxSupply(uint256 _maxSupply) external {
        _maxSupply;
        delegateToAdmin();
    }

    function updateQuantity(uint256 _maxPrivateQuantity, uint256 _maxPublicQuantity) external {
        _maxPrivateQuantity;
        _maxPublicQuantity;
        delegateToAdmin();
    }

    function updatePrice(uint256 _privatePrice, uint256 _publicPrice) external {
        _privatePrice;
        _publicPrice;
        delegateToAdmin();
    }

    function updatePriceOfToken(uint256 _tokenIndex, uint256 _publicPrice) external {
        _tokenIndex;
        _publicPrice;
        delegateToAdmin();
    }


    function pause() external virtual {
        delegateToAdmin();
    }

    function unpause() external virtual {
        delegateToAdmin();
    }

    function updateWhitelist(address[] calldata whitelist) external {
        whitelist;
        delegateToAdmin();
    }

    function updateUcdHolders(address[] calldata _holders) external {
        _holders;
        delegateToAdmin();
    }

    function withdrawToTreasury() external onlyTreasury {
        delegateToAdmin();
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------
    function _toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function delegateToAdmin() internal {
        (bool success,) = adminImplementation.delegatecall(msg.data);
        require(success);
    }
}
