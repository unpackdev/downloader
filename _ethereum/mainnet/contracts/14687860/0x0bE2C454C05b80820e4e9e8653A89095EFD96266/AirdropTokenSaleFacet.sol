// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155.sol";

import "./IERC20.sol";

import "./MerkleAirdropFacet.sol";

import "./Controllable.sol";

import "./IAirdrop.sol";

import "./IERC1155Mint.sol";

import "./IERC20Mint.sol";

import "./IERC721Mint.sol";

import "./ITokenSale.sol";

import "./InterfaceChecker.sol";

import "./IAirdropTokenSale.sol";

import "./MerkleAirdropFacet.sol";

interface IERC2981Setter {
    function setRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 amount
    ) external;
}

interface IMerkleAirdropAdder {
    function addAirdrop(IAirdrop.AirdropSettings memory _airdrop) external;
}

contract AirdropTokenSaleFacet is ITokenSale, Modifiers {
    /// @notice emitted when a token is opened
    event TokenSaleOpen(
        uint256 tokenSaleId,
        IAirdropTokenSale.TokenSaleSettings tokenSale
    );

    /// @notice emitted when a token is opened
    event TokenSaleClosed(
        uint256 tokenSaleId,
        IAirdropTokenSale.TokenSaleSettings tokenSale
    );

    /// @notice emitted when a token is opened
    event TokenPurchased(
        uint256 tokenSaleId,
        address indexed purchaser,
        uint256 tokenId,
        uint256 quantity
    );

    // token settings were updated
    event TokenSaleSettingsUpdated(
        uint256 tokenSaleId,
        IAirdropTokenSale.TokenSaleSettings tokenSale
    );

    event TokensaleCreated(
        uint256 indexed tokensaleId,
        IAirdropTokenSale.TokenSaleSettings settings
    );
    event AirdropRedeemed(
        uint256 indexed airdropId,
        address indexed beneficiary,
        bytes32[] proof,
        uint256 amount
    );

    using UInt256Set for UInt256Set.Set;

    /// @notice intialize the contract. should be called by overriding contract
    /// @param tokenSaleInit struct with tokensale data
    function createTokenSale(
        IAirdropTokenSale.TokenSaleSettings memory tokenSaleInit
    ) public virtual returns (uint256 tokenSaleId) {
        // sanity check input values
        require(
            tokenSaleInit.token != address(0),
            "Multitoken address must be set"
        );

        // set settings object
        tokenSaleId = uint256(
            keccak256(
                abi.encodePacked(
                    s.airdropTokenSaleStorage.tsnonce,
                    address(this)
                )
            )
        );
        s.airdropTokenSaleStorage._tokenSales[
            uint256(tokenSaleId)
        ] = tokenSaleInit;
        s
            .airdropTokenSaleStorage
            ._tokenSales[uint256(tokenSaleId)]
            .contractAddress = address(this);
        emit TokensaleCreated(tokenSaleId, tokenSaleInit);
    }

    /// @notice Called to purchase some quantity of a token. Assumes no airdrop / no whitelist
    /// @param receiver - the address of the account receiving the item
    /// @param _drop - the seed
    function _purchase(
        uint256 tokenSaleId,
        uint256 _drop,
        address receiver,
        uint256 quantity
    ) internal returns (uint256) {
        // if the payment type is erc20, then transfer the tokens from the sender to the contract
        if (
            s.merkleAirdropStorage._settings[_drop].paymentType ==
            IAirdropTokenSale.PaymentType.TOKEN &&
            s.merkleAirdropStorage._settings[_drop].tokenAddress != address(0)
        ) {
            address tokenAddress = s
                .merkleAirdropStorage
                ._settings[_drop]
                .tokenAddress;
            uint256 price = s
                .merkleAirdropStorage
                ._settings[_drop]
                .initialPrice
                .price * quantity;
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), price);
        }

        uint256 tokenHash;
        if (_drop != 0) {
            require(
                s.merkleAirdropStorage._settings[_drop].whitelistId == _drop,
                "Airdrop doesnt exist"
            );
            tokenHash = s.merkleAirdropStorage._settings[_drop].tokenHash;
        } else {
            tokenHash = s
                .airdropTokenSaleStorage
                ._tokenSales[tokenSaleId]
                .tokenHash;
        }

        // mint a token to the user
        tokenHash = this.airdropRedeemed(tokenSaleId, tokenHash, receiver, 1);

        // increase total bought
        s.airdropTokenSaleStorage.totalPurchased[_drop] += 1;
        s.airdropTokenSaleStorage.purchased[_drop][receiver] += 1;

        // emit a message about the purchase
        emit TokenPurchased(tokenSaleId, receiver, tokenHash, 1);
        return tokenHash;
    }

    function purchase(
        uint256 tokenSaleId,
        address receiver,
        uint256 quantity,
        uint256 total,
        uint256 drop,
        uint256 index,
        bytes32[] memory merkleProof
    ) external payable {
        address targetTokenn = s
            .airdropTokenSaleStorage
            ._tokenSales[tokenSaleId]
            .token;
        if (InterfaceChecker.isERC20(targetTokenn)) {
            _purchaseToken(
                tokenSaleId,
                receiver,
                quantity,
                total,
                drop,
                index,
                merkleProof,
                msg.value
            );
        } else {
            for(uint256 counter = 0; counter < quantity; counter++) {
                _purchaseToken(
                    tokenSaleId,
                    receiver,
                    1,
                    total,
                    drop,
                    index,
                    merkleProof,
                    msg.value / quantity
                );
            }
        }

    }

    /// @notice Called to purchase some quantity of a token
    /// @param receiver - the address of the account receiving the item
    /// @param quantity - the seed
    /// @param drop - the seed
    /// @param leaf - the seed
    /// @param merkleProof - the seed
    function _purchaseToken(
        uint256 tokenSaleId,
        address receiver,
        uint256 quantity,
        uint256 total,
        uint256 drop,
        uint256 leaf,
        bytes32[] memory merkleProof,
        uint256 valueAttached
    ) internal {
        // only check for a non-zero drop id
        if (drop != 0) {
            IAirdrop.AirdropSettings storage _drop = s
                .merkleAirdropStorage
                ._settings[drop];

            // check that the airdrop is valid
            require(_drop.whitelistId == drop, "Airdrop doesnt exist");

            // check that the airdrop has not yet been redeemed by the user
            require(
                !IMerkleAirdrop(address(this)).airdropRedeemed(drop, receiver),
                "Airdrop already redeemed"
            );

            // make sure there are still tokens to purchase
            require(
                _drop.maxQuantity == 0 ||
                    (_drop.maxQuantity != 0 &&
                        _drop.quantitySold + quantity <= _drop.maxQuantity),
                "The maximum amount of tokens has been bought."
            );

            // if the payment type is ETH (base token) ensure that enough price is attached
            if (_drop.paymentType == IAirdropTokenSale.PaymentType.ETH) {
                require(
                    _drop.initialPrice.price * quantity <= valueAttached,
                    "Not enough price attached"
                );
            }

            // make sure the max qty per sale is not exceeded
            require(
                _drop.minQuantityPerSale == 0 ||
                    (_drop.minQuantityPerSale != 0 &&
                        quantity >= _drop.minQuantityPerSale),
                "Minimum quantity per sale not met"
            );

            // make sure the max qty per sale is not exceeded
            require(
                _drop.maxQuantityPerSale == 0 ||
                    (_drop.maxQuantityPerSale != 0 &&
                        quantity <= _drop.maxQuantityPerSale),
                "Maximum quantity per sale exceeded"
            );

            // make sure the token sale has started
            require(
                block.timestamp >= _drop.startTime || _drop.startTime == 0,
                "The sale has not started yet"
            );

            // make sure token sale is not over
            require(
                block.timestamp <= _drop.endTime || _drop.endTime == 0,
                "The sale has ended"
            );

            // transfer the payment to the payee if the payee address is set
            if(_drop.payee != address(0)) {
                if (IAirdropTokenSale.PaymentType(_drop.paymentType) == IAirdropTokenSale.PaymentType.TOKEN) {
                    IERC20(_drop.tokenAddress).transferFrom(address(this), _drop.payee, valueAttached);
                } else {
                    payable(_drop.payee).transfer(valueAttached);
                } 
            }

            // only enforce the whitelist if explicitly set
            if (_drop.whitelistOnly) {
                // redeem the airdrop slot and then purchase an NFT
                IMerkleAirdropRedeemer(address(this)).redeemAirdrop(
                    drop,
                    leaf,
                    receiver,
                    quantity,
                    total,
                    merkleProof
                );
            }

            // purchase the token and then emit an event about it
            _purchase(tokenSaleId, drop, receiver, quantity);
            emit AirdropRedeemed(drop, receiver, merkleProof, quantity);
        } else {
            IAirdropTokenSale.TokenSaleSettings storage tokenSaleSettings = s
                .airdropTokenSaleStorage
                ._tokenSales[tokenSaleId];

            // if the token sale is ETH make sure enough ETH is attached
            if (
                tokenSaleSettings.paymentType ==
                IAirdropTokenSale.PaymentType.ETH
            ) {
                require(
                    tokenSaleSettings.initialPrice.price * quantity <=
                        valueAttached,
                    "Not enough payment attached"
                );
            }

            // make sure there are still tokens to purchase
            require(
                tokenSaleSettings.maxQuantity == 0 ||
                    (tokenSaleSettings.maxQuantity != 0 &&
                        s.airdropTokenSaleStorage.totalPurchased[0] <
                        tokenSaleSettings.maxQuantity),
                "The maximum amount of tokens has been bought."
            );

            // make sure the max qty per sale is not exceeded
            require(
                tokenSaleSettings.minQuantityPerSale == 0 ||
                    (tokenSaleSettings.minQuantityPerSale != 0 &&
                        quantity >= tokenSaleSettings.minQuantityPerSale),
                "Minimum quantity per sale not met"
            );

            // make sure the max qty per sale is not exceeded
            require(
                tokenSaleSettings.maxQuantityPerSale == 0 ||
                    (tokenSaleSettings.maxQuantityPerSale != 0 &&
                        quantity <= tokenSaleSettings.maxQuantityPerSale),
                "Maximum quantity per sale exceeded"
            );

            // make sure token sale is started
            require(
                block.timestamp >= tokenSaleSettings.startTime ||
                    tokenSaleSettings.startTime == 0,
                "The sale has not started yet"
            );

            // make sure token sale is not over
            require(
                block.timestamp <= tokenSaleSettings.endTime ||
                    tokenSaleSettings.endTime == 0,
                "The sale has ended"
            );

            // transfer the payment to the payee if the payee address is set
            if(tokenSaleSettings.payee != address(0)) {
                if (IAirdropTokenSale.PaymentType(tokenSaleSettings.paymentType) == IAirdropTokenSale.PaymentType.TOKEN) {
                    IERC20(tokenSaleSettings.tokenAddress).transferFrom(address(this), tokenSaleSettings.payee, valueAttached);
                } else {
                    payable(tokenSaleSettings.payee).transfer(valueAttached);
                } 
            }

            _purchase(tokenSaleId, drop, receiver, quantity);
        }
    }

    // @notice Called to redeem some quantity of a token - same as purchase
    /// @param drop - the address of the account receiving the item
    /// @param leaf - the seed
    /// @param recipient - the seed
    /// @param amount - the seed
    /// @param merkleProof - the seed
    function redeemToken(
        uint256 tokenSaleId,
        uint256 drop,
        uint256 leaf,
        address recipient,
        uint256 amount,
        uint256 total,
        bytes32[] memory merkleProof
    ) public payable {
        address targetTokenn = s
            .airdropTokenSaleStorage
            ._tokenSales[tokenSaleId]
            .token;
        if (InterfaceChecker.isERC20(targetTokenn)) {
            _purchaseToken(
                tokenSaleId,
                recipient,
                amount,
                total,
                drop,
                leaf,
                merkleProof,
                msg.value
            );
        } else {
            for(uint256 i = 0; i < amount; i++) {
                _purchaseToken(
                    tokenSaleId,
                    recipient,
                    1,
                    total,
                    drop,
                    leaf,
                    merkleProof,
                    msg.value / amount
                );
            }
        }

    }

    function airdropRedeemed(
        uint256 tokenSaleId,
        uint256 tHash,
        address recipient,
        uint256 amount
    ) external returns (uint256 tokenHash_) {
        // mint the token
        address targetTokenn = s
            .airdropTokenSaleStorage
            ._tokenSales[tokenSaleId]
            .token;
        if (InterfaceChecker.isERC20(targetTokenn)) {
            IERC20Mint(targetTokenn).mintTo(recipient, amount);
        } else if (InterfaceChecker.isERC721(targetTokenn)) {
            tokenHash_ = IERC721Mint(address(this)).mintTo(
                recipient,
                tHash
            );
        } else if (InterfaceChecker.isERC1155(targetTokenn)) {
            tokenHash_ = IERC1155Mint(address(this)).mintTo(
                recipient,
                tHash,
                amount,
                ""
            );
        } else {
            require(false, "Token not supported");
        }
    }

    /// @notice Get the token sale settings
    function getTokenSaleSettings(uint256 tokenSaleId)
        external
        view
        virtual
        returns (IAirdropTokenSale.TokenSaleSettings memory settings)
    {
        settings = IAirdropTokenSale.TokenSaleSettings(
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].contractAddress,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].token,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].tokenHash,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].collectionHash,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].owner,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].payee,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].symbol,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].name,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].description,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].openState,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].startTime,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].endTime,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].maxQuantity,
            s
                .airdropTokenSaleStorage
                ._tokenSales[tokenSaleId]
                .maxQuantityPerSale,
            s
                .airdropTokenSaleStorage
                ._tokenSales[tokenSaleId]
                .minQuantityPerSale,
            s
                .airdropTokenSaleStorage
                ._tokenSales[tokenSaleId]
                .maxQuantityPerAccount,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].initialPrice,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].paymentType,
            s.airdropTokenSaleStorage._tokenSales[tokenSaleId].tokenAddress
        );
    }

    /// @notice Updates the token sale settings
    /// @param settings - the token sake settings
    function updateTokenSaleSettings(
        uint256 tokenSaleId,
        IAirdropTokenSale.TokenSaleSettings memory settings
    ) external onlyOwner {
        require(
            msg.sender ==
                s.airdropTokenSaleStorage._tokenSales[tokenSaleId].owner,
            "Only the owner can update the token sale settings"
        );
        s.airdropTokenSaleStorage._tokenSales[tokenSaleId] = settings;
        emit TokenSaleSettingsUpdated(tokenSaleId, settings);
    }

    /// @notice add a new airdrop
    /// @param _airdrop the id of the airdrop
    function newAirdrop(IAirdrop.AirdropSettings memory _airdrop)
        external
        onlyOwner
    {
        IMerkleAirdropAdder(address(this)).addAirdrop(_airdrop);
    }
}
