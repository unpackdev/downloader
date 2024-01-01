// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721SignatureMint.sol";
import "./TWStrings.sol";
import "./CurrencyTransferLib.sol";
import "./EIP712.sol";
import "./LazyMint.sol";
import "./ERCCooldown.sol";

/// @author Book.io (with the help of thirdweb's base contract)
/// @title RandomSignatureMint
/// @notice Implement a randomized version of signature minting
abstract contract RandomSignatureMint is ERC721SignatureMint, LazyMint, ERCCooldown {
    using TWStrings for uint256;
    using ECDSA for bytes32;

    // The list of tokens that have yet to be minted
    uint256[] public remainingMintableTokens;

    // Store the random seed that was used by the last minter
    uint256 lastMintSeed = 0;

    // Whether or not this contract utilizes randomized minting
    bool public isRandomized = true;
    bool public isCool = false;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    /// this is separate from the non-randomized version (the parent member is private)
    mapping(bytes32 => bool) private minted;

    bytes32 private constant RANDOM_TYPEHASH =
        keccak256(
            "RandomMintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid,uint256 seed)"
        );

    struct RandomMintRequest {
        address to;
        address royaltyRecipient;
        uint256 royaltyBps;
        address primarySaleRecipient;
        uint256 quantity;
        uint256 pricePerToken;
        address currency;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
        uint256 seed;
    }

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721SignatureMint(
            _defaultAdmin,
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
        ERCCooldown(_royaltyBps,0,0)
    {
        // Generate a reasonable starting seed
        lastMintSeed = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Base, ERCCooldown) returns (bool) {
        return ERC721Base.supportsInterface(interfaceId) || ERCCooldown.supportsInterface(interfaceId);
    }

    function _canChangeRandomizedMinting() internal view virtual returns (bool);
    function _canChangeCoolMint() internal view virtual returns (bool);
    function _canSignAnyRequest(address _signer) internal view virtual returns (bool);

    function setRandomizedMinting(bool _isRandomized) external {
        require(_canChangeRandomizedMinting(), "Not authorized to change randomized minting");
        require(remainingMintableTokens.length == 0, "Cannot change randomized minting after available tokens have been set");
        require(_currentIndex == 0, "Cannot change randomized minting after tokens have been minted");
        isRandomized = _isRandomized;
    }

    function enableCoolMint(uint16 royaltyBps) external {
        require(_canChangeCoolMint(), "Not authorized to change Cooldown minting");
        require(_currentIndex == 0, "Cannot change cool mint after tokens have been minted");
        isCool = true;

        _setupDefaultRoyaltyInfo(address(this), royaltyBps);
    }

    function disableCoolMint(address royaltyRecipient, uint16 royaltyBps) external {
        require(_canChangeCoolMint(), "Not authorized to change Cooldown minting");
        require(_currentIndex == 0, "Cannot change cool mint after tokens have been minted");
        isCool = false;

        _setupDefaultRoyaltyInfo(royaltyRecipient, royaltyBps);
    }

    function setCooldownParams(uint16 _royalty, uint16 _transferCoolRate, uint16 _mintCoolRate) external {
        require(_canChangeCoolMint(), "Not authorized to change Cooldown minting");
        require(_currentIndex == 0, "Cannot change cooldown params after tokens have been minted");
        _adjustCoolRates(_royalty,_transferCoolRate,_mintCoolRate);
    }

    /// @dev Prevent verification of normal mint requests if randomized minting is enabled
    function _canSignMintRequest(address _signer) internal view virtual override returns (bool) {
        return !isRandomized && _canSignAnyRequest(_signer);
    }

    /// @dev Prevent verification of random mint requests if randomized minting is disabled
    function _canSignRandomizedMintRequest(address _signer) internal view virtual returns (bool) {
        return isRandomized && _canSignAnyRequest(_signer);
    }

    /// @dev Override token URI getter to return the base URI for randomized mints where the token ID is not known
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (isRandomized && _currentIndex <= _tokenId) {
            return _getBaseURI(_tokenId);
        }
        return super.tokenURI(_tokenId);
    }

    /// @dev If payment gets sent to this contract and cool is enabled, we send the appropriate amount.
    receive() payable external {
        if (isCool) {
            _transferCooldown(msg.value);
        }
    }

    /// @dev If payment gets sent to this contract for some reason and there is a balance, allow the owner to
    /// withdraw it.
    function withdraw() public onlyOwner {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send ETH");
    }

    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        virtual
        override
        returns (address signer)
    {
        // we have to override this function so that we can use _currentIndex here
        // rather than nextTokenIdToMint(). This is because nextTokenIdToMint() contains
        // the next token id for a lazy mint, which is not what we want (ie: if we upload 100
        // NFTS, nextTokenIdToMint() will be 100 while _currentIndex will be 0).
        uint256 tokenIdToMint = _currentIndex;
        if (tokenIdToMint + _req.quantity > nextTokenIdToLazyMint) {
            revert("No tokens left to mint");
        }

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        if (isCool) {
            uint256 totalPrice = _req.quantity * _req.pricePerToken;
            uint256 amountToCollect = totalPrice - _mintCooldownShare(totalPrice);
            _collectAmountOnClaim(_req.primarySaleRecipient, amountToCollect, totalPrice, _req.currency);
            _mintCooldown(msg.value);
        } else {
            // Collect price
            _collectPriceOnClaim(_req.primarySaleRecipient, _req.quantity, _req.currency, _req.pricePerToken);
        }

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0) && _req.royaltyBps != 0) {
            _setupRoyaltyInfoForToken(tokenIdToMint, _req.royaltyRecipient, _req.royaltyBps);
        }

        // Mint tokens.
        _safeMint(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    /// @dev Provide a randomized signature minting implementation
    function randMintWithSignature(RandomMintRequest calldata _req, bytes calldata _signature)
        external
        payable
        virtual
        returns (address signer)
    {
        require(isRandomized == true, "Randomized minting is disabled");

        // Verify and process payload.
        signer = _processRequestRandom(_req, _signature);

        // We can't modify the tokenId (internal to the contract) that is actually minted,
        // but we _can_ modify the URIs that are stored for each tokenId. So, we'll
        // generate the tokens as usual, but then modify the URIs in series.
        uint256 tokenIdToMint = _currentIndex;
        if (tokenIdToMint + _req.quantity > nextTokenIdToLazyMint) {
            revert("No tokens left to mint");
        }

        address receiver = _req.to;

        if (isCool) {
            uint256 totalPrice = _req.quantity * _req.pricePerToken;
            uint256 amountToCollect = totalPrice - _mintCooldownShare(totalPrice);
            _collectAmountOnClaim(_req.primarySaleRecipient, amountToCollect, totalPrice, _req.currency);
            _mintCooldown(msg.value);
        } else {
            // Collect price
            _collectPriceOnClaim(_req.primarySaleRecipient, _req.quantity, _req.currency, _req.pricePerToken);
        }

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0) && _req.royaltyBps != 0) {
            _setupRoyaltyInfoForToken(tokenIdToMint, _req.royaltyRecipient, _req.royaltyBps);
        }

        // Mint tokens.
        _safeMint(receiver, _req.quantity);

        // Update the token URIs
        for (uint256 i = 0; i < _req.quantity; i++) {
            uint256 id = takeNextRandomId(i, _req.to, _req.seed);
            string memory batchUri = _getBaseURI(id);
            _setTokenURI(tokenIdToMint + i, string(abi.encodePacked(batchUri, id.toString())));
        }

        // Get the first URI
        string memory uri = tokenURI(tokenIdToMint);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, MintRequest({
            to: _req.to,
            royaltyRecipient: _req.royaltyRecipient,
            royaltyBps: _req.royaltyBps,
            primarySaleRecipient: _req.primarySaleRecipient,
            quantity: _req.quantity,
            pricePerToken: _req.pricePerToken,
            currency: _req.currency,
            validityStartTimestamp: _req.validityStartTimestamp,
            validityEndTimestamp: _req.validityEndTimestamp,
            uri: uri,
            uid: _req.uid
        }));
    }

    function takeNextRandomId(
        uint256 offset,
        address _mintingAddress,
        uint256 _minterSeed
    ) internal returns (uint256) {
        (uint256 id, uint256 index) = generateRandomId(_mintingAddress, _minterSeed + offset);
        // Remove the id from the list of remaining mintable tokens
        require(index < remainingMintableTokens.length, "Index out of bounds");
        remainingMintableTokens[index] = remainingMintableTokens[remainingMintableTokens.length - 1];
        remainingMintableTokens.pop();
        return id;
    }

    /// @dev Generate a random ID for someone to mint
    function generateRandomId(
        address _mintingAddress,
        uint256 _minterSeed
    ) internal view returns (uint256, uint256) {
        if (remainingMintableTokens.length == 0) {
            revert("No tokens left to mint");
        }
        // Generate a random number based on several factors:
        // - The last seed used. Helps prevent predicting what the next id will be
        // - The current block number - an simple way of providing some entropy
        // - The current block difficulty - another simple way of providing some entropy
        // - The minters seed - We generated this, so we know it's random, and this
        //   gives makes it so the "hot" ids are different for each minter
        // - The minters address - This helps prevent US from controlling what numbers
        //   are generated for other people. This alleviates the concern that we could
        //   maniuplate or predict the IDs given
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    lastMintSeed,
                    block.number,
                    block.prevrandao,
                    _minterSeed,
                    _mintingAddress
                )
            )
        );
        uint256 index = random % remainingMintableTokens.length;
        return (remainingMintableTokens[index], index);
    }

    function _processRequestRandom(
        RandomMintRequest calldata _req,
        bytes calldata _signature
    ) internal returns (address signer) {
        bool success;
        (success, signer) = verifyRandom(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }
        require(_req.to != address(0), "recipient undefined");
        require(_req.quantity > 0, "0 qty");

        minted[_req.uid] = true;
    }

    /// @dev Verifies that a mint request is signed by an authorized account.
    function verifyRandom(RandomMintRequest calldata _req, bytes calldata _signature)
        public
        view
        returns (bool success, address signer)
    {
        signer = _recoverRandomAddress(_req, _signature);
        success = !minted[_req.uid] && _canSignRandomizedMintRequest(signer);
    }

    /// @dev Verifies a mint request and marks the request as minted.
    function _processRandomRequest(
        RandomMintRequest calldata _req, bytes calldata _signature
    ) internal returns (address signer) {
        bool success;
        (success, signer) = verifyRandom(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }
        require(_req.to != address(0), "recipient undefined");
        require(_req.quantity > 0, "0 qty");

        minted[_req.uid] = true;
    }

    /// @dev Returns the address of the signer of the mint request.
    function _recoverRandomAddress(
        RandomMintRequest calldata _req, bytes calldata _signature
    ) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRandomRequest(_req))).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRandomRequest(
        RandomMintRequest calldata _req
    ) internal pure returns (bytes memory) {
        return
            abi.encode(
                RANDOM_TYPEHASH,
                _req.to,
                _req.royaltyRecipient,
                _req.royaltyBps,
                _req.primarySaleRecipient,
                _req.quantity,
                _req.pricePerToken,
                _req.currency,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid,
                _req.seed
            );
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() public view override returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @dev Can be used in special cases when we collect less than the total price.
    function _collectAmountOnClaim(
        address _primarySaleRecipient,
        uint256 _amountToCollect,
        uint256 _totalPrice,
        address _currency
    ) internal virtual {
        if (_totalPrice == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == _totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, saleRecipient, _amountToCollect);
    }
}
