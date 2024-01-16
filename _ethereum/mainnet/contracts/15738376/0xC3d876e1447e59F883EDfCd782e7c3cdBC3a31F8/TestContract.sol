// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "./AccessControlUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./TestContractStash.sol";
import "./TestContractAccessControl.sol";

contract TestContract is
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    TestContractStash
{
    address public SIGNER_ADDRESS;
    uint256 public PRICE_PER_TOKEN;
    address public TREASURY_ADDRESS;
    uint256 public MAX_SUPPLY;

    string public baseURI;

    error Ended();
    error NotStarted();
    error NotEOA();
    error MintTooManyAtOnce();
    error InvalidSignature();
    error ZeroQuantity();
    error ExceedMaxSupply();
    error ExceedAllowedQuantity();
    error NotEnoughETH();
    error TicketUsed();

    mapping(address => bool) public operatorProxies;

    function initialize(
        string memory _TOKEN_NAME,
        string memory _SYMBOL,
        string memory _BASE_URI,
        address _DEPLOYMENT_ADMIN,
        address _SIGNER_ADMIN,
        address _TREASURY_ADMIN,
        address _SIGNER,
        address _TREASURY,
        address _ROYALTY,
        uint256 _PRICE,
        uint256 _MAX_SUPPLY
    ) public initializerERC721A initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _DEPLOYMENT_ADMIN);

        _setupRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _DEPLOYMENT_ADMIN);
        _setupRole(TestContractAccessControl.ROLE_SIGNER_ADMIN, _SIGNER_ADMIN);
        _setupRole(TestContractAccessControl.ROLE_TREASURY_ADMIN, _TREASURY_ADMIN);

        __AccessControl_init();
        __ERC721A_init(_TOKEN_NAME, _SYMBOL);
        __ERC2981_init();

        _setDefaultRoyalty(_ROYALTY, 1000);

        baseURI = _BASE_URI;

        SIGNER_ADDRESS = _SIGNER;
        TREASURY_ADDRESS = _TREASURY;

        PRICE_PER_TOKEN = _PRICE;
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    modifier onlySigner() {
        require(msg.sender == SIGNER_ADDRESS, "must call by signer");
        _;
    }

    function devMint(address to, uint256 quantity) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        _mint(to, quantity);
    }

    function devMintWithPrice(address to, uint256 quantity) external payable {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");

        if (msg.value < quantity * PRICE_PER_TOKEN) {
            revert NotEnoughETH();
        }

        _mint(to, quantity);
    }

    function mint(
        uint256 quantity,
        uint256 allowedQuantity,
        uint256 startTime,
        uint256 endTime,
        bytes calldata signature
    ) external payable onlyEOA {
        if (quantity == 0) {
            revert ZeroQuantity();
        }

        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert ExceedMaxSupply();
        }


        if (quantity + _numberMinted(msg.sender) > allowedQuantity) {
            revert ExceedAllowedQuantity();
        }

        if (block.timestamp < startTime) {
            revert NotStarted();
        }

        if (block.timestamp >= endTime) {
            revert Ended();
        }

        if (msg.value < quantity * PRICE_PER_TOKEN) {
            revert NotEnoughETH();
        }

        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encodePacked(msg.sender, allowedQuantity, startTime, endTime, address(this)))
        );

        if (ECDSAUpgradeable.recover(hash, signature) != SIGNER_ADDRESS) {
            revert InvalidSignature();
        }

        _mint(msg.sender, quantity);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
            _transferCheck(tokenId);
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function approve(address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        _transferCheck(tokenId);
        super.approve(to, tokenId);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        if (operatorProxies[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function swapOperatorProxies(address _proxyAddress) public {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        operatorProxies[_proxyAddress] = !operatorProxies[_proxyAddress];
    }

    function setSigner(address signer_) external {
        require(hasRole(TestContractAccessControl.ROLE_SIGNER_ADMIN, _msgSender()), "ERR: No access.");
        SIGNER_ADDRESS = signer_;
    }

    function setTreasury(address treasury_) external {
        require(hasRole(TestContractAccessControl.ROLE_TREASURY_ADMIN, _msgSender()), "ERR: No access.");
        TREASURY_ADDRESS = treasury_;
    }

    function setBaseURI(string memory baseURI_) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        PRICE_PER_TOKEN = price_;
    }

    function setMaxSupply(uint256 maxSupply_) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        MAX_SUPPLY = maxSupply_;
    }

    function setStashEnable(bool enableStash) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        _setStashingEnable(enableStash);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        require(hasRole(TestContractAccessControl.ROLE_DEPLOY_ADMIN, _msgSender()), "ERR: No access.");
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external {
        require(hasRole(TestContractAccessControl.ROLE_TREASURY_ADMIN, _msgSender()), "ERR: No access.");
        payable(TREASURY_ADDRESS).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, ERC2981Upgradeable, IERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
