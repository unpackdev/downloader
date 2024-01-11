pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract BagHodlersCommunityContract is ERC721A, Ownable {

    using Strings for uint256;

    // boolean
    bool public isMintOpen = true;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 PRICE = .05 ether;
    uint256 MAX_MINT_PER_TX = 100;

    // strings
    string private _baseURIExtended;

    // mapping
    mapping(bytes32 => bool) private sign_used;
    mapping(address => bool) public freeMintRedeemed;

    // address
    address master;

    constructor() ERC721A("BagHodlers Community", "BHOD", MAX_MINT_PER_TX, MAX_SUPPLY) { }

    function _intMint(address _to, uint _count) internal {
        require(_count <= MAX_MINT_PER_TX, "Max mint per transaction exceeded");
        uint _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY, 'Max supply already reached');
        require((_count + _totalSupply) < MAX_SUPPLY, 'Max supply will be reached with this amount of minting');
        _safeMint(_to, _count);
    }

    function mint(address _to, uint _count) public payable {
        require(isMintOpen, "Mint not yet opened!");
        require(PRICE*_count <= msg.value, 'Not enough ether sent');
        _intMint(_to, _count);
    }

    function freeMint(address _minter, uint8 _amount, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(isMintOpen, "Mint not yet opened!");
        bytes32 hash = keccak256(abi.encodePacked(_minter, _amount));
        require(!sign_used[hash], "Sign already used");
        require(_verifySign(hash, _v, _r, _s), "Invalid sign");
        require(!freeMintRedeemed[_minter], "Free mint already redeemed");
        _intMint(_minter, _amount);
        sign_used[hash] = true;
        freeMintRedeemed[_minter] = true;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function _verifySign(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hash));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer == master;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function dMint(uint _count) public onlyOwner {
        _intMint(msg.sender, _count);
    }

    function setMintOpen(bool _isMintOpen) public onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setMaster(address _add) public onlyOwner {
        master = _add;
    }

}
