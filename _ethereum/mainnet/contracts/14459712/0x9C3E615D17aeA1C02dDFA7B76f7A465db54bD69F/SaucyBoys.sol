//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Math.sol";
import "./Strings.sol";
import "./Allowlist.sol";
import "./ERC721A.sol";
import "./cIERC20.sol";

contract SaucyBoys is ERC721A, PaymentSplitter, Ownable, AccessControl, Pausable, ReentrancyGuard, Allowlist {
    uint private maxSupply = 1869;
    uint private maxPerTx = 20;
    uint private maxPerWallet = 3; // for Allowlist

    // Metadata
    string internal _tokenURI;

    // Pricing
    uint256 public price = 0.06 ether;
    uint256 public tokenPrice = 300 ether;

    // Phases
    mapping(address => uint) private claimed;
    bool public isPublic = false;
    bool public isPreMint = false;
    uint public maxTokenMint;
    uint public maxEtherMint;
    uint private curTokenMint;
    uint private curEtherMint;

    // Proxy
    address private stakingAddress;
    address private tokenAddress;

    constructor (
        string memory tokenURI_,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A("SaucyBoys", "SB", maxPerTx)
    PaymentSplitter(payees, shares) {
        _tokenURI = tokenURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        transferOwnership(0xC8a6e81E8473feB3ae676C543531a8169832EFdC);
    }

    /**
     * @dev Public minting function
     */
    function mint(uint amount) 
        external payable 
        whenNotPaused nonReentrant {
            require(isPublic, "public mint is not open");
            require(amount <= maxPerTx, "amount too big");
            require(msg.value == price * amount, "insufficient fund");
            require(curEtherMint + amount <= maxEtherMint, "exceed current max ether mint");

            curEtherMint += amount;
            
            _mint(msg.sender, amount);
    }

    /**
     * @dev Whitelist minting function, requires signature
     */
    function preMint(uint amount, bytes32[] calldata proof) 
        external payable 
        onlyAllowed(proof) whenNotPaused nonReentrant {
            require(isPreMint, "pre mint is not open");
            require(claimed[msg.sender] + amount <= maxPerWallet, "exceed mint quota");
            require(msg.value == price * amount, "insufficient fund");
            require(curEtherMint + amount <= maxEtherMint, "exceed current max ether mint");

            curEtherMint += amount;
            claimed[msg.sender] += amount;

            _mint(msg.sender, amount);
    }

    /**
     * @dev Token minting, requires ERC20 token $CONDIMENT
     */
    function tokenMint(uint amount) 
        external 
        whenNotPaused nonReentrant {
            cIERC20 token = cIERC20(tokenAddress);
            require(tokenAddress != address(0), "token mint not open");
            require(curTokenMint + amount <= maxTokenMint, "exceed current max token mint");
            require(amount <= maxPerTx, "amount too big");
            require(token.balanceOf(msg.sender) >= tokenPrice * amount, "insufficient token");
            require(balanceOf(msg.sender) > 0, "need to be a holder");

            curTokenMint += amount;

            token.burnFrom(msg.sender, tokenPrice * amount);
            _mint(msg.sender, amount);
    }

    function _mint(address to, uint amount) internal {
        uint supply = totalSupply();
        require(to != address(0), "empty address");
        require(amount > 0, "amount too little");
        require(supply + amount <= maxSupply, "exceed max supply");

        _safeMint(to, amount);
    }

    /**
     * @dev Admin only airdrop function
     */
    function airdrop(address wallet, uint256 amount) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
            _mint(wallet, amount);
    }

    function owned(address owner) 
        external view 
        returns (uint256[] memory) {
        uint balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for(uint i = 0; i < balance; i++){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // Pausable
    function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = amount;
    }

    function setMaxPerWallet(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerWallet = amount;
    }

    function setMaxPerTx(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerTx = amount;
    }

    // Minting fee
    function setPrice(uint amount) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        price = amount;
    }
    function claim() external {
        release(payable(msg.sender));
    }

    // Allowlist
    function setMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMerkleRoot(root);
    }

    function setPublic(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = value;
    }
    function setPreMint(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPreMint = value;
    }
    function setMaxTokenMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTokenMint = amount;
    }
    function setMaxEtherMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxEtherMint = amount;
    }

    // Metadata
    function setTokenURI(string calldata _uri) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenURI = _uri;
    }
    function baseTokenURI() 
        external view 
        returns (string memory) {
        return _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) 
        public view override 
        returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    // Proxy
    function setStakingAddress(address addr) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingAddress = addr;
    }
    function setTokenAddress(address addr) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddress = addr;
    }

    function isApprovedForAll(address owner, address operator)
        public view virtual override
        returns (bool) {
        return super.isApprovedForAll(owner, operator) 
        || (stakingAddress != address(0) && operator == stakingAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
