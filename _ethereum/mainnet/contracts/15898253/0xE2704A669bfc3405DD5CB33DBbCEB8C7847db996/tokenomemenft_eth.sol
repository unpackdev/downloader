// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract ChinkiesETH is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    address proxyRegistryAddress;
    Counters.Counter private _tokenIds;

    string public baseURI;
    string public baseExtension = ".json";

    //Merkle root of freemint list and presale whitelist
    bytes32 public rootFM;
    bytes32 public rootWL;

    uint256 public maxSupply = 6969;

    //Limit of a minting round
    uint256 public endOfMintRound = 6969;

    uint256 public _price = 69690000000000000;

    //Link/description of the licence used for the nft collection
    string public licenceURI;

    //Flag modes
    bool public autoEndMode = true;
    bool public paused = false;
    bool public freemintMode = false;
    bool public whitelistMode = false;
    bool public publicMode = false;

    //Records of mintings claimed for FM and WL
    mapping(address => uint256) public _freemintClaimed;
    mapping(address => uint256) public _whitelistClaimed;

    constructor(string memory uri, address _proxyRegistryAddress)
        ERC721("Chinkies DeGenesis", "Chinkies")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        setBaseURI(uri);
        proxyRegistryAddress = _proxyRegistryAddress;
        rootFM = 0x0000000000000000000000000000000000000000000000000000000000000000;
        rootWL = 0x0000000000000000000000000000000000000000000000000000000000000000;
    }

    function setLicenceURI(string memory _newLicenceURI) public onlyOwner {
        licenceURI = _newLicenceURI;
    }

    function _licenceURI() internal view returns (string memory) {
        return licenceURI;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "onlyAccounts(): Not allowed origin");
        _;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(string memory rootType, bytes32 merkleroot)
        public
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(rootType)) ==
                keccak256(abi.encodePacked("FM")) ||
                keccak256(abi.encodePacked(rootType)) ==
                keccak256(abi.encodePacked("WL")),
            "Wrong root type: must be FM or WL"
        );

        if (
            keccak256(abi.encodePacked(rootType)) ==
            keccak256(abi.encodePacked("FM"))
        ) {
            rootFM = merkleroot;
        }
        if (
            keccak256(abi.encodePacked(rootType)) ==
            keccak256(abi.encodePacked("WL"))
        ) {
            rootWL = merkleroot;
        }
    }

    function setMintRound(uint256 mintRoundAmount) public onlyOwner {
        endOfMintRound = _tokenIds.current() + mintRoundAmount;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof, bytes32 merkleroot) {
        require(
            MerkleProof.verify(
                _proof,
                merkleroot,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "isValidMerkleProof(): Not allowed origin"
        );
        _;
    }

    function freeMint(
        address account,
        uint256 _amount,
        uint256 _maxAuthorizedAmount,
        bytes32[] calldata _proof
    ) external payable isValidMerkleProof(_proof, rootFM) onlyAccounts {
        require(msg.sender == account, "Account not allowed");
        require(freemintMode, "Freemint is OFF");
        require(!paused, "Contract is paused");
        require(
            _freemintClaimed[msg.sender] + _amount <= _maxAuthorizedAmount,
            "You can't mint so much tokens"
        );

        uint256 current = _tokenIds.current();

        require(current + _amount <= maxSupply, "Max supply exceeded");
        require(_price * _amount <= msg.value, "Not enough ethers sent");

        _freemintClaimed[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function whitelistMint(
        address account,
        uint256 _amount,
        uint256 _maxAuthorizedAmount,
        bytes32[] calldata _proof
    ) external payable isValidMerkleProof(_proof, rootWL) onlyAccounts {
        require(msg.sender == account, "Account not allowed");
        require(whitelistMode, "Whitelist mode is OFF");
        require(!paused, "Contract is paused");
        require(
            _whitelistClaimed[msg.sender] + _amount <= _maxAuthorizedAmount,
            "You can't mint so much tokens"
        );

        uint256 current = _tokenIds.current();

        require(current + _amount <= maxSupply, "Max supply exceeded");
        require(_price * _amount <= msg.value, "Not enough ethers sent");

        _whitelistClaimed[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts {
        require(publicMode, "PublicSale is OFF");
        require(!paused, "Contract is paused");
        require(_amount > 0, "Zero amount of mint");

        uint256 current = _tokenIds.current();

        require(
            current + _amount <= endOfMintRound,
            "Max supply for this minting round exceeded"
        );

        require(current + _amount <= maxSupply, "Max supply exceeded");
        require(_price * _amount <= msg.value, "Not enough ethers sent");

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);

        //sold out!
        if (autoEndMode) {
            if (tokenId == maxSupply || tokenId == endOfMintRound) {
                publicMode = false;
            }
        }
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePublicSale() public onlyOwner {
        publicMode = !publicMode;

        if (publicMode) {
            adjustMintPriceInWei(69690000000000000);
            whitelistMode = false;
            freemintMode = false;
        }
    }

    function toggleWhitelist() public onlyOwner {
        whitelistMode = !whitelistMode;

        if (freemintMode) {
            adjustMintPriceInWei(42000000000000000);
            publicMode = false;
            freemintMode = false;
        }
    }

    function toggleFreemint() public onlyOwner {
        freemintMode = !freemintMode;

        if (freemintMode) {
            adjustMintPriceInWei(0);
            whitelistMode = false;
            publicMode = false;
        }
    }

    function toggleAutoEndMode() public onlyOwner {
        autoEndMode = !autoEndMode;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// Adjust the mint price
    /// @dev modifies the state of the `mintPrice` variable
    /// @notice sets the price for minting a token
    /// @param newPrice_ The new price for minting
    function adjustMintPriceInWei(uint256 newPrice_) public onlyOwner {
        _price = newPrice_;
    }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
