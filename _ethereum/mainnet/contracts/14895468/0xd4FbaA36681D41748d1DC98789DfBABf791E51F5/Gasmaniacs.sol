// SPDX-License-Identifier: MIT

// @author serht0.eth - twitter.com/serht0
// @creator: Gasmaniacs

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";


/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Gasmaniacs is ERC721A, Ownable {

    bytes32 public root;

    string BASE_URI; 

    address proxyRegistryAddress;

    uint256 public TOTAL_SUPPLY = 3333;

    bool public IS_ALLOWLIST_MINT_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;

    uint256 constant NUMBER_OF_TOKENS_ALLOWED = 3;

    mapping(address => uint256) addressToMintCount;

    constructor(string memory name, string memory symbol, string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721A(name, symbol)
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;
        BASE_URI= uri;
    }

    function setBaseURI(string memory _newBaseURI) public 
    onlyOwner {
        BASE_URI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setMerkleRoot(bytes32 merkleroot) public 
    onlyOwner
    {
        root = merkleroot;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Invalid merkle proof");
        _;
   }

    function toggleAllowListSale() public 
    onlyOwner {
        IS_ALLOWLIST_MINT_ACTIVE = !IS_ALLOWLIST_MINT_ACTIVE;
    }

    function togglePublicSale() public 
    onlyOwner {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }


    function allowListSaleMint(address account, uint256 _amount, bytes32[] calldata _proof) public
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_ALLOWLIST_MINT_ACTIVE, "Allowlist Mint is not active");
        require(totalSupply() + _amount <= TOTAL_SUPPLY, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + _amount <= NUMBER_OF_TOKENS_ALLOWED, "Exceeds mint per address");

        addressToMintCount[msg.sender] += _amount;

        _safeMint(msg.sender, _amount);
    }

    function publicSaleMint(uint256 _amount) public
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Public Mint is not active");
        require(totalSupply() + _amount <= TOTAL_SUPPLY, "Exceed total supply");
        require(addressToMintCount[msg.sender] + _amount <= NUMBER_OF_TOKENS_ALLOWED, "Exceeds mint per address");

        addressToMintCount[msg.sender] += _amount;

        _safeMint(msg.sender, _amount);
    }


    function ownerMint(uint256 _amount) public 
    onlyOwner {
        require(totalSupply() + _amount <= TOTAL_SUPPLY, "Exceed total supply");
        _safeMint(msg.sender, _amount);
    }



    function getCurrentMintCount(address _account) public view returns (uint) {
    return addressToMintCount[_account];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
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




