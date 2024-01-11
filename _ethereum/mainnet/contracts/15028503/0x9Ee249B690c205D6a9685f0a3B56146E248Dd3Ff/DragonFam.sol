//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract DragonFam is ERC721A, Ownable, ReentrancyGuard, Pausable {
    event SaleStateChange(uint256 _newState);
    event PriceChange(uint256 _newPrice);

    using Strings for uint256;
    uint256 public maxTokens = 6666;
    uint256 public price = 0.0325 ether;
    uint256 public maxPerWallet = 5;

    string private baseURI;
    string public notRevealedJson =
        "ipfs://QmeTpdw2URmck75NYwAArycsu4gN7qAP3z5sutwjSXMZZH/";

    bool public revealed;

    enum SaleState {
        NOT_ACTIVE,
        PRESALE,
        PUBLIC_SALE
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    struct WhitelistRole {
        bytes32 merkleRoot;
        uint256 freeMints;
        uint256 mintPrice;
        uint256 maxPerWallet;
    }

    WhitelistRole mythicalWizard;
    WhitelistRole legendaryWizard;
    WhitelistRole powerfulWizard;
    WhitelistRole verifiedWizard;
    WhitelistRole regularWizard;

    mapping(address => uint256) public mintedOnPublicSale;
    mapping(address => uint256) public mintedOnPresale;

    bytes32 OGMerkleRoot;

    constructor() ERC721A("Dragon Fam Genesis", "DRAGON") {
        // Mythical Wizards
        mythicalWizard.freeMints = 3;
        mythicalWizard.mintPrice = 0.015 ether;
        mythicalWizard.maxPerWallet = 10;
        // Legendary Wizards
        legendaryWizard.freeMints = 2;
        legendaryWizard.mintPrice = 0.0225 ether;
        legendaryWizard.maxPerWallet = 10;
        // Powerful Wizards
        powerfulWizard.freeMints = 1;
        powerfulWizard.mintPrice = 0.025 ether;
        powerfulWizard.maxPerWallet = 10;
        // Verified Wizards
        verifiedWizard.mintPrice = 0.025 ether;
        verifiedWizard.maxPerWallet = 7;
        // Regular whitelist
        regularWizard.mintPrice = 0.0275 ether;
        regularWizard.maxPerWallet = 5;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        return (
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            )
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return
            string(
                abi.encodePacked(notRevealedJson, tokenId.toString(), ".json")
            );
    }

    receive() external payable {}

    function getWizardRoleMemory(uint256 _role)
        internal
        view
        returns (WhitelistRole memory)
    {
        if (_role == 0) {
            return mythicalWizard;
        } else if (_role == 1) {
            return legendaryWizard;
        } else if (_role == 2) {
            return powerfulWizard;
        } else if (_role == 3) {
            return verifiedWizard;
        } else if (_role == 4) {
            return regularWizard;
        } else {
            revert("Invalid role!");
        }
    }

    function getWizardRoleStorage(uint256 _role)
        internal
        view
        returns (WhitelistRole storage)
    {
        if (_role == 0) {
            return mythicalWizard;
        } else if (_role == 1) {
            return legendaryWizard;
        } else if (_role == 2) {
            return powerfulWizard;
        } else if (_role == 3) {
            return verifiedWizard;
        } else if (_role == 4) {
            return regularWizard;
        } else {
            revert("Invalid role!");
        }
    }

    function whitelistMint(
        uint256 _amount,
        uint256 _role,
        bytes32[] calldata _merkleProof,
        bytes32[] calldata _OGMerkleProof
    ) external payable nonReentrant whenNotPaused {
        require(saleState == SaleState.PRESALE, "Presale is not active!");
        WhitelistRole memory wizardRole = getWizardRoleMemory(_role);
        require(
            isValidMerkleProof(_merkleProof, wizardRole.merkleRoot),
            "Not whitelisted!"
        );
        if (_OGMerkleProof.length > 0) {
            require(
                isValidMerkleProof(_OGMerkleProof, OGMerkleRoot),
                "OG merkle proof invalid!"
            );
            wizardRole.maxPerWallet++;
        }
        require(
            mintedOnPresale[msg.sender] + _amount <= wizardRole.maxPerWallet,
            "Not enough mints remaining!"
        );
        uint256 initialPrice = wizardRole.mintPrice * _amount;
        uint256 totalPrice;
        if (wizardRole.freeMints <= mintedOnPresale[msg.sender]) {
            totalPrice = initialPrice;
        } else {
            uint256 freeMintDiscount = (wizardRole.freeMints -
                mintedOnPresale[msg.sender]) * wizardRole.mintPrice;
            if (initialPrice > freeMintDiscount) {
                totalPrice = initialPrice - freeMintDiscount;
            }
        }
        require(msg.value >= totalPrice, "Not enough ETH!");
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        mintedOnPresale[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            mintedOnPublicSale[msg.sender] + _amount <= maxPerWallet,
            "Not enough mints remaining!"
        );
        require(saleState == SaleState.PUBLIC_SALE, "Public sale not active!");
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        require(msg.value >= price * _amount, "Not enough ETH!");
        mintedOnPublicSale[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function freeMint(uint256 _amount) external onlyOwner {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        _safeMint(address(0x6194b0326E0960010680453e3Ef014829999d6c1), _amount);
    }

    // Only owner functions

    function setSaleState(uint256 _state) external onlyOwner {
        if (_state == 0) {
            saleState = SaleState.NOT_ACTIVE;
        } else if (_state == 1) {
            saleState = SaleState.PRESALE;
        } else if (_state == 2) {
            saleState = SaleState.PUBLIC_SALE;
        }
        emit SaleStateChange(_state);
    }

    function updateOGWhitelistMerkleRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        OGMerkleRoot = _merkleRoot;
    }

    function updateWhitelistMerkleRoot(bytes32 _merkleRoot, uint256 _role)
        external
        onlyOwner
    {
        WhitelistRole storage wizardRole = getWizardRoleStorage(_role);
        wizardRole.merkleRoot = _merkleRoot;
    }

    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed!");
    }

    function revealTokens(string calldata _ipfsCID) external onlyOwner {
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        revealed = true;
    }

    function updateNotRevealedJson(string calldata _ipfsCID) external onlyOwner {
        notRevealedJson = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
