// SPDX-License-Identifier: MIT

// ███████╗　　██╗   ██╗　　███████╗　　██╗　　 ██████╗ 　　███╗   ██╗
// ██╔════╝　　██║   ██║　　██╔════╝　　██║　　██╔═══██╗　　████╗  ██║
// █████╗  　　██║   ██║　　███████╗　　██║　　██║   ██║　　██╔██╗ ██║
// ██╔══╝  　　██║   ██║　　╚════██║　　██║　　██║   ██║　　██║╚██╗██║
// ██║     　　╚██████╔╝　　███████║　　██║　　╚██████╔╝　　██║ ╚████║
// ╚═╝     　　 ╚═════╝ 　　╚══════╝　　╚═╝　　 ╚═════╝ 　　╚═╝  ╚═══╝

pragma solidity ^0.8.13;

import "./ERC721AQueryableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IFusionErrorCodes.sol";
import "./IERC721.sol";
import "./IERC4906.sol";
import "./IITEM.sol";
import "./IKATANA.sol";
import "./RevokableDefaultOperatorFiltererUpgradeable.sol";
import "./RevokableOperatorFiltererUpgradeable.sol";

contract FUSION is
    IERC4906,
    IFUSIONErrorCodes,
    Initializable,
    UUPSUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    RevokableDefaultOperatorFiltererUpgradeable
{
    using StringsUpgradeable for uint256;

    // public variables
    mapping(address => bool) public isBurnableContract;
    mapping(address => uint256) public amountMintedByAddress;
    mapping(address => uint256) public amountSaleTransferredByAddress;
    mapping(uint256 => bool) public isFusioned;
    mapping(uint256 => uint256[2]) public elementsIds; // [_itemId, _katanaId]
    uint256 public maxSupply;
    uint256 public price;
    uint256 public nextTransferId;
    string public mannequinURI;
    string public baseFusionURI;
    bool public isCreatingItemActive;
    bool public isPublicActive;
    bool public isPreActive;
    bool public isContractSaleActive;
    bool public isFusionActive;
    IITEM public itemContract;
    IKATANA public katanaContract;

    // private variables
    bytes32 private _merkleRoot;

    mapping(uint256 => uint256) public itemToKatanaMapping;
    // Events
    event MintAmount(
        uint256 _mintAmountLeft,
        uint256 _totalMinted,
        address _minter
    );
    event TransferredAmount(
        uint256 _transferAmountLeft,
        uint256 _contractBalance,
        address _caller
    );
    event PublicMint(uint256 _totalMinted, address _minter);

    event Fusioned(uint256 _tokenId, uint256 _itemId, uint256 _katanaId);

    // Modifiers
    modifier mintCompliance(uint256 _mintAmount) {
        if (_mintAmount <= 0) revert FUSION__MintAmountIsTooSmall();
        if (totalMinted() + _mintAmount > maxSupply)
            revert FUSION__MustMintWithinMaxSupply();
        _;
    }

    modifier transferCompliance(uint256 _amount) {
        if (balanceOf(address(this)) < _amount) revert FUSION__AmountIsTooBig();
        _;
    }

    modifier saleCompliance(uint256 _mintAmount, bool _isSaleActive) {
        if (!_isSaleActive) revert FUSION__NotReadyYet();
        if (msg.value != price * _mintAmount)
            revert FUSION__InsufficientMintPrice();
        _;
    }

    modifier merkleProofCompliance(
        uint256 _mintAmount,
        uint256 _maxMintableAmount,
        uint256 _processedAmount,
        address _to,
        bytes32[] calldata _merkleProof
    ) {
        if (_mintAmount > _maxMintableAmount - _processedAmount)
            revert FUSION__InsufficientMintsLeft();
        if (!_verify(_to, _maxMintableAmount, _merkleProof))
            revert FUSION__InvalidMerkleProof();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _maxSupply,
        uint256 _price,
        string memory _mannequinURI,
        bytes32 merkleRoot_
    ) public initializerERC721A initializer {
        __ERC721A_init("FUSION", "FUSION");
        __ERC721AQueryable_init();
        __ERC2981_init();
        __Ownable_init();
        __RevokableDefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
        maxSupply = _maxSupply;
        price = _price;
        _merkleRoot = merkleRoot_;
        mannequinURI = _mannequinURI;
    }

    /**
     * @dev For receiving ETH just in case someone tries to send it.
     */
    receive() external payable {}

    function ownerMint(
        address _to,
        uint256 _mintAmount
    ) external onlyOwner mintCompliance(_mintAmount) {
        if (_to == address(this)) {
            uint256 startTokenId = _startTokenId();
            nextTransferId = totalMinted() + startTokenId;
        }
        _safeMint(_to, _mintAmount);
    }

    function airdrop(
        address[] memory _toList,
        uint256[] memory _amountList
    ) external onlyOwner {
        if (_toList.length != _amountList.length)
            revert FUSION__MismatchedArrayLengths();
        uint256 maxCount = _toList.length;
        for (uint256 i = 0; i < maxCount; ) {
            _safeMint(_toList[i], _amountList[i]);
            unchecked {
                ++i;
            }
        }
    }

    function publicMint(
        uint256 _mintAmount
    )
        external
        payable
        mintCompliance(_mintAmount)
        saleCompliance(_mintAmount, isPublicActive)
        nonReentrant
    {
        address caller = _msgSender();
        _safeMint(caller, _mintAmount);
        emit PublicMint(totalMinted(), caller);
    }

    function preMint(
        uint256 _amount,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        mintCompliance(_amount)
        saleCompliance(_amount, isPreActive)
        merkleProofCompliance(
            _amount,
            _maxMintableAmount,
            amountMintedByAddress[_msgSender()],
            _msgSender(),
            _merkleProof
        )
    {
        address to = _msgSender();
        unchecked {
            amountMintedByAddress[to] += _amount;
        }
        _safeMint(to, _amount);
        uint256 mintAmountLeft;
        unchecked {
            mintAmountLeft = _maxMintableAmount - amountMintedByAddress[to];
        }
        emit MintAmount(mintAmountLeft, totalMinted(), to);
    }

    function contractSaleTransfer(
        uint256 _amount,
        uint256 _maxTransferableAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        saleCompliance(_amount, isContractSaleActive)
        transferCompliance(_amount)
        merkleProofCompliance(
            _amount,
            _maxTransferableAmount,
            amountSaleTransferredByAddress[_msgSender()],
            _msgSender(),
            _merkleProof
        )
    {
        address to = _msgSender();
        if (!_verify(to, _maxTransferableAmount, _merkleProof))
            revert FUSION__InvalidMerkleProof();
        unchecked {
            amountSaleTransferredByAddress[to] += _amount;
        }
        _safeTransferFromByContract(to, _amount);
        uint256 transferAmountLeft;
        unchecked {
            transferAmountLeft =
                _maxTransferableAmount -
                amountSaleTransferredByAddress[to];
        }
        emit TransferredAmount(
            transferAmountLeft,
            balanceOf(address(this)),
            to
        );
    }

    function executeFusion(
        uint256 _mannequinId,
        uint256 _itemId,
        uint256 _katanaId
    ) external nonReentrant {
        if (!isFusionActive) revert FUSION__NotReadyYet();
        address caller = _msgSender();
        if (!isFusionable(caller, _mannequinId, _itemId, _katanaId))
            revert FUSION__NotFusionable();
        itemContract.burn(caller, _itemId, 1);
        katanaContract.burn(caller, _katanaId, 1);
        isFusioned[_mannequinId] = true;
        elementsIds[_mannequinId] = [_itemId, _katanaId];
        emit MetadataUpdate(_mannequinId);
        emit Fusioned(_mannequinId, _itemId, _katanaId);
    }

    function isFusionable(
        address _address,
        uint256 _mannequinId,
        uint256 _itemId,
        uint256 _katanaId
    ) public view returns (bool) {
        if (
            ownerOf(_mannequinId) != _address ||
            isFusioned[_mannequinId] ||
            itemContract.balanceOf(_address, _itemId) == 0 ||
            katanaContract.balanceOf(_address, _katanaId) == 0 ||
            katanaContract.isTamaHagane(_katanaId) ||
            itemToKatanaMapping[_itemId] != _katanaId
        ) return false;
        return true;
    }

    function toggleCreatingItemActive() external onlyOwner {
        isCreatingItemActive = !isCreatingItemActive;
    }

    function togglePublicActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function togglePreActive() external onlyOwner {
        isPreActive = !isPreActive;
    }

    function toggleContractSaleActive() external onlyOwner {
        isContractSaleActive = !isContractSaleActive;
    }

    function toggleFusionActive() external onlyOwner {
        isFusionActive = !isFusionActive;
    }

    /**
     * @notice Only the owner can withdraw all of the contract balance.
     * @dev All the balance transfers to the owner's address.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        if (!success) revert FUSION__WithdrawFailed();
    }

    function transferERC721To(
        address _to,
        uint256 _amount
    ) external transferCompliance(_amount) onlyOwner {
        _safeTransferFromByContract(_to, _amount);
    }

    function setBatchItemToKatana(
        uint256[] memory _itemIdList,
        uint256[] memory _katanaIdList
    ) external onlyOwner {
        uint256 itemIdLen = _itemIdList.length;
        if (itemIdLen != _katanaIdList.length || itemIdLen == 0)
            revert FUSION__MismatchedArrayLengths();

        for (uint256 i = 0; i < itemIdLen; ) {
            itemToKatanaMapping[_itemIdList[i]] = _katanaIdList[i];
            unchecked {
                ++i;
            }
        }
    }

    function setItemContract(address _contractAddress) external onlyOwner {
        itemContract = IITEM(_contractAddress);
    }

    function setKatanaContract(address _contractAddress) external onlyOwner {
        katanaContract = IKATANA(_contractAddress);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBurnableContract(
        address _contractAddress,
        bool _isBurnable
    ) external onlyOwner {
        isBurnableContract[_contractAddress] = _isBurnable;
    }

    function setMerkleProof(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setNextTransferId(uint256 _nextTransferId) external onlyOwner {
        nextTransferId = _nextTransferId;
    }

    function setMannequinURI(
        string memory _newMannequinURI
    ) external onlyOwner {
        mannequinURI = _newMannequinURI;
        emit BatchMetadataUpdate(_startTokenId(), totalMinted());
    }

    function setBaseFusionURI(
        string memory _newBaseFusionURI
    ) external onlyOwner {
        baseFusionURI = _newBaseFusionURI;
        emit BatchMetadataUpdate(_startTokenId(), totalMinted());
    }

    /**
     * @dev Set the new royalty fee and the new receiver.
     */
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFee
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    function burn(uint256 _tokenId) public nonReentrant {
        if (_msgSender() != ownerOf(_tokenId)) revert FUSION__NotTokenOwner();
        _burn(_tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}

    function _safeTransferFromByContract(address _to, uint256 _amount) private {
        uint256 startTransferId = nextTransferId;
        uint256 endTransferId = startTransferId + _amount;
        nextTransferId = endTransferId;
        address from = address(this);
        uint256[] memory tokenIds = _tokensOfOwnerIn(
            from,
            startTransferId,
            endTransferId
        );
        if (_amount != tokenIds.length) revert FUSION__MismatchedArrayLengths();
        for (uint256 i = 0; i < _amount; ) {
            this.safeTransferFrom(from, _to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        if (!isFusioned[_tokenId]) return mannequinURI;
        return
            bytes(baseFusionURI).length != 0
                ? string(abi.encodePacked(baseFusionURI, _toString(_tokenId)))
                : "";
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the owner of the ERC1155 token contract.
     */
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function mintableAmount(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256) {
        uint256 amountMinted = amountMintedByAddress[_address];
        if (
            _verify(_address, _maxMintableAmount, _merkleProof) &&
            amountMinted < _maxMintableAmount
        ) return _maxMintableAmount - amountMinted;
        else return 0;
    }

    function fusionableTokensOfOwer(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256[] memory tokensOfOwner = this.tokensOfOwner(_owner);
        uint256 count = 0;

        // Count the fusionable tokens
        for (uint256 i = 0; i < tokensOfOwner.length; ) {
            if (!isFusioned[tokensOfOwner[i]]) {
                count++;
            }
            unchecked {
                ++i;
            }
        }

        uint256[] memory fusionableTokensOfOwner = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < tokensOfOwner.length; ) {
            if (!isFusioned[tokensOfOwner[i]]) {
                fusionableTokensOfOwner[index] = tokensOfOwner[i];
                unchecked {
                    ++index;
                }
            }
            unchecked {
                ++i;
            }
        }
        return fusionableTokensOfOwner;
    }

    function _tokensOfOwnerIn(
        address _owner,
        uint256 _start,
        uint256 _stop
    ) private view returns (uint256[] memory) {
        return this.tokensOfOwnerIn(_owner, _start, _stop);
    }

    function _verify(
        address _address,
        uint256 _maxMintableAmount,
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(_address, _maxMintableAmount.toString())
        );

        return MerkleProofUpgradeable.verify(_merkleProof, _merkleRoot, leaf);
    }
}