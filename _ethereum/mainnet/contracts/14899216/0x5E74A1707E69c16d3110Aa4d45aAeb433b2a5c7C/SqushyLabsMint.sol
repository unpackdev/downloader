// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AUpgradeable.sol";
import "./ECDSA.sol";
import "./OwnableUpgradeable.sol";

struct Config {
    string name;
    string symbol;
    uint256 maxSupply;
    address signer;
    string baseURI;
    uint256 publicMintLimit;
    uint256 publicMintPrice;
    bool publicMintEnabled;
    bool approveListMintingEnabled;
    address squshy_labs_address;
    uint256 commission;
    address implementationAddress;
}

contract SqushyLabsMintUpgradeable is ERC721AUpgradeable, OwnableUpgradeable {
    using ECDSA for bytes32;

    // public vars
    uint256 public maxSupply;
    string public baseURI;

    bool public approveListMintingEnabled;
    bool public publicMintEnabled;

    uint256 public publicMintPrice;
    uint256 public publicMintLimit;

    address private squshy_labs_address;
    uint256 private commission;

    // private vars
    address private signer;

    function _initialize(Config memory _config) initializerERC721A initializer public {
        __ERC721A_init(_config.name, _config.symbol);
        __Ownable_init();
        setURI(_config.baseURI);
        signer = _config.signer;
        maxSupply = _config.maxSupply;
        commission = _config.commission;
        squshy_labs_address = _config.squshy_labs_address;
        setMintConfig(_config.publicMintLimit, _config.publicMintPrice, _config.publicMintEnabled, _config.approveListMintingEnabled);
    }

    function setMintConfig(uint256 _publicMintLimit, uint256 _publicMintPrice, bool _publicMintEnabled, bool _approveListMintingEnabled) public onlyOwner{
        publicMintLimit = _publicMintLimit;
        publicMintPrice = _publicMintPrice;
        publicMintEnabled = _publicMintEnabled;
        approveListMintingEnabled = _approveListMintingEnabled;
    }

    // read metadata
	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

    // set metadata
    function setURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}

    // using signer technique for managing approved minters
    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _hash(address _address, uint amount, uint allowedAmount, uint cost) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, amount, allowedAmount, cost));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == signer);
    }

    // standard minting function
    function mint(uint256 amount, address mintAddress) public payable {
        require(publicMintEnabled, "CONTRACT ERROR: minting has not been enabled");
        require(_numberMinted(mintAddress) + amount <= publicMintLimit, "CONTRACT ERROR: Address has already claimed max amount");
        require(totalSupply() + amount <= maxSupply, "CONTRACT ERROR: not enough remaining in supply to support desired mint amount");
        require(amount * msg.value == amount * publicMintPrice, "CONTRACT ERROR: not enough ether sent");
        _safeMint(mintAddress, amount);
    }

    // allow list minting function
    function allowListMint(uint8 v, bytes32 r, bytes32 s, uint256 amount, uint256 allowedAmount, address mintAddress) public payable {
        require(approveListMintingEnabled, "CONTRACT ERROR: allow list minting has not been enabled");
        require(_numberMinted(mintAddress) + amount <= allowedAmount, "CONTRACT ERROR: Address has already claimed max amount");
        require(totalSupply() + amount <= maxSupply, "CONTRACT ERROR: not enough remaining in supply to support desired mint amount");
        require(_verify(_hash(mintAddress, amount, allowedAmount, msg.value), v, r, s), 'CONTRACT ERROR: Invalid signature');
        _safeMint(mintAddress, amount);
    }

    // withdraw function
    function withdraw() public payable {
        uint256 balance = address(this).balance;
        require(balance > 0, "CONTRACT ERROR: Zero balance");
        uint256 _commission = ((commission * balance) / 1000);
        AddressUpgradeable.sendValue(payable(squshy_labs_address), _commission);
        AddressUpgradeable.sendValue(payable(owner()), balance - _commission);
    }

}

contract SqushyLabsMint is SqushyLabsMintUpgradeable {
    function initialize(Config memory _config
    ) public initializer {
        _initialize(_config);
    }
}