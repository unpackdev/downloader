// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IERC721.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IERC721Burnable is IERC721 {
    function burn(uint256 tokenId) external;
    function getPyramidSlots(uint16 _pyramidId) external view returns (TokenSlot[4] memory tokenSlots);
}

    struct TokenSlot {
        uint16 tokenId;
        bool occupied;
    }

contract INX is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable
{
    IERC721Burnable public pyramidToken;
    IERC721 public quirklingToken;


    event TokenBurnt(
        uint256 pyramidTokenId,
        uint256 pyramidToken2Id,
        uint256 quirklingTokenId,
        uint256 quirklingToken2Id,
        uint256 mintedToken
    );

    event TokenMinted(
        uint256 quirklingTokenId,
        uint256 quirklingToken2Id,
        uint256 mintedToken
    );

    uint256 public MAX_SUPPLY;

    bool public _isBurnActive;
    bool public _isMintActive;

    uint256 public ETH_MINTING_PRICE;

    function initialize(
        string memory baseURI,
        address teamWallet,
        address pyramidTokenAddress,
        address quirklingTokenAddress
    ) public initializer {
        __ERC721_init("INX", "INX");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        __ERC2981_init();
        __ReentrancyGuard_init();

        pyramidToken = IERC721Burnable(pyramidTokenAddress);
        quirklingToken = IERC721(quirklingTokenAddress);
        _setDefaultRoyalty(teamWallet, 700);
        _baseTokenURI = baseURI;
        _isBurnActive = false;
        _isMintActive = false;
        //minting price not confirmed
        ETH_MINTING_PRICE = 0.05 ether;
        MAX_SUPPLY = 2500;
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function changeRoyalty(uint96 _royalty, address _teamWallet) external onlyOwner {
        _setDefaultRoyalty(_teamWallet, _royalty);
    }

    function updateEthMintingPrice(uint256 _newPrice) external onlyOwner {
        ETH_MINTING_PRICE = _newPrice;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
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
        override(ERC721Upgradeable, IERC721Upgradeable)
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
        override(ERC721Upgradeable, IERC721Upgradeable)
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
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBurnActive(bool isActive) external onlyOwner {
        _isBurnActive = isActive;
    }

    function setMintActive(bool isActive) external onlyOwner {
        _isMintActive = isActive;
    }

    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function mint(
        uint quirklingTokenId,
        uint256 quirklingTokenId2
    ) external payable nonReentrant{
        require(_isMintActive, "mint has not begun yet");
        require(msg.value >= ETH_MINTING_PRICE, "Insufficient ETH sent");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
        require(
            quirklingTokenId >= 5000 && quirklingTokenId2 >= 5000,
            "Quirlking token id should be 5000+"
        );
        quirklingToken.transferFrom(msg.sender, 0x0000000000000000000000000000000000000001, quirklingTokenId);
        quirklingToken.transferFrom(msg.sender, 0x0000000000000000000000000000000000000001, quirklingTokenId2);
        _safeMint(msg.sender, totalSupply() + 1);
        emit TokenMinted(
            quirklingTokenId,
            quirklingTokenId2,
            totalSupply()
        );
    }

    function theGreatBurn(
        uint16 pyramidTokenId,
        uint16 pyramidTokenId2,
        uint16 quirklingTokenId,
        uint16 quirklingTokenId2
    ) external callerIsUser nonReentrant {
        require(_isBurnActive, "the great burn has not begun yet");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
        require(
            pyramidToken.isApprovedForAll(msg.sender, address(this)),
            "Pyramids not approved"
        );
        require(
            quirklingToken.isApprovedForAll(msg.sender, address(this)),
            "Quirklings not approved"
        );
        require(
            quirklingTokenId >= 5000 && quirklingTokenId2 >= 5000,
            "Quirlking token id should be 5000+"
        );

        TokenSlot[4] memory pyramidSlots = pyramidToken.getPyramidSlots(pyramidTokenId);
        require(pyramidSlots[0].occupied, "pyramid is not fully equipped");
        require(pyramidSlots[1].occupied, "pyramid is not fully equipped");
        require(pyramidSlots[2].occupied, "pyramid is not fully equipped");
        require(pyramidSlots[3].occupied, "pyramid is not fully equipped");

        
        TokenSlot[4] memory pyramidSlots2 = pyramidToken.getPyramidSlots(pyramidTokenId2);
        require(pyramidSlots2[0].occupied, "pyramid 2 is not fully equipped");
        require(pyramidSlots2[1].occupied, "pyramid 2 is not fully equipped");
        require(pyramidSlots2[2].occupied, "pyramid 2 is not fully equipped");
        require(pyramidSlots2[3].occupied, "pyramid 2 is not fully equipped");

                
        pyramidToken.transferFrom(msg.sender, address(this), pyramidTokenId);
        pyramidToken.transferFrom(msg.sender, address(this), pyramidTokenId2);
        pyramidToken.burn(pyramidTokenId);
        pyramidToken.burn(pyramidTokenId2);
        quirklingToken.transferFrom(msg.sender, 0x0000000000000000000000000000000000000001, quirklingTokenId);
        quirklingToken.transferFrom(msg.sender, 0x0000000000000000000000000000000000000001, quirklingTokenId2);
        _safeMint(msg.sender, totalSupply() + 1 );
        emit TokenBurnt(
            pyramidTokenId,
            pyramidTokenId2,
            quirklingTokenId,
            quirklingTokenId2,
            totalSupply()
        );
    }
}
