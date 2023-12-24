// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155LazyMint.sol";
import "./SignatureMintERC1155.sol";
import "./CurrencyTransferLib.sol";
import "./PrimarySale.sol";
import "./PlatformFee.sol";

contract AltNFT is ERC1155LazyMint, SignatureMintERC1155, PrimarySale, PlatformFee  {
    // Mapping from tokenId to wallet address to maximum claimable count
    mapping(uint256 => uint256) public maxClaimableCount;

    // Mapping from tokenId to minter address
    mapping(uint256 => address) public tokenIdToMinter;

    // Mapping from minter address to array of tokenIds minted
    mapping(address => uint256[]) public minterToTokenIds;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) SignatureMintERC1155() {}

    function setMaxClaimableCount(uint256 tokenId, uint256 count) public {
        require(msg.sender == owner() || msg.sender == tokenIdToMinter[tokenId], "Not authorized");
        maxClaimableCount[tokenId] = count;
    }

    function setTokenMinter(uint256 tokenId, address minter) internal {
        tokenIdToMinter[tokenId] = minter;
    }

    function getTokenIdsByMinter(address minter) public view returns (uint256[] memory) {
        return minterToTokenIds[minter];
    }

    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public virtual override returns (uint256 batchId) {
        batchId = super.lazyMint(_amount, _baseURIForTokens, _data);
        uint256 startId = nextTokenIdToLazyMint - _amount;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = startId + i;
            setTokenMinter(tokenId, msg.sender);
            minterToTokenIds[msg.sender].push(tokenId);
            setMaxClaimableCount(tokenId, 1);
        }
        return batchId;
    }

    function _canLazyMint() internal view virtual override returns (bool) {
        return true;
    }

    function verifyClaim(
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity
    ) public view virtual override {
        super.verifyClaim(_claimer, _tokenId, _quantity);
        require(balanceOf[_claimer][_tokenId] + _quantity <= maxClaimableCount[_tokenId], "Claim exceeds max allowed");
    }

    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable virtual override returns (address signer) {
        require(_req.quantity > 0, "Minting zero tokens.");

        uint256 tokenIdToMint;
        uint256 nextIdToMint = nextTokenIdToMint();

        if (_req.tokenId == type(uint256).max) {
            tokenIdToMint = nextIdToMint;
        } else {
            require(_req.tokenId < nextIdToMint, "invalid id");
            tokenIdToMint = _req.tokenId;
        }

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        // Collect price
        _collectPriceOnClaim(
            _req.primarySaleRecipient,
            _req.quantity,
            _req.currency,
            _req.pricePerToken
        );

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0)) {
            _setupRoyaltyInfoForToken(
                tokenIdToMint,
                _req.royaltyRecipient,
                _req.royaltyBps
            );
        }

        // Set URI
        if (_req.tokenId == type(uint256).max) {
            _setTokenURI(tokenIdToMint, _req.uri);
        }
        
        verifyClaim(receiver, tokenIdToMint, _req.quantity);

        // Mint tokens.
        _mint(receiver, tokenIdToMint, _req.quantity, "");

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = (_quantityToClaim * _pricePerToken) / 1 ether;
        require(totalPrice > 0, "quantity too low");

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "Must send total price.");
        }

        address saleRecipient = _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(
            _currency,
            msg.sender,
            saleRecipient,
            totalPrice
        );
    }

    function _canSignMintRequest(address _signer)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _signer == owner();
    }

    function _canSetPrimarySaleRecipient()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }

    function _canSetPlatformFeeInfo() 
        internal 
        view 
        virtual 
        override returns (bool) 
    {
        return msg.sender == owner();
    }
}
