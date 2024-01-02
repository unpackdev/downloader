// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";

interface IDelegationRegistry {
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights) external view returns (uint256);
}

interface IaKEYcalledBEAST {
    function unlock(uint256 cardId, uint256 amount, address adr) external;
}

contract BitBeast is Initializable, ERC721Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private currentSupply;

    string public baseURI;
    address public keyAdr;
    bool public hasClaimStarted;

    // BEAST List Minting
    uint public CURR_MINT_COST;
    bytes32 private verificationHash;
    bool public beastListStarted;
    mapping(address => uint32) public _walletsMinted;

    uint private initialSetupRun;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("BITBEAST", "BIT");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        baseURI = "";
        hasClaimStarted = false;
        keyAdr = 0xbe86f8d47A20b4461BA1C30d470779115912FF58;
        CURR_MINT_COST = 0 ether;
        beastListStarted = false;
        initialSetupRun = 0;
    }

    // OpenSea Operator Filter Registry Functions https://github.com/ProjectOpenSea/operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint) {
        return currentSupply;
    }

    function mintNft(uint256 amount, address vault) external {
        require(hasClaimStarted, "Claim hasn't started yet.");

        if (vault != msg.sender) {
            IDelegationRegistry delegateO = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

            if (!delegateO.checkDelegateForToken(msg.sender, vault, keyAdr, 1)) {
                IDelegationRegistry delegateT = IDelegationRegistry(0x00000000000000447e69651d841bD8D104Bed493);

                require(delegateT.checkDelegateForERC1155(msg.sender, vault, keyAdr, 1, "") >= amount, "Not owner of claim.");
            }
        }

        IaKEYcalledBEAST(keyAdr).unlock(1, amount, vault);

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(vault, currentSupply + i + 1);
        }

        currentSupply = currentSupply + amount;
    }

    function initialSetup() external onlyOwner {
        require(!hasClaimStarted, "Claim has already started");
        require(initialSetupRun == 0, "Initial setup has already been run.");

        _safeMint(owner(), 0);

        initialSetupRun = 1;
    }

    function completeSetup() external onlyOwner {
        require(!hasClaimStarted, "Claim has already started");
        require(initialSetupRun == 1, "Initial setup has not run yet.");

        _burn(0);

        initialSetupRun = 2;
    }

    function airdrop(address[] memory adrs) external onlyOwner {
        require(adrs.length > 0, "At least one address is required to airdrop");

        for (uint256 i = 0; i < adrs.length; i++) {
            _safeMint(adrs[i], currentSupply + i + 1);
        }

        currentSupply = currentSupply + adrs.length;
    }

    function mintBeastList (bytes32[] memory proof) external payable {
        require(msg.value >= CURR_MINT_COST, "Insufficient funds");
        require(beastListStarted, "BEAST List minting has not started yet.");
        require((_walletsMinted[msg.sender]) == 0, "Max per address exceeded.");

        bytes32 user = keccak256(abi.encodePacked(msg.sender));
        require(verify(user, proof), "User is not beast listed.");

        _walletsMinted[msg.sender]++;

        _safeMint(msg.sender, currentSupply + 1);
        currentSupply = currentSupply + 1;
    }

    function verify (bytes32 user, bytes32[] memory proof) internal view returns (bool) {
        bytes32 computedHash = user;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == verificationHash;
    }

    function setBeastListMinting(bytes32 _hash, uint cost, bool started) external onlyOwner {
        verificationHash = _hash;
        CURR_MINT_COST = cost;
        beastListStarted = started;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setClaimStarted(bool _state) external onlyOwner {
        hasClaimStarted = _state;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
