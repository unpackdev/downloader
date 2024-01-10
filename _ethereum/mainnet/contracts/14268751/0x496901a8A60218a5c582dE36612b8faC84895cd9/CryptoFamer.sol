// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./ERC721A.sol";
import "./AccessControlEnumerable.sol";
import "./Strings.sol";

contract CryptoFamer is ERC721A, AccessControlEnumerable {
    using Strings for uint256;

    address constant private economist = 0x7632af0c66d707747c493cFC190591A12C64A812;
    address constant private dev = 0xa5C26Bc9c86Fc70D3cEd078F46B52342B8Bd8FE6;
    address constant private dev2 = 0xE69B1D13682eEc14505B0E54c8696eaFD5F964fB;

    bytes32 private constant OPERATOR = keccak256("OPERATOR");

    uint256 constant public MAX_SUPPLY = 1337;
    uint256 public tierSupply = 200;

    uint256 public mintPrice = 0.1 ether;
    uint256 public whitelistPrice = 0.08 ether;

    uint256 public maxAmountPerMint = 5;

    string internal _baseUri = '';

    bool public isPublicSaleActive = false;
    uint256 public publicSaleStartTime = 1648270800;


    bool public isWhitelistSaleActive = false;
    uint256 public whitelistSaleStartTime = 1648260000;


    mapping(address => uint256) public whitelist;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    event WhitelistMint_Started();
    event WhitelistMint_Stopped();
    event PublicSale_Started();
    event PublicSale_Stopped();
    event TokenMinted(uint256 supply);

    constructor() ERC721A("CryptoFamers", "CF") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR, _msgSender());
        _setupRole(OPERATOR, economist);
        _setupRole(OPERATOR, dev);
        _setupRole(OPERATOR, dev2);
    }

    /*
        Access control settings
    */

    function transferOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), 'ERC721A: mint to the zero address');
        address oldOwner = _msgSender();
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
    }

    function addOperator(address newOperator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOperator != address(0), 'Add zero address as admin');
        grantRole(OPERATOR, newOperator);
    }

    function revokeOperator(address toRemove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR, toRemove);
    }

    function owner() external view returns(address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function getOperators() external view returns(address[] memory) {
        uint256 length = getRoleMemberCount(OPERATOR);

        address[] memory rets = new address[](length);

        for (uint256 i; i < length ; i++) {
            rets[i] = getRoleMember(OPERATOR, i);
        }
        return rets;
    }

    /*
        Variable settings
    */
    function setTierSupply(uint256 newTierSupply) public onlyRole(OPERATOR) {
        require(newTierSupply <= MAX_SUPPLY, 'Exceed max supply');
        require(newTierSupply >= totalSupply(), 'Tier supply should be greater than total supply');
        tierSupply = newTierSupply;
    }

    function setMintPrice(uint256 newMintPrice) public onlyRole(OPERATOR) {
        mintPrice = newMintPrice;
    }

    function setWhitelistMintPrice(uint256 newWLMintPrice) public onlyRole(OPERATOR) {
        whitelistPrice = newWLMintPrice;
    }

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) public onlyRole(OPERATOR) {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    function setBaseURI(string memory newBaseUri) external onlyRole(OPERATOR){ 
        _baseUri = newBaseUri;
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /*
        white list setting
    */
    function setWhitelist(address[] memory addresses, uint256[] memory numSlots)
        external
        onlyRole(OPERATOR)
    {
        require(
        addresses.length == numSlots.length,
        "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
        whitelist[addresses[i]] = numSlots[i];
        }
    }


    /*
        sale settings
    */
    function flipPublicSaleActive() public onlyRole(OPERATOR) {
        isPublicSaleActive = !isPublicSaleActive;
        if (isPublicSaleActive) {
            emit PublicSale_Started();
        } else {
            emit PublicSale_Stopped();
        }
    }

    function setPublicSaleTime(uint256 newStartTime) public onlyRole(OPERATOR) {
        publicSaleStartTime = newStartTime;
    }

    function flipWhitelistSaleActive() public onlyRole(OPERATOR) {
        isWhitelistSaleActive = !isWhitelistSaleActive;
        if (isWhitelistSaleActive) {
            emit WhitelistMint_Started();
        } else {
            emit WhitelistMint_Stopped();
        }
    }

    function setWhitelistSaleTime(uint256 newStartTime) public onlyRole(OPERATOR) {
        whitelistSaleStartTime = newStartTime;
    }


    /*
        mint
    */

    function isPublicSaleOn() public view returns (bool) {
        return
        isPublicSaleActive &&
        block.timestamp >= publicSaleStartTime;
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {

        require(isPublicSaleOn(), 'Sale not active');
        require(totalSupply() + quantity <= tierSupply, 'Sale would exceed tier supply');
        require(quantity <= maxAmountPerMint, 'Sale would exceed max mint per mint');
        require(quantity * mintPrice <= msg.value, 'Not enough ether sent');
        _safeMint(msg.sender, quantity);
        emit TokenMinted(totalSupply());
    }

    function isWhitelistSaleOn() public view returns (bool) {
        return
        isWhitelistSaleActive &&
        block.timestamp >= whitelistSaleStartTime;
    }

    function whitelistMint() external payable callerIsUser {
        require(isWhitelistSaleOn(), "whitelist sale has not begun yet");
        require(whitelist[msg.sender] > 0, "not eligible for whitelist mint");
        require(totalSupply() + 1 <= tierSupply, "reached max supply");
        require(whitelistPrice <= msg.value, 'Not enough ether sent');
        whitelist[msg.sender]--;
        _safeMint(msg.sender, 1);
        emit TokenMinted(totalSupply());
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
        totalSupply() + quantity <= tierSupply,
        "Will exceed tier supply"
        );
        _safeMint(msg.sender, quantity);
        emit TokenMinted(totalSupply());

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyRole(OPERATOR) {
        uint256 balance = address(this).balance;
        if (totalSupply() >= 201) {
            uint256 devShare = balance * 375 / 10000;
            uint256 ownerShare = balance - 2 * devShare;
            require(payable(dev).send(devShare), "Send Failed");
            require(payable(dev2).send(devShare), "Send Failed");
            require(payable(economist).send(ownerShare), "Send Failed");
        } else {
            require(payable(economist).send(balance), "Send Failed");
        }
    }

}