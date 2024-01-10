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
 * Wavy Shark Society

                     ^`.                     o
     ^_              \  \                  o  o
     \ \             {   \                 o
     {  \           /     `~~~--__
     {   \___----~~'              `~~-_     ______          _____
      \                         /// a  `~._(_||___)________/___
      / /~~~~-, ,__.    ,      ///  __,,,,)      o  ______/    \
      \/      \/    `~~~;   ,---~~-_`~= \ \------o-'            \
                       /   /            / /
                      '._.'           _/_/
                                      ';|\

 * Developed By: @sbmitchell.eth
 **************************************************/

contract WavySharkSociety is ERC721A, Ownable {
    string constant NAME = "Wavy Shark Society";
    string constant SYMBOL = "Wavy Shark Society";
    string private constant WL_ALLOWANCE = "5";
    uint256 public constant MAX_PER_TX = 11;
    uint256 private constant RESERVES_TO_MINT = 222;

    address private DEV_ADDRESS = 0xEDC0f30D965476921359c055821411fC3C3f3e75;
    address public proxyRegistryAddress;
    address public treasury;
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    string public baseURI = "";
    string public fileExtensionType = ".json";
    bool public isRevealed = false;
    bool public isSaleActive = false;
    bool public hasCollected = false;
    uint256 public priceInWei = 0.15 ether;

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

    /** Public **/
    function publicMint(uint256 quantity) public payable {
        require(isSaleActive, "0");
        require(quantity < MAX_PER_TX, "1");
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
        require(addressToMinted[msg.sender] + quantity <= 5, "6");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                leaf(msg.sender, WL_ALLOWANCE)
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
    function setPriceInWei(uint256 _priceInWei) external onlyOwner {
        priceInWei = _priceInWei;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFileExtensionType(string memory _fileExtensionType)
        external
        onlyOwner
    {
        fileExtensionType = _fileExtensionType;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    function toggleSaleActive() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function togglePublicSale(uint256 _maxSupply) external onlyOwner {
        delete merkleRoot;
        maxSupply = _maxSupply;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function collectReserves() external onlyOwner {
        require(!hasCollected, "999");
        _safeMint(msg.sender, RESERVES_TO_MINT);
        hasCollected = true;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function flipProxyState(address proxyAddress) external onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool s1, ) = payable(treasury).call{value: (amount * 95) / 100}("");

        (bool s2, ) = payable(DEV_ADDRESS).call{value: (amount * 5) / 100}("");

        if (s1 && s2) return;

        // fallback to paying all to treasury
        (bool s3, ) = treasury.call{value: amount}("");

        require(s3, "Withdrawal failed");
    }
}
