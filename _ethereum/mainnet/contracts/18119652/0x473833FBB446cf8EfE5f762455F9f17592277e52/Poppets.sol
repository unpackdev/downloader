// SPDX-License-Identifier: UNLICENSED

//
// The NFTs managed by this smart contract are subject to the license found at IPFS CID
// bafkreih646uk4xlbk3vnogrwtb4mpwwmqd5ubhnwtgemp4rc5hy5xvs5cq
// https://ipfs.io/ipfs/bafkreih646uk4xlbk3vnogrwtb4mpwwmqd5ubhnwtgemp4rc5hy5xvs5cq
//

pragma solidity 0.8.20;

import "./PoppetBase.sol";

contract Poppets is PoppetBase {
    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        address curios_,
        string memory uri_
    ) PoppetBase(name_, symbol_, signer_, uri_) {
        _setDefaultRoyalty(msg.sender, 500);
        _setCuriosAddress(curios_);
    }

    function airdrop(
        address to_,
        uint256 quantity
    ) external payable onlyOwner activeThreadOnly quantityAvailable(quantity) {
        _mint(to_, quantity);
    }

    /**
     * @dev Airdrops Poppets tokens to a list of recipients.
     * @param recipients An array of addresses to receive the tokens.
     * @param quantities An array of token amounts to be sent to each recipient.
     * @notice The length of `recipients` and `quantities` arrays must be equal.
     * @notice Only the contract owner can call this function.
     */
    function poppetsplosion(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) public payable onlyOwner activeThreadOnly {
        if (recipients.length != quantities.length) {
            revert MismatchedParameters();
        }

        for (uint i = 0; i < recipients.length; i++) {
            _mint(recipients[i], quantities[i]);
        }

        /* Not ideal to have this after mints happen, but it saves gas  to not check every time through the loop */
        if (_nextTokenId() > _getConfig().maxTokenId) {
            revert ExceedsMaxSupply();
        }
    }

    /**
     * @dev Mints a specified quantity of Poppet tokens to the caller of the function.
     *      The caller must send enough ether to cover the cost of the tokens.
     *      The price of the tokens is determined by the publicMintPrice value in the contract's configuration.
     *      If the publicMintPrice is set to 0, the function will revert with a PublicMintUnavailable error.
     *      If the caller sends insufficient funds, the function will revert with an InsufficientFunds error.
     * @param quantity The number of tokens to mint.
     */
    function mintPublic(
        uint256 quantity
    ) public payable quantityAvailable(quantity) activeThreadOnly {
        ThreadConfig storage config = _getConfig();
        if (config.publicMintPrice == 0) {
            revert PublicMintUnavailable();
        }
        if (msg.value < quantity * config.publicMintPrice) {
            revert InsufficientFunds();
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Mints a specified quantity of Poppet tokens to the caller of the function, provided that the caller's signature is valid.
     *      The caller must send enough ether to cover the cost of the tokens.
     *      The price of the tokens is determined by the signedMintPrice value in the contract's configuration.
     *      If the signedMintPrice is set to 0, the function will revert with a SignedMintUnavailable error.
     *      If the caller sends insufficient funds, the function will revert with an InsufficientFunds error.
     *      If the signature is invalid, the function will revert with an InvalidSignature error.
     * @param quantity The number of tokens to mint.
     * @param nonce The nonce used to sign the message.
     * @param signature The signature used to sign the message.
     */
    function mintSigned(
        uint256 quantity,
        uint256 nonce,
        bytes calldata signature
    ) public payable quantityAvailable(quantity) activeThreadOnly {
        ThreadConfig storage config = _getConfig();
        if (config.signedMintPrice == 0) {
            revert SignedMintUnavailable();
        }
        if (msg.value < quantity * config.signedMintPrice) {
            revert InsufficientFunds();
        }

        verifyMintKey(signature, msg.sender, config.currentThreadId, nonce);

        _mint(msg.sender, quantity);
    }

    function reveal(
        uint256 tokenId,
        uint256[] calldata poppet_accessories,
        uint256[] calldata bonus_accessories,
        uint256 free_poppets,
        uint256 nonce,
        bytes calldata signature
    ) public payable quantityAvailable(free_poppets) onlyPoppetOwner(tokenId) {
        if (REVEAL_PRICE > msg.value) {
            revert InsufficientFunds();
        }
        verifyRevealKey(
            signature,
            _msgSender(),
            tokenId,
            poppet_accessories,
            bonus_accessories,
            free_poppets,
            nonce
        );

        if (free_poppets > 0) {
            _mint(msg.sender, free_poppets);
        }

        if (poppet_accessories.length > 0) {
            ICurios(CURIOS).mintFromPack(
                _getTokenAccount(tokenId),
                poppet_accessories
            );
        }

        if (bonus_accessories.length > 0) {
            ICurios(CURIOS).mintFromPack(_msgSender(), bonus_accessories);
        }

        _reveal(_asSingletonArray(tokenId));
    }

    function forceReveal(
        uint256[] calldata tokenIds,
        RevealKey[] calldata revealKeys
    ) public payable onlyOwner {
        if (tokenIds.length != revealKeys.length) {
            revert MismatchedParameters();
        }
        for (uint i = 0; i < revealKeys.length; i++) {
            if (revealKeys[i].free_poppets > 0) {
                _mint(revealKeys[i].wallet, revealKeys[i].free_poppets);
            }

            if (revealKeys[i].poppet_accessories.length > 0) {
                ICurios(CURIOS).mintFromPack(
                    _getTokenAccount(revealKeys[i].tokenId),
                    revealKeys[i].poppet_accessories
                );
            }

            if (revealKeys[i].bonus_accessories.length > 0) {
                ICurios(CURIOS).mintFromPack(
                    revealKeys[i].wallet,
                    revealKeys[i].bonus_accessories
                );
            }
        }
        _reveal(tokenIds);
    }

    function revealMany(
        RevealKey[] calldata revealKeys,
        bytes[] calldata signatures
    ) public payable {
        if (REVEAL_PRICE * revealKeys.length > msg.value) {
            revert InsufficientFunds();
        }

        for (uint i = 0; i < revealKeys.length; i++) {
            reveal(
                revealKeys[i].tokenId,
                revealKeys[i].poppet_accessories,
                revealKeys[i].bonus_accessories,
                revealKeys[i].free_poppets,
                revealKeys[i].nonce,
                signatures[i]
            );
        }
    }

    function swapCurios(
        SwapKey calldata swapKey,
        Amounts calldata amounts,
        bytes calldata signature
    ) public payable onlyPoppetOwnerIfUnlocked(swapKey.tokenId) {
        if (SWAP_PRICE > msg.value) {
            revert InsufficientFunds();
        }

        verifySwapKey(signature, swapKey, _msgSender());
        _swapCurios(
            _msgSender(),
            _getTokenAccount(swapKey.tokenId),
            swapKey.remove,
            amounts.removeAmounts,
            swapKey.add,
            amounts.addAmounts
        );

        _swapCommunityCurios(
            _msgSender(),
            _getTokenAccount(swapKey.tokenId),
            swapKey.removeC,
            amounts.removeCAmounts,
            swapKey.addC,
            amounts.addCAmounts
        );

        _initializeOwnershipAt(swapKey.tokenId);
        _setExtraDataAt(swapKey.tokenId, uint24(block.number));

        emit PoppetTraitsUpdated(
            swapKey.tokenId,
            swapKey.remove,
            swapKey.add,
            swapKey.removeC,
            swapKey.addC
        );
    }

    function swapWithPermission(
        SwapPermissionKey calldata swapKeyA,
        SwapPermissionKey calldata swapKeyB,
        SwapPermissionMasterKey calldata swapPermissionMasterKey,
        Amounts calldata amounts,
        bytes calldata masterSignature
    )
        public
        payable
        unlockedOrOwner(swapKeyA.fromPoppet)
        unlockedOrOwner(swapKeyB.fromPoppet)
    {
        if (SWAP_PRICE * 2 > msg.value) {
            revert InsufficientFunds();
        }

        if (swapKeyA.fromPoppet != swapKeyB.toPoppet) {
            revert MismatchedParameters();
        }
        if (swapKeyB.fromPoppet != swapKeyA.toPoppet) {
            revert MismatchedParameters();
        }

        if (_msgSender() != ownerOf(swapKeyA.fromPoppet)) {
            if (_msgSender() != ownerOf(swapKeyB.fromPoppet)) {
                revert InsufficientPermissions();
            }
        }

        if (
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(swapKeyA.add),
                    abi.encodePacked(swapKeyA.remove),
                    abi.encodePacked(swapKeyA.addC),
                    abi.encodePacked(swapKeyA.removeC)
                )
            ) !=
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(swapKeyB.remove),
                    abi.encodePacked(swapKeyB.add),
                    abi.encodePacked(swapKeyB.removeC),
                    abi.encodePacked(swapKeyB.addC)
                )
            )
        ) {
            revert MismatchedParameters();
        }

        verifySwapPermissionKey(
            swapPermissionMasterKey.signatureA,
            swapKeyA,
            ownerOf(swapKeyA.fromPoppet)
        );
        verifySwapPermissionKey(
            swapPermissionMasterKey.signatureB,
            swapKeyB,
            ownerOf(swapKeyB.fromPoppet)
        );

        verifySwapPermissionMasterKey(masterSignature, swapPermissionMasterKey);

        _swapCurios(
            _getTokenAccount(swapKeyA.toPoppet),
            _getTokenAccount(swapKeyA.fromPoppet),
            swapKeyA.remove,
            amounts.removeAmounts,
            swapKeyA.add,
            amounts.addAmounts
        );

        _swapCommunityCurios(
            _getTokenAccount(swapKeyA.toPoppet),
            _getTokenAccount(swapKeyA.fromPoppet),
            swapKeyA.removeC,
            amounts.removeCAmounts,
            swapKeyA.addC,
            amounts.addCAmounts
        );

        _initializeOwnershipAt(swapKeyA.fromPoppet);
        _setExtraDataAt(swapKeyA.fromPoppet, uint24(block.number));
        _initializeOwnershipAt(swapKeyB.toPoppet);
        _setExtraDataAt(swapKeyB.fromPoppet, uint24(block.number));

        emit PoppetTraitsUpdated(
            swapKeyA.fromPoppet,
            swapKeyA.remove,
            swapKeyA.add,
            swapKeyA.removeC,
            swapKeyA.addC
        );
        emit PoppetTraitsUpdated(
            swapKeyB.fromPoppet,
            swapKeyB.remove,
            swapKeyB.add,
            swapKeyB.removeC,
            swapKeyB.addC
        );
    }

    function swapCuriosBetweenOwnedPoppets(
        SwapPermissionKey calldata swapKey,
        Amounts calldata amounts,
        SwapPermissionMasterKey calldata masterKey,
        bytes calldata masterSignature
    )
        public
        payable
        onlyPoppetOwnerIfUnlocked(swapKey.toPoppet)
        onlyPoppetOwnerIfUnlocked(swapKey.fromPoppet)
    {
        if (SWAP_PRICE * 2 > msg.value) {
            revert InsufficientFunds();
        }

        verifySwapPermissionKey(masterKey.signatureA, swapKey, _msgSender());
        verifySwapPermissionMasterKey(masterSignature, masterKey);

        _swapCurios(
            _getTokenAccount(swapKey.toPoppet),
            _getTokenAccount(swapKey.fromPoppet),
            swapKey.remove,
            amounts.removeAmounts,
            swapKey.add,
            amounts.addAmounts
        );
        _swapCommunityCurios(
            _getTokenAccount(swapKey.toPoppet),
            _getTokenAccount(swapKey.fromPoppet),
            swapKey.removeC,
            amounts.removeCAmounts,
            swapKey.addC,
            amounts.addCAmounts
        );

        _initializeOwnershipAt(swapKey.fromPoppet);
        _setExtraDataAt(swapKey.fromPoppet, uint24(block.number));
        _initializeOwnershipAt(swapKey.toPoppet);
        _setExtraDataAt(swapKey.toPoppet, uint24(block.number));

        emit PoppetTraitsUpdated(
            swapKey.fromPoppet,
            swapKey.remove,
            swapKey.add,
            swapKey.removeC,
            swapKey.addC
        );
        emit PoppetTraitsUpdated(
            swapKey.toPoppet,
            swapKey.add,
            swapKey.remove,
            swapKey.addC,
            swapKey.removeC
        );
    }

    function journal(
        bytes calldata signature,
        uint256 tokenId,
        string calldata ipfs_cid
    ) external onlyPoppetOwner(tokenId) {
        if (JOURNAL == address(0)) {
            revert JournalNotEnabled();
        }
        verifyJournalKey(signature, tokenId, ipfs_cid);
        IJournal(JOURNAL).mint(_msgSender(), tokenId);
        emit JournalEntry(tokenId, ipfs_cid);
    }

    function deactivateSwapPermissionKey(bytes calldata signature) public {
        _markUsed(signature);
    }
}
