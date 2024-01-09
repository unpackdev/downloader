// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract Monsternauts is ERC721Enumerable, Ownable
{
    uint256 public constant _maxSupply = 6969;    
    uint256 public constant _tokensAllowedPerMint = 25;
    uint256 public constant _initialReserve = 28;
    string private constant _initialBaseURI = "ipfs://QmURhLbpRfDEVji9VgSjQJS91PzimV9tXZgNGiw1t5fNM4/";

    bool public _bIsPublicSale = false;
    bool public _bIsPreSale = false;
    uint256 public _price = 0.06969 ether;
    uint256 public _tokensAllowedPerWhiteListAddress = 1;
    bytes32 private _merkleRoot;
    string private _currentBaseURI;

    mapping(address => uint256) public _whiteListClaimed;

    constructor()
    ERC721("Monsternauts", "MNAUTS")
    {
        uint256 supply = totalSupply();
        
        _currentBaseURI = _initialBaseURI;
        for(uint256 i; i < _initialReserve; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 numberOfMints) public payable
    {
        uint256 supply = totalSupply();

        require(_bIsPublicSale, "Public sale is currently paused.");
        require(numberOfMints > 0 && numberOfMints <= _tokensAllowedPerMint, "Invalid purchase amount.");
        require((supply + numberOfMints) < _maxSupply, "Purchase would exceed max supply of tokens.");
        require((_price * numberOfMints) <= msg.value, "ETH value sent is not correct.");

        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function whiteListMint(bytes32[] calldata _proof) public payable
    {
        uint256 supply = totalSupply();

        require(_bIsPreSale, "Pre-sale is currently paused.");
        require((supply + 1) < _maxSupply, "Purchase would exceed max supply of tokens.");
        require(_price <= msg.value, "ETH value sent is not correct.");
        require(_whiteListClaimed[msg.sender] < _tokensAllowedPerWhiteListAddress, "Purchase would exceed max pre-sale amount for this address.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, _merkleRoot, leaf), "Address is not listed for pre-sale.");

        _safeMint(msg.sender, supply);
        _whiteListClaimed[msg.sender] += 1;
    }

    function setBaseURI(string memory inBaseURI) public onlyOwner
    {
        _currentBaseURI = inBaseURI;
    }

    function togglePublicSale() public onlyOwner
    {
        _bIsPublicSale = !_bIsPublicSale;
    }

    function togglePreSale() public onlyOwner
    {
        _bIsPreSale = !_bIsPreSale;
    }

    function setPrice(uint256 newPrice) public onlyOwner
    {
        _price = newPrice;
    }

    function withdraw() public onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAmount(uint256 amount) public onlyOwner
    {
        require(amount <= address(this).balance, "Amount exceeds balance.");
        payable(msg.sender).transfer(amount);
    }

    function setTokensAllowedPerWhiteListAddress(uint256 newAmount) public onlyOwner
    {
        _tokensAllowedPerWhiteListAddress = newAmount;
    }

    function setMerkleTreeRoot(bytes32 newRoot) public onlyOwner
    {
        _merkleRoot = newRoot;
    }

    function airDropGroup(uint256 startToken, address[] memory users) public onlyOwner
    {
        require(startToken + users.length <= _initialReserve);

        uint256 airDropToken = startToken;
        for (uint256 i = 0; i < users.length; i++) {
            require(ownerOf(airDropToken) == msg.sender);
            address user = users[i];
            safeTransferFrom(msg.sender, user, airDropToken);
            airDropToken++;
        }
    }

    function getWhiteListStatus(address addresstoCheck) public view returns (uint256 whiteListMintCount)
    {
        return _whiteListClaimed[addresstoCheck];
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return _currentBaseURI;
    }
}
