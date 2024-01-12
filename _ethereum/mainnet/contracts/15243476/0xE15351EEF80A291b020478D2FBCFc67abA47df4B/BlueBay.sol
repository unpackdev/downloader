// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./console.sol";


contract BlueBay is ERC721A, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    string public baseURI;
    string public baseExtension       =  ".json";
    string public metaDataFolder      =  "";
    string public notRevealedUri      =  "https://monaco.mypinata.cloud/ipfs/QmVJrRy2y72oq2GMYwtarpKBcDoQbFJKACYdH6C7ZKFm6G/0.json";

    uint256 public remainTokenAmount  =  5000;
    uint256 public revealed           =  0;
    uint256 public calledNum          =  0;
    uint256 public startTime          =  0;

    uint256 public startPrice         =  0.1 ether;
    uint256 public endPrice           =  0.2 ether;

    uint256 public WLdiscountPrice    =  0.02 ether;
    uint256 public WLdiscountLimit    =  2;

    uint256 public changedDuration    =  60;
    uint256 public changedAmount      =  0.000002240143369 ether;

    uint256 public prevTime           =  startTime;
    uint256 public prevPrice          =  startPrice;

    bool public started               =  false;
    bool public ended                 =  false;

    address private masterWallet;
    bytes32 private merkleRoot;
    uint256[] public totalTokenIDs;

    struct User {
        uint256[] userTokenIDs;
        address userAddr;
    }

    mapping(uint256 => User) public users;
    mapping(address => uint256) public WLreservedNum;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        masterWallet = owner();
    }

    // internal
    // convenience function to return the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // reserve NFT tokens needed to be bought
    function reserve(uint256[] memory _tokenIds, bytes32[] memory _merkleProof) public payable {
        require(started, "Mint is not started");
        require(!ended, "Mint is ended");
        require(msg.sender != address(0), "Recipient should be present");
        require(_tokenIds.length > 0, "Need to mint at least 1 NFT");
        require(currentPrice() >= startPrice && currentPrice() < endPrice, "Not suitable minting price");
        require(remainTokenAmount > 0, "Max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(msg.value != 0, "Royalty value should be positive" );
            bytes32 sender = keccak256(abi.encodePacked(msg.sender));

            if (MerkleProof.verify(_merkleProof, merkleRoot, sender) && WLreservedNum[msg.sender] < WLdiscountLimit) {
                console.log("whitelisted user and still in discount limit");
                uint256 temp = WLdiscountLimit.sub(WLreservedNum[msg.sender]);

                if (_tokenIds.length <= temp) {
                    WLreservedNum[msg.sender] = WLreservedNum[msg.sender].add(_tokenIds.length);
                    require(msg.value >= currentPrice().sub(WLdiscountPrice).mul(_tokenIds.length), "Insufficient funds");
                } else {
                    WLreservedNum[msg.sender] = WLreservedNum[msg.sender].add(temp);
                    require(msg.value >= currentPrice().sub(WLdiscountPrice).mul(temp).add(currentPrice().mul(_tokenIds.length.sub(temp))), "Insufficient funds");
                }
            } else {
                console.log("not whitelisted user or not in discount limit");
                require(msg.value >= currentPrice().mul(_tokenIds.length), "Insufficient funds");
            }
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] >= 0 && _tokenIds[i] < 5000, "invalid token IDs");

            if (totalTokenIDs.length > 0) {
                for (uint256 j = 0; j < totalTokenIDs.length; j++) {
                    require(_tokenIds[i] != totalTokenIDs[j], "duplicated tokenID");
                }
            }

            totalTokenIDs.push(_tokenIds[i]);
            users[calledNum].userTokenIDs.push(_tokenIds[i]);
            remainTokenAmount = remainTokenAmount.sub(1);
        }

        users[calledNum].userAddr = msg.sender;
        calledNum = calledNum.add(1);
    }

    // distribute NFT tokens to owners bought them
    function distribute() public onlyOwner {
        require(ended, "Mint is not ended yet");
        require(calledNum > 0, "calledNum value should be positive");

        for (uint256 i = 0; i < calledNum; i++) {
            _safeMint(users[i].userAddr, users[i].userTokenIDs.length);
        }
    }

    // get NFT current price
    function currentPrice() public view returns (uint256) {
        uint256 price;

        if (prevTime <= 0) {
            price = prevPrice;
        } else {
            price = prevPrice.add(block.timestamp.sub(prevTime).div(changedDuration).mul(changedAmount));

            if (price >= endPrice) {
                price = endPrice;
            }
        }
        return price;
    }

    // return NFT token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if(revealed == 0) return notRevealedUri;
        // If there is no base URI, return the token URI.["
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, baseExtension));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function getIsRevealed() public view returns (uint256) {
        return revealed;
    }
    
    // view
    function getIsEnded() public view returns (uint256) {
        if (ended == true) return 1;
        return 0;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getTotalTokenIDs() external view returns (uint256[] memory) {
        return totalTokenIDs;
    }

    function getTotalTokenIDsLength() external view returns (uint256) {
        return totalTokenIDs.length;
    }

    //only owner
    function setReveal(uint256 _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedUri(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setRevealedURI(string memory _RevealedURI) public onlyOwner {
        setReveal(1);
        setBaseURI(_RevealedURI);
    }

    function setStartPrice(uint256 _startPrice) public onlyOwner {
        require(_startPrice < endPrice, "start price should be less than end price");
        startPrice = _startPrice;
        prevPrice = startPrice;
    }

    function setEndPrice(uint256 _endPrice) public onlyOwner {
        require(_endPrice > startPrice, "end price should be greater than start price");
        endPrice = _endPrice;
    }

    function setWLdiscountLimit(uint256 _WLdiscountLimit) public onlyOwner {
        WLdiscountLimit = _WLdiscountLimit;
    }

    function setWLdiscountPrice(uint256 _WLdiscountPrice) public onlyOwner {
        require(_WLdiscountPrice < currentPrice(), "whitelist user's discount price should be less than current price");
        WLdiscountPrice = _WLdiscountPrice;
    }

    function setChangedDuration(uint256 _changedDuration) public onlyOwner {
        prevPrice = prevPrice.add(block.timestamp.sub(prevTime).div(changedDuration).mul(changedAmount));
        prevTime = block.timestamp;
        changedDuration = _changedDuration;
    }

    function setChangedAmount(uint256 _changedAmount) public onlyOwner {
        prevPrice = prevPrice.add(block.timestamp.sub(prevTime).div(changedDuration).mul(changedAmount));
        prevTime = block.timestamp;
        changedAmount = _changedAmount;
    }

    function setStart(bool _state) public onlyOwner {
        started = _state;
        startTime = block.timestamp;
        prevTime = startTime;
    }

    function setEnd(bool _state) public onlyOwner {
        ended = _state;
    }

    function setMasterWallet(address addr) public onlyOwner {
        //current setted contract owner.
        require(addr != address(0), "Invalid Address");
        masterWallet = addr;
    }

    function withdraw() public onlyOwner {
        // =============================================================================

        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(masterWallet).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}