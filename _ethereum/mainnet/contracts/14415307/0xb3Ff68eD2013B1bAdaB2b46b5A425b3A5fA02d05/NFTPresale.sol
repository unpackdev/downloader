// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

import "./NFTMintable.sol";

contract NFTPresale is Ownable {
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32[];

    enum SaleState {
        Paused,
        PrivateSale,
        WhitelistSale,
        PublicSale,
        Reveal
    }

    // current state
    SaleState public state = SaleState.Paused;

    // nft max supply
    uint16 public maxSupply = 4200;

    // one nft price static
    uint256 public purchasePrice = 0.09 ether;

    // walletAddress where funds are forwarded
    address public walletAddress = 0x01C92E523EeAab2c78f0E6B203C3867fF39b7463;

    // private merkle root used below
    bytes32 privateMerkleRoot;

    // counter sold NFTs per address on private stage
    mapping(address => uint8) public privateSoldCount;

    // whitelist merkle root used below
    bytes32 whitelistMerkleRoot;

    // maximum quantity of NFTs to sell on whitelist per address, can be changed by owner
    uint8 public whitelistMaxSalePerAddr;

    // counter sold NFTs per address on whitelist stage
    mapping(address => uint8) public whitelistSoldCount;

    // maximum quantity of NFTs to sell on publicSale per address, can be changed by owner
    uint8 public publicMaxSalePerAddr;

    // counter sold NFTs per address on publicSale stage
    mapping(address => uint8) public publicSoldCount;

    // counter softly minted, sold NFTS
    mapping(address => uint8) public softMinted;

    uint16 public soldCount;

    NFTMintable public NFT;

    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);

    event PresaleMint(
        address minter,
        uint8 numberOfTokensMinted,
        bool hardMinted,
        SaleState state
    );

    constructor(
        address _NFT,
        bytes32 _privateMerkleRoot,
        bytes32 _whitelistMerkleRoot,
        uint8 _whitelistMaxSalePerAddr,
        uint8 _publicMaxSalePerAddr
    ) {
        NFT = NFTMintable(_NFT);

        privateMerkleRoot = _privateMerkleRoot;
        whitelistMerkleRoot = _whitelistMerkleRoot;

        whitelistMaxSalePerAddr = _whitelistMaxSalePerAddr;
        publicMaxSalePerAddr = _publicMaxSalePerAddr;
    }

    modifier whenSalePaused() {
        require(
            state == SaleState.Paused,
            "You can not perform action when contract is not on Paused state"
        );
        _;
    }

    modifier atState(SaleState _state) {
        require(state == _state, "Wrong state. Action not allowed.");
        _;
    }

    /// @dev Returns if given address is memeber of private list
    /// @param proof - Merkle proof of @param addr
    /// @param addr - Target address
    /// @return verification status (boolean)
    function isPrivateUser(bytes32[] memory proof, address addr)
        public
        view
        returns (bool)
    {
        return
            proof.verify(privateMerkleRoot, keccak256(abi.encodePacked(addr)));
    }

    /// @dev Returns if given address is memeber of private list
    /// @param proof - Merkle proof of @param addr
    /// @param addr - Target address
    /// @return verification status (boolean)
    function isWhitelisted(bytes32[] memory proof, address addr)
        public
        view
        returns (bool)
    {
        return
            proof.verify(
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(addr))
            );
    }

    /// Pause sale.
    function pauseSale() external onlyOwner {
        state = SaleState.Paused;
    }

    /// @dev recovers ERC20 tokens if contract has it accidentally
    /// @param tokenAddress - Address of a contract implementing IERC20 interface
    /// @param tokenAmount - Amount of token which are property of current contract
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    /// @dev Recovers a ERC721(NFT) token if the contract has it accidentally
    /// @param tokenAddress - Address of a contract implementing IERC721 interface.
    /// @param tokenId - ID of token which is property of the current contract
    function recoverERC721(address tokenAddress, uint256 tokenId)
        external
        onlyOwner
    {
        IERC721(tokenAddress).safeTransferFrom(address(this), owner(), tokenId);
        emit RecoveredERC721(tokenAddress, tokenId);
    }

    /// @dev Change merkle root to update current private list
    /// @dev Contract owner should calculate new merkle root before setting
    /// @param _root - New merkle root which is calculated in advanced
    function setPrivateMerkleRoot(bytes32 _root)
        external
        onlyOwner
        whenSalePaused
    {
        privateMerkleRoot = _root;
    }

    /// @dev Change merkle root to update current whitelist
    /// @dev Contract owner should calculate new merkle root before setting
    /// @param _root - New merkle root which is calculated in advanced
    function setWhitelisteMerkleRoot(bytes32 _root)
        external
        onlyOwner
        whenSalePaused
    {
        whitelistMerkleRoot = _root;
    }

    function setWalletAddress(address _walletAddress)
        external
        onlyOwner
        returns (bool)
    {
        walletAddress = _walletAddress;
        return true;
    }

    function setPurchasePrice(uint256 _purchasePrice)
        external
        onlyOwner
        whenSalePaused
        returns (bool)
    {
        require(_purchasePrice > 0, "Invalid price");
        purchasePrice = _purchasePrice;
        return true;
    }

    function setWhitelistMaxSalePerAddr(uint8 _whitelistMaxSalePerAddr)
        external
        onlyOwner
        whenSalePaused
        returns (bool)
    {
        whitelistMaxSalePerAddr = _whitelistMaxSalePerAddr;
        return true;
    }

    function setPublicMaxSalePerAddr(uint8 _publicMaxSalePerAddr)
        external
        onlyOwner
        whenSalePaused
        returns (bool)
    {
        publicMaxSalePerAddr = _publicMaxSalePerAddr;
        return true;
    }

    function setMaxSupply(uint16 _maxSupply)
        external
        onlyOwner
        whenSalePaused
        returns (bool)
    {
        require(
            soldCount <= _maxSupply,
            "More than or equal to soldCount allowed"
        );
        maxSupply = _maxSupply;

        return true;
    }

    /// Start Whitelist Sale
    function startPrivateSale() external onlyOwner {
        state = SaleState.PrivateSale;
    }

    /// Start Whitelist Sale
    function startWhitelistSale() external onlyOwner {
        state = SaleState.WhitelistSale;
    }

    /// Start public Sale
    function startPublicSale() external onlyOwner {
        state = SaleState.PublicSale;
    }

    /// Start Reveal
    function startReveal() external onlyOwner {
        state = SaleState.Reveal;
    }

    function reclaimFunds() external onlyOwner {
        assert(payable(walletAddress).send(address(this).balance));
    }

    /// @dev Mint NFT while state is PrivateSale
    /// @dev Sender will be checked via merkle tree to find out if sender is private member
    /// @dev Sender can soft mint to save in local storage for saving gases or hard mint to call NFT contract
    /// @param proof - Proof of merkle tree to verify sender's status
    function mintNFTInPrivateSale(bytes32[] memory proof) external {
        require(state == SaleState.PrivateSale, "Minting not allowed");

        address buyer = _msgSender();

        require(
            isPrivateUser(proof, _msgSender()),
            "Address is not member of private sale"
        );

        require(
            privateSoldCount[buyer] == 0,
            "More than max allowed in private for this address"
        );

        require(soldCount + 1 <= maxSupply, "More than max supply allowed");

        privateSoldCount[buyer] += 1;
        soldCount += 1;

        NFT.mintTo(_msgSender(), 1);

        emit PresaleMint(buyer, 1, true, state);
    }

    /// @dev Mint NFT while state is WhitelistSale
    /// @dev Sender will be checked via merkle tree to find out if sender is whitelisted
    /// @dev Sender can soft mint to save in local storage for saving gases or hard mint to call NFT contract
    /// @param numberOfTokens - How many tokens to mint
    /// @param hardMint - soft/hard minting
    /// @param proof - Proof of merkle tree to verify sender's status
    function mintNFTInWhitelistSale(
        uint8 numberOfTokens,
        bool hardMint,
        bytes32[] memory proof
    ) external payable {
        require(state == SaleState.WhitelistSale, "Minting not allowed");

        address buyer = _msgSender();
        uint256 value = msg.value;

        require(purchasePrice * numberOfTokens <= value, "Not enough Funds");

        require(isWhitelisted(proof, _msgSender()), "Address not whitelisted");

        require(
            whitelistSoldCount[buyer] + numberOfTokens <=
                whitelistMaxSalePerAddr,
            "More than max allowed in whitelist for this address"
        );

        require(
            soldCount + numberOfTokens <= maxSupply,
            "More than max supply allowed"
        );

        whitelistSoldCount[buyer] += numberOfTokens;
        soldCount += numberOfTokens;

        if (hardMint) {
            NFT.mintTo(_msgSender(), numberOfTokens);
        } else {
            softMinted[_msgSender()] += numberOfTokens;
        }

        emit PresaleMint(buyer, numberOfTokens, hardMint, state);
    }

    /// @dev Mint NFT while state is PublicSale
    /// @dev Sender can soft mint to save in local storage for saving gases or hard mint to call NFT contract
    /// @param numberOfTokens - How many tokens to mint
    /// @param hardMint - soft/hard minting
    function mintNFTInPublicSale(uint8 numberOfTokens, bool hardMint)
        external
        payable
    {
        require(state == SaleState.PublicSale, "Minting not allowed");

        address buyer = _msgSender();
        uint256 value = msg.value;

        require(purchasePrice * numberOfTokens <= value, "Not enough Funds");

        require(
            publicSoldCount[buyer] + numberOfTokens <= publicMaxSalePerAddr,
            "More than max allowed in public sale for this address"
        );

        require(
            soldCount + numberOfTokens <= maxSupply,
            "More than max supply allowed"
        );

        publicSoldCount[buyer] += numberOfTokens;
        soldCount += numberOfTokens;

        if (hardMint) {
            NFT.mintTo(_msgSender(), numberOfTokens);
        } else {
            softMinted[_msgSender()] += numberOfTokens;
        }

        emit PresaleMint(buyer, numberOfTokens, hardMint, state);
    }

    function mint(uint8 numberOfTokens) external {
        require(
            softMinted[_msgSender()] >= numberOfTokens,
            "Not soft minted NFTs for sender"
        );

        softMinted[_msgSender()] -= numberOfTokens;

        NFT.mintTo(_msgSender(), numberOfTokens);
    }
}
