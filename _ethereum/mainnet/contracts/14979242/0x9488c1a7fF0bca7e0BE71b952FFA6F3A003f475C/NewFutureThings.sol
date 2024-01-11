//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";

abstract contract KaboomBoxMP {
  function mint(address addr, uint256 quantity) public virtual;
}

contract NewFutureThings is ERC721, PaymentSplitter, Ownable {

    enum State { OFF, PRESALE, PUBLIC }
    uint public transactionLimit = 50;
    State public saleState = State.OFF;
    bytes32 public presaleMerkleRoot;
    uint public publicPrice = 0.08 ether;
    uint public presalePrice = 0.07 ether;

    string private _contractURI;
    string public baseURI = "";
    uint256 public totalSupply;
    uint public immutable maxSupply = 7000;
    mapping(address => bool) public isPresaleCommunity;
    KaboomBoxMP public kaboomBoxMP;

    address[] private addressList = [
       0x48Ced19d2FE89909031003f7B42d69AFB9E9e1e2,
       0xFc6BD106000132f581e7dEc9dF83e5BD641e157B,
       0x2bAD77c1aE11FF611bD23f6f350D23079AD8A6E1,
       0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7,
       0xd2f56329e98A8D3f6539C0b6FE1226eF2325A801
    ];
    
    uint[] private shareList = [
        33,
        33,
        15,
        8,
        11
    ];

    constructor() 
        ERC721("New Future Things", "NFT")
        PaymentSplitter(addressList, shareList) {
    }

    function mint(uint quantity) external payable {
        require(saleState == State.PUBLIC, "Sale is not active");
        require(publicPrice * quantity == msg.value, "Incorrect ETH amount");
        
        _mintTokens(msg.sender, quantity);
    }

    function communityMint(uint quantity, address addr) external payable {
        require(saleState == State.PRESALE, "Sale is not active");
        require(presalePrice * quantity == msg.value, "Incorrect ETH amount");
        require(isPresaleCommunity[addr], "Not a presale community address");
        ERC721 communityContract = ERC721(addr);
        require(communityContract.balanceOf(msg.sender) > 0, "You don't own anything from this collection");

        _mintTokens(msg.sender, quantity);
    }

    function presaleMint(uint quantity, bytes32[] memory proof) external payable {
        require(saleState == State.PRESALE, "Presale is not active");
        require(presalePrice * quantity == msg.value, "Incorrect ETH amount");
        require(MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        
        _mintTokens(msg.sender, quantity);
    }

    function ownerMint(address addr, uint quantity) external onlyOwner {
        _mintTokens(addr, quantity);
    }

    function _mintTokens(address addr, uint quantity) internal {
        require(quantity > 0, "Must be greater than 0");
        uint start = totalSupply;
        uint end = totalSupply + quantity;
        require(end <= maxSupply, "Exceeds supply");
        require(quantity <= transactionLimit, "Over transaction limit");

        uint256 currentSupply_ = totalSupply;
        for (uint256 i; i < quantity; ++i) {
            _safeMint(addr, currentSupply_++);
        }
        totalSupply = currentSupply_;

        if(address(kaboomBoxMP) != address(0)) {
            uint kaboomCount = (end / 9) - (start / 9 );
            if(kaboomCount > 0) {
                kaboomBoxMP.mint(addr, kaboomCount);
            }
        }
    }

    function enablePublicMint() external onlyOwner {
        saleState = State.PUBLIC;
    }

    function enablePresaleMint() external onlyOwner {
        saleState = State.PRESALE;
    }

    function disableMint() external onlyOwner {
        saleState = State.OFF;
    }

    function setPublicPrice(uint price_) external onlyOwner {
        publicPrice = price_;
    }

    function setPresalePrice(uint price_) external onlyOwner {
        presalePrice = price_;
    }

    function setKaboomBoxMP(address addr) external onlyOwner {
        kaboomBoxMP = KaboomBoxMP(addr);
    }

    function addPresaleCommunity(address addr) external onlyOwner {
        isPresaleCommunity[addr] = true;
    }

    function addPresaleCommunities(address[] memory addresses) external onlyOwner {
        for(uint x = 0; x < addresses.length; x++) {
            isPresaleCommunity[addresses[x]] = true;
        }
    }

    function removePresaleCommunity(address addr) external onlyOwner {
        isPresaleCommunity[addr] = false;
    }

    function setPresaleMerkleRoot(bytes32 presaleRoot) public onlyOwner {
		presaleMerkleRoot = presaleRoot;
	}

    function setBaseUri(string memory uri_) external onlyOwner {
        baseURI = uri_;
    }

    function setContractURI(string memory uri_) external onlyOwner {
        _contractURI = uri_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function releaseAll() public {
        for(uint x = 0; x < addressList.length; x++) {
            release(payable(address(addressList[x])));
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }
}