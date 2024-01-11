// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

// @author Kanishka Gunatunga
// @contact kanishka@loops.lk

contract AdventuresOfTako is ERC721, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;

    address proxyRegistryAddress;

    uint256 public maxSupply = 888;
    uint256 public presaleMaxSupply = 88;

    string public baseURI;
    string public notRevealedUri =
        "https://gateway.pinata.cloud/ipfs/QmYADAmVjpM8rbDtwKb9VNrLhrbRPVUEjiyQA13AC55mZP/ttm_hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public discountM = false;

    uint256 presaleAmountLimit = 1;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 28800000000000000; // 0.0288 ETH
    uint256 _discountPrice = 14400000000000000; // 0.0144 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [92, 8];
    address[] private _team = [
        0xb701bd46aa3535f0b762a548CB32128B657E7303,
        0x08030a874510cD4BFEa8B0D4d328F8FE9404c633
    ]; 

    constructor(
        string memory uri,
        bytes32 merkleroot,
        address _proxyRegistryAddress
    )
        ERC721("Adventures Of Tako", "TTM")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
        root = merkleroot;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ) == true,
            "Not allowed address."
        );
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function toggleDiscount() public onlyOwner {
        discountM = !discountM;
    }

    function presaleMint(address account,uint256 _amount,bytes32[] calldata _proof) 
    external isValidMerkleProof(_proof) onlyAccounts {
        require(msg.sender == account, "Adventures Of Tako: Not allowed");
        require(presaleM, "Adventures of Tako: Presale is OFF");
        require(!paused, "Adventures of Tako: Contract is paused");
        require(
            _amount <= presaleAmountLimit,
            "Adventures of Tako: You can't mint so much tokens"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,
            "Adventures of Tako: You can't mint so much tokens"
        );

        uint256 current = _tokenIds.current();

        require(
            current + _amount <= presaleMaxSupply,
            "Adventures of Tako: Presale max supply exceeded"
        );

        _presaleClaimed[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts {
        require(publicM, "Adventures of Tako: PublicSale is OFF");
        require(!paused, "Adventures of Tako: Contract is paused");
        require(_amount > 0, "Adventures of Tako: zero amount");
        require(_amount <= 20, "Adventures of Tako: max 20 mints per wallet");

        uint256 current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Adventures of Tako: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Adventures of Tako: Not enough ethers sent"
        );

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function discountSaleMint(uint256 _amount) external payable onlyAccounts {
        require(discountM, "Adventures of Tako: DiscountSale is OFF");
        require(!paused, "Adventures of Tako: Contract is paused");
        require(_amount > 0, "Adventures of Tako: zero amount");
        require(_amount <= 20, "Adventures of Tako: max 20 mints per wallet");

        uint256 current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Adventures of Tako: Max supply exceeded"
        );
        require(
            _discountPrice * _amount <= msg.value,
            "Adventures of Tako: Not enough ethers sent"
        );

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
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
        if (revealed == false) {
            return notRevealedUri;
        }

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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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
