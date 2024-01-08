// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./ERC721.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./ERC721Burnable.sol";
import "./draft-EIP712.sol";
import "./IGoldz.sol";

contract FeudalzElvez is ERC721, EIP712, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IGoldz goldz = IGoldz(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);

    Counters.Counter private _tokenIdCounter;
    address _signerAddress;
    string _baseUri;
    string _contractUri;
    
    mapping (address => uint) public accountToMintedFreeTokens;
    uint public constant MAX_SUPPLY = 10000;
    bool public isSalesActive = true;
    uint public price;
    
    constructor() ERC721("FeudalzElvez", "ELVEZ") EIP712("ELVEZ", "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        price = 50 ether;
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
        _contractUri = "ipfs://QmVmJpUzzP7gHbuce1yKL2aeYqkd6cUT4W3xW61XgoBDH1";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function mint(uint quantity) external {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
        
        goldz.transferFrom(msg.sender, address(this), price * quantity);
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function mint(uint quantity, address receiver) external onlyRole(ADMIN_ROLE) {
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");

        for (uint i = 0; i < quantity; i++) {
            safeMint(receiver);
        }
    }

    function freeMint(uint quantity, uint maxFreeMints, bytes calldata signature) external {
        require(recoverAddress(msg.sender, maxFreeMints, signature) == _signerAddress, "user cannot mint");
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "quantity exceeds max supply");
        require(quantity + accountToMintedFreeTokens[msg.sender] <= maxFreeMints, "quantity exceeds allowance");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedFreeTokens[msg.sender] += quantity;
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyRole(ADMIN_ROLE) {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyRole(ADMIN_ROLE) {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyRole(ADMIN_ROLE) {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyRole(ADMIN_ROLE) {
        price = newPrice;
    }

    function burnGoldz() external onlyRole(ADMIN_ROLE) {
        uint balance = goldz.balanceOf(address(this));
        goldz.burn(balance);
    }

    function _hash(address account, uint maxFreeMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxFreeMints,address account)"),
                        maxFreeMints,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint maxFreeMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxFreeMints), signature);
    }

    function setSignerAddress(address signerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signerAddress = signerAddress;
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}