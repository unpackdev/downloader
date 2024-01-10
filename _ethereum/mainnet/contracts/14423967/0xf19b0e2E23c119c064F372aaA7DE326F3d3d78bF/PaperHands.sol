//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";
import "./IPaperHandsStaking.sol";

contract PaperHands is Initializable, ERC721AUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public constant TOTAL_MAX = 8888;
    uint256 public constant RESERVE_MAX = 150;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant PAPERLIST_PLUS_MAX = 4;
    uint256 public constant QUANTITY_MAX = 2;

    address private signer;
    address public payoutAddress;
    address public royaltyAddress;
    address public staking;

    uint256 public reserveAmountMinted;
    bool public plPlusActive;
    bool public presaleActive;
    bool public saleActive;
    bool private revealed;
    string private baseURI;

    uint96 private royaltyBasisPoints;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    function initialize(address _signer) public initializer {
        __ERC721A_init("PaperHands", "PPRHANDS");
        __Ownable_init();
        signer = _signer;
        royaltyBasisPoints = 500;
    }

    /**
     * @notice mint during presale
     */
    function presaleMint(
        uint256 _quantity,
        bool phPlus,
        bytes memory _signature,
        bool stake
    ) external payable {
        require(presaleActive, "NOT_ACTIVE");
        if (phPlus && plPlusActive) {
            require(
                _numberMinted(msg.sender) + _quantity <= PAPERLIST_PLUS_MAX,
                "INVALID_QUANTITY"
            );
        } else {
            require(!plPlusActive, "TOO_EARLY");
            require(
                _numberMinted(msg.sender) + _quantity <= QUANTITY_MAX,
                "INVALID_QUANTITY"
            );
        }
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + _quantity <= TOTAL_MAX, "TOTAL_EXCEEDED");
        require(
            matchSigner(hashTransaction(phPlus, msg.sender), _signature),
            "UNAUTHORIZED"
        );
        require(msg.value == MINT_PRICE * _quantity, "INVALID_ETH");
        _safeMint(msg.sender, _quantity);
        if (stake) {
            uint256[] memory tokenIds = new uint256[](_quantity);
            for (uint256 i = _quantity; i != 0; i--) {
                tokenIds[i - 1] = _totalSupply + _quantity - i;
            }
            setApprovalForAll(staking, true);
            IPaperHandsStaking(staking).stakeLock(msg.sender, tokenIds);
        }
    }

    /**
     * @notice mint during regular sale
     */
    function mint(uint256 _quantity, bool stake) external payable {
        require(saleActive, "NOT_ACTIVE");
        require(tx.origin == msg.sender, "NOT_EOA");
        uint256 _totalSupply = totalSupply();
        require(_totalSupply + _quantity <= TOTAL_MAX, "TOTAL_EXCEEDED");
        require(_quantity <= QUANTITY_MAX, "INVALID_QUANTITY");
        require(msg.value == MINT_PRICE * _quantity, "INVALID_ETH");
        _mint(msg.sender, _quantity, "", true);
        if (stake) {
            uint256[] memory tokenIds = new uint256[](_quantity);
            for (uint256 i = _quantity; i != 0; i--) {
                tokenIds[i - 1] = _totalSupply + _quantity - i;
            }
            setApprovalForAll(staking, true);
            IPaperHandsStaking(staking).stakeLock(msg.sender, tokenIds);
        }
    }

    /**
     * @notice release reserve
     */
    function releaseReserve(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        require(_quantity > 0, "INVALID_QUANTITY");
        require(totalSupply() + _quantity <= TOTAL_MAX, "TOTAL_EXCEEDED");
        require(
            reserveAmountMinted + _quantity <= RESERVE_MAX,
            "RESERVE_MAXED"
        );
        reserveAmountMinted += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
     * @notice view number minted of address
     */
    function numberMinted(address _account) external view returns (uint256) {
        uint256 _numberMinted = _numberMinted(_account);
        return _numberMinted;
    }

    /**
     * @notice create ethereum hash
     */
    function hashTransaction(bool phPlus, address wallet)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(phPlus, wallet))
            )
        );
        return hash;
    }

    /**
     * @notice verify signer
     */
    function matchSigner(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return signer == ECDSAUpgradeable.recover(hash, signature);
    }

    /**
     * @notice active presale
     */
    function togglePresale(bool presale, bool phPlus) external onlyOwner {
        presaleActive = presale;
        plPlusActive = phPlus;
    }

    /**
     * @notice active sale
     */
    function toggleSale() external onlyOwner {
        if (presaleActive) presaleActive = false;
        !saleActive ? saleActive = true : saleActive = false;
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata _baseURI, bool reveal)
        external
        onlyOwner
    {
        revealed = reveal;
        baseURI = _baseURI;
    }

    /**
     * @notice set royalty rate
     */
    function setRoyaltyRate(uint96 _royaltyBasisPoints) external onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
     * @notice set payment address
     */
    function setPaymentAddress(address _payoutAddress) external onlyOwner {
        payoutAddress = _payoutAddress;
    }

    /**
     * @notice set royalty address
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    /**
     * @notice set signer address
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signer = _signerAddress;
    }

    /**
     * @notice set staking address
     */
    function setStaking(address _staking) external onlyOwner {
        staking = _staking;
    }

    /**
     * @notice transfer funds
     */
    function transferFunds() external onlyOwner {
        (bool success, ) = payable(payoutAddress).call{
            value: address(this).balance
        }("");
        require(success, "TRANSFER_FAILED");
    }

    /**
     * @notice royalty information
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    /**
     * @notice supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice get nfts from wallet
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
     * @notice token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (revealed) {
            return
                string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        } else {
            return baseURI;
        }
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        IPaperHandsStaking(staking).transferRewards(_from, _to);
        for (uint256 i; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) public {
        IPaperHandsStaking(staking).transferRewards(_from, _to);
        for (uint256 i; i < _tokenIds.length; i++) {
            super.safeTransferFrom(_from, _to, _tokenIds[i], _data);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        IPaperHandsStaking(staking).transferRewards(from, to);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        IPaperHandsStaking(staking).transferRewards(from, to);
        super.safeTransferFrom(from, to, tokenId, data);
    }

}
