// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./CommissionUpgradeable.sol";
import "./IHumbleNFTERC721Upgradeable.sol";

/*  Commission fee calculation related contract */
contract HumblGalleryERC721 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    CommissionUpgradeable,
    ReentrancyGuardUpgradeable
{
    /* Execute once on contract deployment with commission fee, commission fee receiver, royaltyFraction and royalty receiver */
    function initialize(uint96 commissionPercentage, address commissionReceiver)
        public
        initializer
    {
        __ERC721_init("HumblGallery", "HUMBL");
        __ReentrancyGuard_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        require(commissionPercentage >= 0, "H101");
        require(commissionPercentage <= 5000, "H102");
        require(commissionReceiver != address(0), "H103");
        _setDefaultCommission(commissionPercentage);
        _setCommissionReceiver(commissionReceiver);
        setPaymentToken(0, address(0));
    }

    /* event trigger on buying */
    event safeSaleNFT(
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 transferAmount,
        uint256 commissionAmount,
        address commissionReceiver
    );
    event royaltyEvent(address royaltyReceiver, uint256 royaltyAmount);
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    address public admin;
    mapping(bytes32 => bool) public executedHash;
    /* Map all humbleNFT to  HumblNFTs*/
    mapping(uint256 => HumblNFT) public HumblNFTs;
    mapping(uint8 => address) paymentTokens;
    /* define struct for holds token and sale data */
    struct HumblNFT {
        string tokenURI;
        address minter;
        uint96 commission;
        bool isCommissionChanged;
        uint8 ERC20TokenIndex;
        uint256 price;
        uint256 salt;
        uint96[] royalty;
        address[] royaltyReceiver;
    }
    /* define struct for holds temporary  NFT as parameter */
    struct NFT {
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        address commissionReceiver;
        uint256 commissionAmount;
        address[] royaltyReceiver;
        uint256[] royaltyAmount;
        address ERC20Token;
    }
    /* sale type enum */
    enum SaleKind {
        FixedPrice,
        Auction
    }
    /* payload structure */
    struct Payload {
        uint256 tokenId;
        uint256 price;
        uint256 salt;
        string tokenURI;
        uint8 ERC20TokenIndex;
        address seller;
        address buyer;
        address[] royaltyReceiver;
        uint96[] royaltyPercentage;
        SaleKind saleKind;
    }
    /* signature structure */
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* Mint with Quantities, saleQauntity, unit price, currency,royaltyFraction */
    function mint(
        uint256[3] memory intData,
        string calldata uri,
        uint8 ERC20TokenIndex,
        address seller,
        address buyer,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        SaleKind salekind
    ) public whenNotPaused returns (uint256) {
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            uri,
            ERC20TokenIndex,
            seller,
            buyer,
            royaltyReceiver,
            royaltyPercentage,
            salekind
        );
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        payload.tokenId = _mint(payload);
        executedHash[hash] = true;
        return payload.tokenId;
    }

    /* Mint and buy with Quantities, saleQauntity, unit price, currency, royaltyFraction */
    function lazyMint(
        uint256[3] memory intData,
        string calldata uri,
        uint8 ERC20TokenIndex,
        address seller,
        address buyer,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        Signature memory sig,
        SaleKind salekind
    ) public payable whenNotPaused nonReentrant returns (uint256 tokenId) {
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            uri,
            ERC20TokenIndex,
            seller,
            buyer,
            royaltyReceiver,
            royaltyPercentage,
            salekind
        );
        bytes32 hash = _Hash(payload);
        payload.buyer = _msgSender();
        require(payload.saleKind == SaleKind.FixedPrice, "H162");
        require(!executedHash[hash], "H106");
        require(validateSignature(seller, hash, sig), "H107");
        payload.tokenId = _mint(payload);
        _safeTransferNFT(payload);
        executedHash[hash] = true;
        return payload.tokenId;
    }

    /* Mint and Transfer */
    function transferWithMint(
        uint256[3] memory intData,
        string calldata uri,
        uint8 ERC20TokenIndex,
        address seller,
        address buyer,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyPercentage,
        SaleKind salekind
    ) public whenNotPaused nonReentrant returns (uint256 tokenId) {
        Payload memory payload = Payload(
            intData[0],
            intData[1],
            intData[2],
            uri,
            ERC20TokenIndex,
            seller,
            buyer,
            royaltyReceiver,
            royaltyPercentage,
            salekind
        );
        payload.tokenId = _mint(payload);
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        _safeTransfer(payload.seller, payload.buyer, payload.tokenId, "");
        executedHash[hash] = true;
        return payload.tokenId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /* Only buyer would be able to excecute  */
    function safeBuyNFT(Payload memory payload, Signature memory sig)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        bytes32 hash = _Hash(payload);
        /* if payload.buyer is zero address then any buyer can buy the NFT */
        if (payload.buyer == address(0)) {
            payload.buyer = _msgSender();
        } else {
            /* if payload.buyer is non zero address then only current buyer is allowed to buy the NFT */
            require(payload.buyer == _msgSender(), "H180");
        }
        require(payload.saleKind == SaleKind.FixedPrice, "H162");
        require(validateSignature(payload.seller, hash, sig), "H107");
        HumblNFT storage nft = HumblNFTs[payload.tokenId];
        require(payload.salt >= nft.salt, "H161");
        if (!executedHash[hash]) {
            nft.price = payload.price;
            nft.salt = payload.salt;
            executedHash[hash] = true;
        }
        _safeTransferNFT(payload);
    }

    /* Transfer NFT through Auction by admin or seller */
    function safeTransferNFT(
        Payload memory sellerPayload,
        Payload memory buyerPayload,
        Signature memory sellerSig,
        Signature memory buyerSig
    ) public payable whenNotPaused nonReentrant {
        bytes32 sellerHash = _Hash(sellerPayload);
        bytes32 buyerHash = _Hash(buyerPayload);
        require(!executedHash[sellerHash], "H106");
        require(!executedHash[buyerHash], "H174");
        require(validateSignature(sellerPayload.seller, sellerHash, sellerSig), "H154");
        require(validateSignature(buyerPayload.buyer, buyerHash, buyerSig), "H155");
        require(sellerPayload.saleKind == SaleKind.Auction, "H163");
        require(_msgSender() == sellerPayload.seller || admin == _msgSender(), "H156");
        require(buyerPayload.ERC20TokenIndex == sellerPayload.ERC20TokenIndex, "H158");
        require(buyerPayload.tokenId == sellerPayload.tokenId, "H179");
        require(buyerPayload.seller == sellerPayload.seller, "H180");
        if (!_exists(sellerPayload.tokenId)) {
            _mint(sellerPayload);
            executedHash[sellerHash] = true;
        }
        address _token = getPaymentToken(sellerPayload.ERC20TokenIndex);
        _executeTransferNFT(
            sellerPayload.seller,
            buyerPayload.buyer,
            buyerPayload.tokenId,
            buyerPayload.price,
            _token
        );
        executedHash[buyerHash] = true;
    }

    /* Transfer Already minted NFT through Auction by admin or seller */
    function safeTransferNFTERC721(
        IHumbleNFTERC721Upgradeable ERC721humbleNFT,
        Payload memory sellerPayload,
        Payload memory buyerPayload,
        Signature memory sellerSig,
        Signature memory buyerSig
    ) public payable whenNotPaused nonReentrant {
        bytes32 sellerHash = _Hash(sellerPayload);
        bytes32 buyerHash = _Hash(buyerPayload);
        require(!executedHash[sellerHash], "H106");
        require(!executedHash[buyerHash], "H174");
        require(validateSignature(sellerPayload.seller, sellerHash, sellerSig), "H154");
        require(validateSignature(buyerPayload.buyer, buyerHash, buyerSig), "H155");
        require(_msgSender() == sellerPayload.seller || admin == _msgSender(), "H156");
        require(buyerPayload.ERC20TokenIndex == sellerPayload.ERC20TokenIndex, "H158");
        require(buyerPayload.tokenId == sellerPayload.tokenId, "H179");
        require(buyerPayload.seller == sellerPayload.seller, "H180");
        require(sellerPayload.saleKind == SaleKind.Auction, "H163");
        address _token = getPaymentToken(sellerPayload.ERC20TokenIndex);
        _executeTransferERC721(
            ERC721humbleNFT,
            sellerPayload.seller,
            buyerPayload.buyer,
            buyerPayload.tokenId,
            buyerPayload.price,
            _token
        );
        executedHash[sellerHash] = true;
        executedHash[buyerHash] = true;
    }

    /* Validate signature */
    function validateSignature(
        address seller,
        bytes32 hash,
        Signature memory sig
    ) public pure returns (bool) {
        bytes32 _hash = hash.toEthSignedMessageHash();
        return _hash.recover(sig.v, sig.r, sig.s) == seller;
    }

    /* Invalidate signature */
    function cancelHash(Payload memory payload, Signature memory sig) public whenNotPaused {
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        require(validateSignature(_msgSender(), hash, sig), "H107");
        executedHash[hash] = true;
    }

    /* Genrate signature */
    function _Hash(Payload memory payload) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    payload.tokenId,
                    payload.price,
                    payload.tokenURI,
                    payload.ERC20TokenIndex,
                    payload.seller,
                    payload.buyer,
                    payload.royaltyReceiver,
                    payload.royaltyPercentage,
                    payload.salt,
                    payload.saleKind,
                    address(this)
                )
            );
    }

    /* Internal mint */
    function _mint(Payload memory payload) internal returns (uint256) {
        require(!_exists(payload.tokenId), "H173");
        require(bytes(payload.tokenURI).length >= 1, "H116");
        require(payload.royaltyPercentage.length == payload.royaltyReceiver.length, "H105");
        uint256 totalFee;
        for (uint256 i = 0; i < payload.royaltyPercentage.length; ++i) {
            totalFee = totalFee.add(payload.royaltyPercentage[i]);
        }
        require(totalFee <= 5000, "H176");
        _mint(payload.seller, payload.tokenId);
        if (bytes(payload.tokenURI).length > 0) {
            _setTokenURI(payload.tokenId, payload.tokenURI);
        }
        HumblNFT storage newNFT = HumblNFTs[payload.tokenId];
        newNFT.tokenURI = payload.tokenURI;
        newNFT.minter = payload.seller;
        newNFT.ERC20TokenIndex = payload.ERC20TokenIndex;
        newNFT.royalty = payload.royaltyPercentage;
        newNFT.royaltyReceiver = payload.royaltyReceiver;
        newNFT.price = payload.price;
        newNFT.salt = payload.salt;
        return payload.tokenId;
    }

    /* Set commission fee by plateform owner */
    function setCommission(uint256 tokenId, uint96 commissionPercentage) public virtual onlyOwner {
        require(_exists(tokenId), "H120");
        require(commissionPercentage >= 0, "H121");
        require(commissionPercentage <= 5000, "H122");
        HumblNFT storage nft = HumblNFTs[tokenId];
        nft.commission = commissionPercentage;
        nft.isCommissionChanged = true;
    }

    /* Set commission fee receiver*/
    function setCommissionReceiver(address commissionReceiver) public virtual onlyOwner {
        _setCommissionReceiver(commissionReceiver);
    }

    /* Return Commission fee */
    function getCommissionBalance(address receiver) public view onlyOwner returns (uint256) {
        return _getCommissionBalance(receiver);
    }

    /* Set commission fee in percentage beetween 0 to 100 */
    function setDefaultCommission(uint96 commissionPercentage) public virtual onlyOwner {
        require(commissionPercentage >= 0, "H123");
        require(commissionPercentage <= 5000, "H124");
        _setDefaultCommission(commissionPercentage);
    }

    /* Return default commission fee */
    function getDefaultCommission() public view returns (uint256) {
        return _getDefaultCommission();
    }

    /* Return commission fee receiver */
    function getCommissionReceiver() public view returns (address) {
        return _getCommissionReceiver();
    }

    /* Set ERC20 payment token */
    function setPaymentToken(uint8 index, address token) public virtual onlyOwner {
        paymentTokens[index] = token;
    }

    /* Get ERC20 payment token */
    function getPaymentToken(uint8 index) public view returns (address) {
        return paymentTokens[index];
    }

    /* To check only token minter is allowed */
    modifier tokenMinterOnly(uint256 tokenId) {
        HumblNFT storage nft = HumblNFTs[tokenId];
        require(nft.minter == _msgSender(), "H104");
        _;
    }

    /* Pause contract for execution - stopped state */
    function pause() public onlyOwner {
        _pause();
    }

    /* Unpause contract return to normal state */
    function unpause() public onlyOwner {
        _unpause();
    }

    /* Get royalties receiver and percentage */
    function getRoyalties(uint256 tokenId) public view returns (uint96[] memory, address[] memory) {
        require(_exists(tokenId), "H126");
        return (HumblNFTs[tokenId].royalty, HumblNFTs[tokenId].royaltyReceiver);
    }

    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "H138");
        admin = _admin;
    }

    /* Execute fund transfer ERC721 - royalty, commission and NFT price */
    function _safeTransferNFT(Payload memory payload) internal {
        require(payload.seller != address(0), "H138");
        HumblNFT storage nft = HumblNFTs[payload.tokenId];
        payload.price = nft.price;
        address ERC20Token = paymentTokens[nft.ERC20TokenIndex];
        _executeTransferNFT(
            payload.seller,
            payload.buyer,
            payload.tokenId,
            payload.price,
            ERC20Token
        );
    }

    /* Buy external ERC721 contract */
    function safeBuyNFTERC721(
        IHumbleNFTERC721Upgradeable ERC721humbleNFT,
        Payload memory payload,
        Signature memory sig
    ) public payable whenNotPaused nonReentrant {
        bytes32 hash = _Hash(payload);
        require(!executedHash[hash], "H106");
        require(payload.saleKind == SaleKind.FixedPrice, "H162");
        require(validateSignature(payload.seller, hash, sig), "H133");
        address ERC20Token = paymentTokens[payload.ERC20TokenIndex];
        _executeTransferERC721(
            ERC721humbleNFT,
            payload.seller,
            _msgSender(),
            payload.tokenId,
            payload.price,
            ERC20Token
        );
        executedHash[hash] = true;
    }

    function _executeTransferERC721(
        IHumbleNFTERC721Upgradeable ERC721humbleNFT,
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price,
        address ERC20Token
    ) internal {
        require(seller != address(0), "H150");
        require(ERC721humbleNFT.balanceOf(seller) >= 1, "H151");
        if (ERC20Token == address(0)) {
            require(msg.value >= price, "H152");
        } else {
            require(IERC20Upgradeable(ERC20Token).balanceOf(buyer) >= price, "H153");
        }
        uint256 royaltyPercentage;
        address[] memory royaltyReceiver = new address[](1);
        (royaltyPercentage, royaltyReceiver[0]) = ERC721humbleNFT.royaltyInfo();
        uint256[] memory royaltyAmount = new uint256[](1);
        if (royaltyReceiver[0] != seller) {
            royaltyAmount[0] = (price * royaltyPercentage) / 100;
        } else {
            royaltyAmount[0] = 0;
            royaltyReceiver[0] = address(0);
        }
        uint96 commission = _getDefaultCommission();
        address commissionReceiver;
        uint256 commissionAmount;
        if (commission > 0) {
            (commissionReceiver, commissionAmount) = _getCommission(commission, price);
        }
        NFT memory _data = NFT(
            tokenId,
            seller,
            buyer,
            price,
            commissionReceiver,
            commissionAmount,
            royaltyReceiver,
            royaltyAmount,
            ERC20Token
        );
        _executeFundTransfer(_data);
        ERC721humbleNFT.safeTransferFrom(seller, buyer, tokenId, "");
    }

    function _executeTransferNFT(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price,
        address ERC20Token
    ) internal {
        require(_exists(tokenId), "H143");
        HumblNFT storage nft = HumblNFTs[tokenId];
        if (ERC20Token == address(0)) {
            require(msg.value == price, "H145");
        } else {
            require(IERC20Upgradeable(ERC20Token).balanceOf(buyer) >= price, "H146");
        }
        uint256[] memory royaltyAmount = new uint256[](nft.royalty.length);
        address commissionReceiver;
        uint256 commissionAmount;
        if (nft.minter != seller) {
            if (nft.royalty.length > 0) {
                for (uint256 i = 0; i < nft.royalty.length; i++) {
                    royaltyAmount[i] = (price * nft.royalty[i]) / 10000;
                }
            }
        }
        if (nft.isCommissionChanged) {
            if (nft.commission > 0) {
                (commissionReceiver, commissionAmount) = _getCommission(nft.commission, price);
            }
        } else {
            (commissionReceiver, commissionAmount) = _getCommission(_getDefaultCommission(), price);
        }
        NFT memory _data = NFT(
            tokenId,
            seller,
            buyer,
            price,
            commissionReceiver,
            commissionAmount,
            nft.royaltyReceiver,
            royaltyAmount,
            ERC20Token
        );
        _executeFundTransfer(_data);
        _safeTransfer(seller, buyer, tokenId, "");
    }

    /* Execute funds transfer */
    function _executeFundTransfer(NFT memory _data) internal {
        /* Commission calculation and pay*/
        if (_data.commissionAmount > 0) {
            if (_data.ERC20Token == address(0)) {
                _setCommissionBalance(_data.commissionReceiver, _data.commissionAmount);
                payable(_data.commissionReceiver).transfer(_data.commissionAmount);
            } else {
                _transferWithTokens(
                    _data.ERC20Token,
                    _data.buyer,
                    _data.commissionReceiver,
                    _data.commissionAmount
                );
            }
        }
        /* Royalty calculation on secondary sale and pay*/
        uint256 totalRoyaltyAmount = 0;
        if (_data.royaltyAmount.length > 0) {
            if (_data.ERC20Token == address(0)) {
                for (uint256 i = 0; i < _data.royaltyAmount.length; i++) {
                    totalRoyaltyAmount = totalRoyaltyAmount.add(_data.royaltyAmount[i]);
                    payable(_data.royaltyReceiver[i]).transfer(_data.royaltyAmount[i]);
                    emit royaltyEvent(_data.royaltyReceiver[i], _data.royaltyAmount[i]);
                }
            } else {
                for (uint256 i = 0; i < _data.royaltyAmount.length; i++) {
                    totalRoyaltyAmount = totalRoyaltyAmount.add(_data.royaltyAmount[i]);
                    _transferWithTokens(
                        _data.ERC20Token,
                        _data.buyer,
                        _data.royaltyReceiver[i],
                        _data.royaltyAmount[i]
                    );
                    emit royaltyEvent(_data.royaltyReceiver[i], _data.royaltyAmount[i]);
                }
            }
        }
        uint256 _transferAbleAmount = (_data.price).sub(
            ((totalRoyaltyAmount).add(_data.commissionAmount)),
            "H148"
        );
        if (_data.ERC20Token == address(0)) {
            payable(_data.seller).transfer(_transferAbleAmount);
        } else {
            _transferWithTokens(_data.ERC20Token, _data.buyer, _data.seller, _transferAbleAmount);
        }
        emit safeSaleNFT(
            _data.seller,
            _data.buyer,
            _data.tokenId,
            _transferAbleAmount,
            _data.commissionAmount,
            _data.commissionReceiver
        );
    }

    function _transferWithTokens(
        address ERC20Token,
        address from,
        address to,
        uint256 price
    ) internal {
        if (price > 0) {
            require(IERC20Upgradeable(ERC20Token).transferFrom(from, to, price), "H175");
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /* The following functions are overrides required by Solidity. */

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
        delete HumblNFTs[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
