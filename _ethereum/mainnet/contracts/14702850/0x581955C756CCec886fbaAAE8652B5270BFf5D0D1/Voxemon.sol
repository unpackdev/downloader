// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**************************************************
 * Voxemon
 * Developed By: Absolabs.xyz / @sbmitchell.eth
 **************************************************/

contract Voxemon is ERC721A, Ownable {
    string constant NAME = "Voxemon";
    string constant SYMBOL = "VXM";
    address private DEV_ADDRESS = 0xEDC0f30D965476921359c055821411fC3C3f3e75;

    address public proxyRegistryAddress;
    address public treasury;
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    uint256 public maxMintPerTx = 4;
    string public baseURI = "";
    string public fileExtensionType = ".json";
    uint256 public wlAllowance = 1;
    uint256 public priceInWei = 0.1 ether;
    bool public isRevealed = false;
    bool public isSaleActive = false;
    bool public hasCollected = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor(
        string memory hiddenBaseURI,
        address _proxyRegistryAddress,
        address _treasury
    ) ERC721A(NAME, SYMBOL) {
        baseURI = hiddenBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        treasury = payable(_treasury);
    }

    /** PUBLIC FUNCTIONS **/

    /** Owner Pre-mint  **/
    function ownerPreMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    /** Public **/
    function publicMint(uint256 quantity) public payable {
        require(isSaleActive, "0");
        require(quantity < maxMintPerTx, "1");
        require(totalSupply() + quantity < maxSupply, "2");
        require(quantity * priceInWei == msg.value, "3");
        _safeMint(msg.sender, quantity);
    }

    /** Whitelist **/
    function whitelistMint(uint256 quantity, bytes32[] calldata proof)
        public
        payable
    {
        require(isSaleActive, "0");
        require(quantity * priceInWei == msg.value, "3");
        require(addressToMinted[msg.sender] + quantity <= wlAllowance, "6");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                leaf(msg.sender, Strings.toString(wlAllowance))
            ),
            "5"
        );
        addressToMinted[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "404");

        string memory currentBaseURI = _baseURI();

        if (bytes(currentBaseURI).length == 0) {
            return "";
        }

        return
            isRevealed == true
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        fileExtensionType
                    )
                )
                : string(
                    abi.encodePacked(
                        currentBaseURI,
                        "hidden",
                        fileExtensionType
                    )
                );
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );

        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    /** INTERNAL **/
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function leaf(address _address, string memory allowance)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(string(abi.encodePacked(_address)), allowance)
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /** OWNER FUNCTIONS **/

    /// @notice Sets the whitelist cap
    function setWhitelistAllowance(uint256 _wlAllowance) external onlyOwner {
        wlAllowance = _wlAllowance;
    }

    /// @notice Sets the max mint per transaction
    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    /// @notice Sets the price in wei
    function setPriceInWei(uint256 _priceInWei) external onlyOwner {
        priceInWei = _priceInWei;
    }

    /// @notice Sets the base URI for metadata
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Sets the file extension type, defaults to .json
    function setFileExtensionType(string memory _fileExtensionType)
        external
        onlyOwner
    {
        fileExtensionType = _fileExtensionType;
    }

    /// @notice Sets a new treasury address
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    /// @notice Toggles the sale state from active and inactive
    function toggleSaleActive() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /// @notice Starts the public sale with a given `maxSupply`
    function togglePublicSale(uint256 _maxSupply) external onlyOwner {
        delete merkleRoot;
        maxSupply = _maxSupply;
    }

    /// @notice Toggles the reveal
    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    /// @notice Sets up a proxy registry
    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /// @notice Sets up the whitelist merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Toggles a proxy address permission set
    function flipProxyState(address proxyAddress) external onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    /// @notice Processes the withdraw request
    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool s1, ) = payable(treasury).call{value: (amount * 90) / 100}("");
        (bool s2, ) = payable(DEV_ADDRESS).call{value: (amount * 10) / 100}("");

        if (s1 && s2) return;

        // fallback to paying all to treasury
        (bool s3, ) = treasury.call{value: amount}("");

        require(s3, "Withdrawal failed");
    }
}
