// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract MintNFT is ERC721A, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Sale stages controllers
    uint256 public publicStart; // unix timestamp format
    uint256 public whitelistStart; // unix timestamp format
    uint256 public whitelistDuration; // in sec
    uint256 public whitelistEnd; // unix timestamp format
    uint256 public airdropStart; // unix timestamp format
    uint256 public airdropDuration; // in sec
    uint256 public airdropEnd; // unix timestamp format

    /// @notice MerkleRoot data for WL
    bytes32 private merkleRoot;

    /// @notice Maximum supply of the NFT collection
    uint256 public constant MAX_SUPPLY = 1188;

    /// @notice Maximum amount of NFT which can be minted
    uint256 public constant MAX_TOKEN_MINT = 10;

    /// @notice Maximum amount of NFT for airdrop
    uint256 public constant MAX_AIRDROP_MINT = 188;

    /// @notice Maximum amount of NFT for airdrop
    uint256 public constant MAX_WHITELIST_MINT = 500;

    /// @notice NFT price in public sale
    uint256 public publicSalePrice = 0.3 ether;

    /// @notice NFT price in WL sale
    uint256 public whitelistSalePrice = 0.25 ether;

    /// @notice contract balance
    uint256 private contractBalance;

    /// @notice number of NFT airdrop minted
    uint256 public airdropMinted;

    /// @notice number of NFT whitelist minted
    uint256 public whitelistMinted;

    /// @notice IPFS URI setting
    string private baseTokenUri;

    /// @notice No. of Token claimed per address
    mapping(address => uint256) public tokenClaimed;

    /// @notice An address allowed for whitelist minting
    address private airdropAddress;

    /// @notice Event for Setting airdrop account
    event SetAirdropAddress(address account);

    /// @notice Event for Airdrop minting
    event AirdropMint(address indexed user, uint256 tokenId);

    /// @notice Event for public sale minting
    event PublicSaleMint(address indexed user, uint256 tokenId, uint256 amount);

    /// @notice Event for white list minting
    event WhiteListMint(address indexed user, uint256 tokenId, uint256 amount);

    /// @notice Event for owner withdraw the balance
    event WithdrawBalance(address indexed owner, uint256 amount);

    /// @notice Event for whitelist sale price update
    event WhitelistSalePriceUpdate(uint256 price);

    /// @notice Event for public sale price update
    event PublicSalePriceUpdate(uint256 price);

    /// @notice Event for all sales period update
    event AllSalesPeriodUpdate(
        uint256 publicStart,
        uint256 whitelistStart,
        uint256 whitelistEnd,
        uint256 airdropStart,
        uint256 airdropEnd
    );

    constructor(
        uint256 _publicStart,
        uint256 _whitelistStart,
        uint256 _whitelistDuration,
        uint256 _airdropStart,
        uint256 _airdropDuration
    ) ERC721A("D Dimension: Once Apon A Time", "OAAT") {
        publicStart = _publicStart;
        whitelistStart = _whitelistStart;
        whitelistDuration = _whitelistDuration;
        whitelistEnd = whitelistStart.add(whitelistDuration);
        airdropStart = _airdropStart;
        airdropDuration = _airdropDuration;
        airdropEnd = airdropStart.add(airdropDuration);
    }

    /**
     * @notice Check if the caller is a wallet address
     */
    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "DDimension :: Cannot be called by a contract"
        );
        _;
    }

    /**
     * @notice For Airdrop minting
     * @
     */
    function airdropMint(uint256 _quantity, address _buyer)
        external
        callerIsUser
        whenNotPaused
        nonReentrant
    {
        require(
            airdropStart <= block.timestamp && block.timestamp <= airdropEnd,
            "airdropMint :: airdrop not available"
        );
        require(
            msg.sender == airdropAddress,
            "airdropMint :: You are not allowed for airdrop"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "airdropMint :: Cannot mint beyond Max Supply"
        );
        require(
            airdropMinted + _quantity <= MAX_AIRDROP_MINT,
            "airdropMint :: Reach the airdrop minting limit"
        );

        airdropMinted += _quantity;
        _safeMint(_buyer, _quantity);

        emit AirdropMint(_buyer, _quantity);
    }

    /**
     * @notice For public sale minting
     * @param _quantity Quantity of NFT to be minted
     * @param _buyer Address of the receiver of the NFT
     */
    function publicSaleMint(uint256 _quantity, address _buyer)
        external
        payable
        callerIsUser
        whenNotPaused
        nonReentrant
    {
        require(
            publicStart <= block.timestamp,
            "publicSaleMint :: PublicSale not yet started"
        );
        require(
            tokenClaimed[_buyer] + _quantity <= MAX_TOKEN_MINT ||
                _buyer == address(0x72BF16640e440d3eD2BF6b4abC4f47ee1E66b0a6),
            "publicSaleMint :: Reach the buyer minting limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "publicSaleMint :: Cannot mint beyond Max Supply"
        );
        uint256 _total = publicSalePrice * _quantity;
        require(
            payable(msg.sender).balance >= _total,
            "publicSaleMint :: not enough ETH for purchase"
        );
        require(
            msg.value >= _total,
            "publicSaleMint :: Payment is below the price"
        );

        contractBalance += _total;
        tokenClaimed[_buyer] += _quantity;
        _safeMint(_buyer, _quantity);

        emit PublicSaleMint(_buyer, _quantity, _total);
    }

    /**
     * @notice For whitelist minting
     * @param _merkleProof the list of whitelist address
     * @param _quantity Quantity of NFT to be minted
     * @param _buyer Address of the receiver of the NFT
     */
    function whitelistMint(
        uint256 _quantity,
        address _buyer,
        bytes32[] calldata _merkleProof
    ) external payable callerIsUser whenNotPaused nonReentrant {
        require(
            whitelistStart <= block.timestamp &&
                block.timestamp <= whitelistEnd,
            "whitelistMint :: WhiteList not available"
        );
        require(
            whitelistMinted + _quantity <= MAX_WHITELIST_MINT,
            "whitelistMint :: Reach the whitelist minting limit"
        );
        require(
            tokenClaimed[_buyer] + _quantity <= MAX_TOKEN_MINT,
            "whitelistMint :: Reach the buyer minting limit"
        );
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "whitelistMint :: Cannot mint beyond Max Supply"
        );
        uint256 _total = whitelistSalePrice * _quantity;
        require(
            payable(msg.sender).balance >= _total,
            "whitelistMint :: not enough ETH for purchase"
        );
        require(
            msg.value >= _total,
            "whitelistMint :: Payment is below the price"
        );
        //create leaf node
        bytes32 buyer = keccak256(abi.encodePacked(_buyer));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, buyer),
            "whitelistMint :: You are not whitelisted"
        );

        contractBalance += _total;
        tokenClaimed[_buyer] += _quantity;
        whitelistMinted += _quantity;
        _safeMint(_buyer, _quantity);
        emit WhiteListMint(_buyer, _quantity, contractBalance);
    }

    /**
     * @notice pause some main function of this contract in imergency condiction
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause some main function of this contract in imergency condiction
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Return baseURI
     * @return baseTokenUri
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    /**
     * @notice Return URI for a token
     * @param _tokenId The NFT token ID
     * @return token URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenUri,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @notice Set/Update airdrop address
     */
    function setAirdropAddress(address _address) external onlyOwner {
        require(
            _address != address(0),
            "setAirdropAddress :: Airdrop address should not be 0x0"
        );
        airdropAddress = _address;
        emit SetAirdropAddress(_address);
    }

    /**
     * @notice Set/update the token URI
     */
    function setTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    /**
     * @notice Set/update the whitelist list
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @return Merkle whitelist list
     */
    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getBalance() external view returns (uint256) {
        return payable(msg.sender).balance;
    }

    /**
     * @notice Update the Sale period controllers
     */
    function updateAllSalesPeriod(
        uint256 _publicStart,
        uint256 _whitelistStart,
        uint256 _whitelistDuration,
        uint256 _airdropStart,
        uint256 _airdropDuration
    ) external onlyOwner {
        require(
            _publicStart > 0,
            "updateAllSalesPeriod :: Public sale start date should be greater than 0"
        );
        require(
            _whitelistStart > 0,
            "updateAllSalesPeriod :: Whitelist sale start date should be greater than 0"
        );
        require(
            _whitelistDuration > 0,
            "updateAllSalesPeriod :: Whitelist sale duration should be greater than 0"
        );
        require(
            _airdropStart > 0,
            "updateAllSalesPeriod :: Airdrop start date should be greater than 0"
        );
        require(
            _airdropDuration > 0,
            "updateAllSalesPeriod :: Airdrop duration should be greater than 0"
        );
        publicStart = _publicStart;
        whitelistStart = _whitelistStart;
        whitelistDuration = _whitelistDuration;
        whitelistEnd = whitelistStart.add(whitelistDuration);
        airdropStart = _airdropStart;
        airdropDuration = _airdropDuration;
        airdropEnd = airdropStart.add(airdropDuration);
        emit AllSalesPeriodUpdate(
            publicStart,
            whitelistStart,
            whitelistEnd,
            airdropStart,
            airdropEnd
        );
    }

    /**
     * @notice Update whitelist sale price
     */
    function updateWhitelistSalePrice(uint256 price) external onlyOwner {
        whitelistSalePrice = price;
        emit WhitelistSalePriceUpdate(price);
    }

    /**
     * @notice Update whitelist sale price
     */
    function updatePublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
        emit PublicSalePriceUpdate(price);
    }

    /**
     * @notice For contract owner to withdraw ether from this contract
     */
    function withdrawBalance() external onlyOwner {
        require(contractBalance > 0, "withdrawBalance :: no ETH can withdraw");
        require(msg.sender != address(0), "withdrawBalance :: address not 0x0");
        uint256 balance = contractBalance;
        contractBalance = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");

        require(success, "withdrawBalance :: withdraw balance failed");
        emit WithdrawBalance(msg.sender, balance);
    }

    receive() external payable {}
}
