// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// ..................................................
// ..................................................
// .......................SSSSSS.....................
// ......................SSSSSSSSS...................
// ....................SSSSSSSSSSSS..................
// ..................SSSSSSSSSSSSSSSS................
// .................SSSSSS..SSSSSSSSSS...............
// ................SSS.SS....SSS..SSSSS..............
// ................SS..SS..SSSS....SSSS..............
// ...............SS......SS.....S..SSSS.............
// ..............SS..............SS..SSS.............
// .............SS..S...........SSS...SSS............
// ............SSS.SS.SS.....S..SSS...SSSS...........
// ............SSSSSS..SS...SS...SSSS.SSSS...........
// ............SSSSS...SS...SSS...SSSSSSSS...........
// .............SSSSS.SSS..SSSSS.SSSSSSSS............
// ..............SSSSSSSS..SSSSSSSSSSSS..............
// ...............SSSSSSSSSSSSSSSSSSSSS..............
// ...............SSSSSSSSSSSSSSSSSSS................
// ................SSSSSSSSSSSSSSSS..................
// .................SSSSSSSSSSSSS....................
// ....................SSSSSSSS......................
// ..................................................
// ..................................................

// @creator: Simulacra Society - simulacrasociety.io
// @developer: Beaxvision - twitter.com/beaxvision

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract IncubationPods is ERC721, ERC2981ContractWideRoyalties, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address proxyRegistryAddress;

    string _contractURI = "https://api.simulacrasociety.io/ipfs/QmSHwzWDCuUh4qhTzaxDP3TxKS85hyYsqaDp8Fn2Wir9Yb/contract.json";
    string public baseURI = ""; 
    string _hiddenURI = "https://api.simulacrasociety.io/ipfs/QmYmgaQrQKXu6vmtEFaUoABqLpmTkmpVsN5UTM6hYTmcAU/hidden.json";

    uint256 mintPrice = 0.033 ether;

    bool mintState = false;
    bool revealState = false;
    bool whitelistMintState = true;

    mapping(address => uint256) addressMintCount;

    uint256 maxSupply = 7777;
    uint256 maxMintAmount = 77;
    uint256 maxMintAmountPerAddress = 4;
    uint256 maxMintAmountPerTx = 4;

    bytes32 merkleRoot;

    // Deployer address: 0xD8ebfB8A11d9731D12f3EE452b23F2Bf16cca06e
    address founder1 = 0x524192ce030D38aD15cfa1b98F19A55AF692feBD;
    address founder2 = 0xBff3A6caec37850f23Db6ebb9E23C884eCBE13BD;
    address founder3 = 0x7Eb5392b927C0ef17CD74395472C07b68bBCb2C2;
    address communityAndPartners = 0xa9C38B390c7DA71a087A7C98B380dcC8772b478a;
    address treasury = 0x62F19066bFAA6269b704F88c9bf69b8f39B26075;

    constructor(string memory name, string memory symbol, bytes32 _merkleRoot, address _proxyRegistryAddress, address _royaltyReceiver) ERC721(name, symbol) {
        merkleRoot = _merkleRoot;
        proxyRegistryAddress = _proxyRegistryAddress; 
        _setRoyalties(_royaltyReceiver, 250);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function hiddenURI() public view returns (string memory) {
        return _hiddenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist.");
        require(tokenId > 0 && tokenId <= maxSupply, "Token doesn't exist.");

        if(revealState == false) {
            return _hiddenURI;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
        }
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function updateHiddenURI(string memory newHiddenURI) public onlyOwner {
        _hiddenURI = newHiddenURI;
    }

    function updateContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981Base) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function updateRoyalties(address _address, uint256 value) public onlyOwner {
        _setRoyalties(_address, value);
    }

    function updateRevealState(bool newState) public onlyOwner {
        revealState = newState;
    }
    
    function updateMintState(bool newState) public onlyOwner {
        mintState = newState;
    }

    function updateWhitelistMintState(bool newState) public onlyOwner {
        whitelistMintState = newState;
    }

    function updateMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function transferFromOwnerToMultipleAddresses(address[] calldata _addresses, uint256[] calldata _tokenIds) public onlyOwner {
        require(_addresses.length > 0 && _tokenIds.length > 0, "Not enough addresses or tokenIds.");
        require(_addresses.length == _tokenIds.length, "Arrays length mismatch.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 currentTokenId = _tokenIds[i];

            require(_exists(currentTokenId), "Token doesn't exist.");
            require(currentTokenId > 0 && currentTokenId <= maxSupply, "Token doesn't exist.");

            address currentAddress = _addresses[i];
            _safeTransfer(msg.sender, currentAddress, currentTokenId, "");
        }
    }

    function ownerMint(uint256 amount) public onlyOwner {
        require(amount > 0, "Not enough amount");

        uint256 currentSupply = _tokenIdCounter.current();
        require(currentSupply + amount <= maxSupply, "Max supply limit exceeded.");

        for (uint256 i = 0; i < amount; i++) {
            addressMintCount[msg.sender]++;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }
    
    function whitelistMint(uint256 amount, bytes32[] calldata merkleProof) public payable {
        require(mintState == true, "Mint deactivated.");
        require(whitelistMintState == true, "Whitelist Mint deactivated.");

        require(msg.sender == tx.origin, "Not allowed origin.");

        require(amount > 0, "Not enough amount.");
        require(msg.value >= mintPrice * amount, "Insufficient funds.");

        require(_verify(_leaf(msg.sender), merkleProof), "Address is not in the whitelist or wrong merkle proof.");

        uint256 currentSupply = _tokenIdCounter.current();
        uint256 currentAddressMintCount = addressMintCount[msg.sender];
        
        require(currentSupply + amount <= maxSupply, "Max supply limit exceeded.");
        require(currentSupply + amount <= maxMintAmount, "Max mint amount exceeded.");
        require(currentAddressMintCount + amount <= maxMintAmountPerAddress, "Max mint amount per address exceeded.");
        require(amount <= maxMintAmountPerTx, "Max mint amount per transaction exceeded.");

        for (uint256 i = 0; i < amount; i++) {
            addressMintCount[msg.sender]++;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function mint(uint256 amount) public payable {
        require(mintState == true, "Mint deactivated.");
        require(whitelistMintState == false, "Whitelist Mint activated.");

        require(msg.sender == tx.origin, "Not allowed origin.");

        require(amount > 0, "Not enough amount.");
        require(msg.value >= mintPrice * amount, "Insufficient funds.");

        uint256 currentSupply = _tokenIdCounter.current();
        uint256 currentAddressMintCount = addressMintCount[msg.sender];

        require(currentSupply + amount <= maxSupply, "Max supply limit exceeded.");
        require(currentSupply + amount <= maxMintAmount, "Max mint amount exceeded.");
        require(currentAddressMintCount + amount <= maxMintAmountPerAddress, "Max mint amount per address exceeded.");
        require(amount <= maxMintAmountPerTx, "Max mint amount per transaction exceeded.");

        for (uint256 i = 0; i < amount; i++) {
            addressMintCount[msg.sender]++;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function updateMaxMintAmountPerAddress(uint256 newAmount) public onlyOwner {
        maxMintAmountPerAddress = newAmount;
    }

    function updateMaxMintAmountPerTx(uint256 newAmount) public onlyOwner {
        maxMintAmountPerTx = newAmount;
    }

    function updateMaxMintAmount(uint256 newAmount) public onlyOwner {
        maxMintAmount = newAmount;
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough balance.");

        (bool successFounder1, ) = payable(founder1).call{value: ((balance * 180) / 1000)}("");
        require(successFounder1, "Transfer failed.");

        (bool successFounder2, ) = payable(founder2).call{value: ((balance * 180) / 1000)}("");
        require(successFounder2, "Transfer failed.");

        (bool successFounder3, ) = payable(founder3).call{value: ((balance * 180) / 1000)}("");
        require(successFounder3, "Transfer failed.");

        (bool successCommunityAndPartners, ) = payable(communityAndPartners).call{value: ((balance * 250) / 1000)}("");
        require(successCommunityAndPartners, "Transfer failed.");

        (bool successTreasury, ) = payable(treasury).call{value: ((balance * 210) / 1000)}("");
        require(successTreasury, "Transfer failed.");

        (bool successOwner, ) = payable(msg.sender).call{value: (address(this).balance)}("");
        require(successOwner, "Transfer failed.");
    }

    function tokensOfOwner(address owner, uint startId, uint endId) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == owner) {
                    result[index] = tokenId;
                    index++;
                }
            }
            return result;
        }
    }

    function _leaf(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function _verify(bytes32 leaf, bytes32[] memory _merkleProof) internal view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function getMintPrice() public view returns (uint) {
        return mintPrice;
    }

    function getMintState() public view returns (bool) {
        return mintState;
    }
    
    function getRevealState() public view returns (bool) {
        return revealState;
    }
    
    function getWhitelistMintState() public view returns (bool) {
        return whitelistMintState;
    }    

    function getMaxSupply() public view returns (uint) {
        return maxSupply;
    }
  
    function getMaxMintAmount() public view returns (uint) {
        return maxMintAmount;
    }
    
    function getMaxMintAmountPerAddress() public view returns (uint) {
        return maxMintAmountPerAddress;
    }
    
    function getMaxMintAmountPerTx() public view returns (uint) {
        return maxMintAmountPerTx;
    }

    function getAddressMintCount(address _address) public view returns (uint) {
        return addressMintCount[_address];
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
}