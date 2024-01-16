// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract WorstCityNFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public totalSupply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    uint256 public maxSupply = 5555;
    uint256 public maxMintAmountPerContract = 2;
    address[] whitelistAddresses;
    bool public paused = true;
    bool public whitelistRound = false;
    bool public revealed = false;

    constructor() ERC721("Worst City", "WC") {
        setHiddenMetadataUri("ipfs://QmapT2NxsbKbAdabFDQua2vCsSCpruqqt55QotWXdrrKxW");
        totalSupply = 0;
    }

    function setIswhitelistEnabled(bool _state) public onlyOwner {
        whitelistRound = _state;
    }
    function mint() public  {
        require(!paused, "Mint event is paused!");
        require(balanceOf(msg.sender) < maxMintAmountPerContract, "you have already max mint !");

        if(whitelistRound==true){
            require(isWhitelistted(msg.sender), "user is not Whitelisted");
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }else if(whitelistRound==false){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
            if(totalSupply == 1500 || totalSupply == 3000 ){
                paused = true;
            }
        }

    }


    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        whitelistAddresses = _users;
    }
    function isWhitelistted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistAddresses.length; i++) {
            if (whitelistAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }
    function setMaxMintAmountPerContract(uint256 _maxMintAmountPerContract) public onlyOwner {
        maxMintAmountPerContract = _maxMintAmountPerContract;
    }


    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {

        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);

    }
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}