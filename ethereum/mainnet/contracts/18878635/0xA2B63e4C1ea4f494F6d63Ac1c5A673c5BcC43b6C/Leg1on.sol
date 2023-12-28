// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

interface DystoPunks {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface EncodeGraphics {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns(address);
}

interface DystoPunksVX {
    function balanceOf(address owner) external view returns (uint256);
}

contract Leg1on is ERC721AQueryable, Ownable, ReentrancyGuard {

    address constant public DystoAddress = 0xbEA8123277142dE42571f1fAc045225a1D347977;
    address constant public EncodeAddress = 0xCBA5AC55D5e1c56Cf16482456aD0a47f27D38a62;
    address constant public VXAddress = 0xf91523Bc0ffA151ABd971f1b11D2567d4167DB3E;

    uint256 public collectionSize = 7777;
    bool public stoped = false;
    uint64 public publicPrice=70000000000000000;
    uint64 public whitelistPrice=50000000000000000;
    uint public reserved=4077;

    bytes32 public whitelistRoot;
    bytes32 public claimRoot;

    struct SaleConfig {
        bool privateSale;
        bool publicSaleStart;
    }
    SaleConfig public saleConfig;

    mapping(address => bool) public claimed;
    mapping(uint => bool) public claimedDysto;
    mapping(uint => bool) public claimedKey;
    uint256 startingTokenId = 1;

    constructor(
        bytes32 whitelistRoot_,
        bytes32 claimRoot_
    ) ERC721A("LEG1ON", "LEG1ON") { 
        whitelistRoot = whitelistRoot_;
        claimRoot = claimRoot_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /*
    |----------------------------|
    |------ Mint Functions ------|
    |----------------------------|
    */

    function whitelistMint(bytes32[] calldata whitelistProof, uint256 _mintAmount) external payable callerIsUser {
        require(stoped == false, "Sale is stoped");
        SaleConfig memory config = saleConfig;
        bool privateSale = bool(config.privateSale);
        require(privateSale == true, "Private sale has not already started");
        require(totalSupply() + _mintAmount <= (collectionSize-reserved), "reached max supply");
        require(_mintAmount <= 7, "exceeds mint allowance");
        require(MerkleProof.verify(whitelistProof, whitelistRoot, toBytes32(msg.sender)) == true, "invalid proof");

        _safeMint(msg.sender, _mintAmount);
        refundIfOver(whitelistPrice * _mintAmount);
    }

    function publicMint(uint256 _mintAmount) external payable callerIsUser {
        require(stoped == false, "Sale is stoped");
        SaleConfig memory config = saleConfig;
        bool publicSaleStart = bool(config.publicSaleStart);
        require(publicSaleStart == true, "Sale has not already started");
        require(totalSupply() + _mintAmount <= (collectionSize-reserved), "reached max supply");
        require(_mintAmount <= 7, "too many per tx");

        _safeMint(msg.sender, _mintAmount);
        refundIfOver(publicPrice * _mintAmount);
    }

    function mintVXList(uint _mintAmount) external payable callerIsUser {
        require(stoped == false, "Sale is stoped");
        SaleConfig memory config = saleConfig;
        bool privateSale = bool(config.privateSale);
        require(privateSale == true, "Private sale has not already started");
        uint256 vx = DystoPunksVX(VXAddress).balanceOf(msg.sender);
        require(_mintAmount <= 7, "7 max tokens");
        require(totalSupply() + _mintAmount <= (collectionSize-reserved), "Exceeds collection size");
        require(vx > 0, "Not whitelisted");
        _safeMint(msg.sender, _mintAmount);
        refundIfOver(whitelistPrice * _mintAmount);
    }

    function freeClaim(bytes32[] calldata claimProof) external callerIsUser {
        require(stoped == false, "Sale is stoped");
        SaleConfig memory config = saleConfig;
        bool privateSale = bool(config.privateSale);
        require(privateSale == true, "Private sale has not already started");
        require(totalSupply() + 1 <= (collectionSize-reserved), "reached max supply");
        require(claimed[msg.sender] == false, "already claimed");
        require(MerkleProof.verify(claimProof, claimRoot, toBytes32(msg.sender)) == true, "invalid proof");

        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function dystoClaim(uint[] calldata ids) external callerIsUser {
        require(stoped == false, "Sale is stoped");
        uint arrayIdsLength = ids.length;
        SaleConfig memory config = saleConfig;
       bool privateSale = bool(config.privateSale);
        require(privateSale == true, "Private sale has not already started");
        require(arrayIdsLength >= 1, "No ids provided");
        require(totalSupply() + arrayIdsLength <= collectionSize, "reached max supply");
        require(isMintableArrayDysto(ids), "Not a mintable combination");

        for (uint i=0; i<arrayIdsLength; i++) {
            claimedDysto[ids[i]] = true;
        }
        _safeMint(msg.sender, arrayIdsLength);
        reserved = reserved - arrayIdsLength;
    }

    function keyClaim(uint[] calldata ids) external callerIsUser {
        require(stoped == false, "Sale is stoped");
        uint arrayIdsLength = ids.length;
        SaleConfig memory config = saleConfig;
        bool privateSale = bool(config.privateSale);
        require(privateSale == true, "Private sale has not already started");
        require(arrayIdsLength >= 1, "No ids provided");
        require(totalSupply() + arrayIdsLength <= collectionSize, "reached max supply");
        require(isMintableArrayEncode(ids), "Not a mintable combination");
        uint256 mintAmount = getAmountOfEncodeMints(ids);

        for (uint i=0; i<arrayIdsLength; i++) {
            claimedKey[ids[i]] = true;
        }

        _safeMint(msg.sender, mintAmount);
        reserved = reserved - mintAmount;
    }

    

    /*
    |----------------------------|
    |---------- Reads -----------|
    |----------------------------|
    */

    // Check if all ids in array are indeed mintable and msg.sender is the owner
    function isMintableArrayDysto(uint[] calldata ids) private view returns(bool) {
        uint totalIds = ids.length;
        uint totalValidIds = 0;
        bool isValid = false;

        for (uint i=0; i<totalIds; i++) {
            bool isClaimed = checkDystoToClaim(ids[i]);
            if (!isClaimed){
                address ownerOfTokenId = DystoPunks(DystoAddress).ownerOf(ids[i]);
                if (ownerOfTokenId == msg.sender) {
                    totalValidIds++;
                }
            }
        }

        if (totalIds == totalValidIds) {
            isValid = true;
        }
        return isValid;
    }

    function isMintableArrayEncode(uint[] calldata ids) private view returns(bool) {
        uint totalIds = ids.length;
        uint totalValidIds = 0;
        bool isValid = false;

        for (uint i=0; i<totalIds; i++) {
            bool isClaimed = checkKeyClaim(ids[i]);
            if (!isClaimed){
                address ownerOfTokenId = EncodeGraphics(EncodeAddress).ownerOf(ids[i]);
                if (ownerOfTokenId == msg.sender) {
                    totalValidIds++;
                }
            }
        }
        if (totalIds == totalValidIds) {
            isValid = true;
        }
        return isValid;
    }

    function getAmountOfEncodeMints(uint[] calldata ids) private pure returns(uint) {
        uint gold = 50;
        uint silver = 250;
        uint total;

        for (uint i=0; i<ids.length; i++) {
            if (ids[i] <= gold) {
                total = total + 4;
            } else if (ids[i] <= silver) {
                total = total + 2;
            } else {
                total = total + 1;
            }
        }

        return total;
    }

      // returns any extra funds sent by user, protects user from over paying
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function availableDystoToClaim(address owner) public view returns (uint[] memory) {
         uint[] memory punksOfOwner = DystoPunks(DystoAddress).tokensOfOwner(owner);

         uint arrayPunksOfOwnerLength = punksOfOwner.length;
         uint x=0;
         for (uint i=0; i<arrayPunksOfOwnerLength; i++) {
              uint256 id = punksOfOwner[i];
              if (claimedDysto[id]==false) {
                  x++;
              }
         }
         uint[] memory tokensAvailable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayPunksOfOwnerLength; i++) {
              if (claimedDysto[punksOfOwner[i]]==false) {
                  tokensAvailable[x]=punksOfOwner[i];
                  x++;
              }
         }
         return tokensAvailable;
    }

    function availableKeyClaim(address owner) public view returns (uint[] memory) {
         uint[] memory keys = EncodeGraphics(EncodeAddress).tokensOfOwner(owner);

         uint arrayKeysLength = keys.length;
         uint x=0;
         for (uint i=0; i<arrayKeysLength; i++) {
              uint256 id = keys[i];
              if (claimedKey[id]==false) {
                  x++;
              }
         }
         uint[] memory tokensAvailable = new uint[](x);
         x=0;
         for (uint i=0; i<arrayKeysLength; i++) {
              if (claimedKey[keys[i]]==false) {
                  tokensAvailable[x]=keys[i];
                  x++;
              }
         }
         return tokensAvailable;
    }

    function checkDystoToClaim(uint id) public view returns (bool) {
         return claimedDysto[id];
    }

    function checkKeyClaim(uint id) public view returns (bool) {
         return claimedKey[id];
    }

    /*
    |----------------------------|
    |----- Owner  Functions -----|
    |----------------------------|
    */

        // setup minting info
    function setupSaleInfo(
        bool privateSale,
        bool publicSaleStart

    ) external onlyOwner {
        saleConfig = SaleConfig(
        privateSale,
        publicSaleStart
        );
    }

    function stopSale(uint num) public onlyOwner {
        require(num == 2077, "Invalid");
        stoped = true;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setCollectionSize(uint256 _maxCollectionSize) external onlyOwner {
        require(totalSupply() < collectionSize, "Sold Out!");
        require(_maxCollectionSize >= totalSupply(), "Cannot be lower than supply");
        collectionSize = _maxCollectionSize;
    }

   
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setClaimRoot(bytes32 _claimRoot) external onlyOwner {
        claimRoot = _claimRoot;
    }
    // for team/promotions/giveaways
    function reserveAirdrop(uint _mintAmount, address addr) public onlyOwner {
        require(stoped == false, "Sale is stoped");
        require(totalSupply() + _mintAmount < (collectionSize-reserved), "Exceeds collection size");
        _safeMint(addr, _mintAmount);
    }

    /*
    |----------------------------|
    |---- Operator Overrides ----|
    |----------------------------|
    */

    function _startTokenId() internal override(ERC721A) view returns (uint256) {
        return startingTokenId;
    }
}