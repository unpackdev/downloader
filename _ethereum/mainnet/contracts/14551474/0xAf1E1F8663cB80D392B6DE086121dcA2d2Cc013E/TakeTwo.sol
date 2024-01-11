// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TakeTwo is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    enum Status { SALE_NOT_LIVE, PRESALE_LIVE, SALE_LIVE }

    uint256 public constant MAX_SUPPLY = 2447;
    
    Status public state;
    uint256 public presalePrice = 0.05 ether;
    uint256 public price = 0.1 ether;
    uint256 public maxPresaleMintsPerWallet = 2;
    uint256 public maxMintsPerWallet = 4;
    bool public revealed;
    string public baseURI;
    string public provenance;

    address private _signerAddress;
 
    constructor() ERC721A("Take Two", "T2") {
        _safeMint(address(this), 1);
        _burn(0);
    }

    function numberMinted(address wallet) external view returns (uint256 amount){
        return _numberMinted(wallet);
    }

    function presaleMint(uint256 quantity, bytes calldata signature) external payable {
        require(msg.sender == tx.origin, "Take Two: Contracts Not Allowed");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Take Two: Exceed Max Supply");

        require(state == Status.PRESALE_LIVE, "Take Two: Presale Not Live");

        require(_signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Take Two: Signer Mismatch");

        require(_numberMinted(msg.sender) + quantity <= maxPresaleMintsPerWallet, "Take Two: Exceeds Max Per Wallet");
        require(msg.value == presalePrice * quantity, "Take Two: Insufficient ETH");
        
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(msg.sender == tx.origin, "Take Two: Contracts Not Allowed");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Take Two: Exceed Max Supply");

        require(state == Status.SALE_LIVE, "Take Two: Sale Not Live");

        require(_numberMinted(msg.sender) + quantity <= maxMintsPerWallet, "Take Two: Exceeds Max Per Wallet");
        require(msg.value == price * quantity, "Take Two: Insufficient ETH");
   
        _safeMint(msg.sender, quantity);
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= MAX_SUPPLY, "Take Two: Exceed Max Supply");
        for(uint256 i = 0; i < receivers.length; i++){
            _safeMint(receivers[i], 1);
        }
    }

    function setSaleState(Status _state) external onlyOwner {
        state = _state;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }


    function setSigner(address _signer) external onlyOwner {
        _signerAddress = _signer;
    }    

    function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxPresaleMintsPerWallet(uint256 _maxPresaleMintsPerWallet) external onlyOwner {
        maxPresaleMintsPerWallet = _maxPresaleMintsPerWallet;
    }

    function setProvenanceHash(string memory _provenance) external onlyOwner {
        require(bytes(provenance).length == 0, "Take Two: Already Set");
        provenance = _provenance;
    }

    function updateBaseURI(string memory newURI, bool reveal) external onlyOwner {
        baseURI = newURI;
        if(reveal) {
            revealed = reveal;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x26cf6d1bA793aE408614302aD2D4977FfC983304).transfer(balance * 1 / 20);
        payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).transfer(balance * 1 / 20);
        payable(0x7Ffe8aBf82Eb24132ff7D06C1aADB3441BC9C444).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}