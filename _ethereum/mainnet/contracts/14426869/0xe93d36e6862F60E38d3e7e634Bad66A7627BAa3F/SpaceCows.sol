// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./UpgradeNFT.sol";

import "./ISpaceMilk.sol";
import "./ISale.sol";

contract SpaceCows is ERC721, Ownable, UpgradeNFT {
    using Counters for Counters.Counter;
    Counters.Counter internal _totalSupply;

    string public constant baseExtension = ".json";
    uint256 public constant collectionIndex = 0;
    bool public revealed;
    string public baseURI;
    string public notRevealedUri;
    
    mapping(uint256 => uint256) public mintingInfo;
    mapping(address => uint256) public mintingRate;

    ISpaceMilk public YieldToken;
    ISale public SaleContract;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _notRevealedUri,
        address _tokenAddress,
        uint256 _namePrice,
        uint256 _bioPrice
    )
    ERC721(_name, _symbol)
    UpgradeNFT(_namePrice, _bioPrice) {
        revealed = true;
        baseURI = _baseUri;
        notRevealedUri = _notRevealedUri;
        YieldToken = ISpaceMilk(_tokenAddress);
        _totalSupply.increment();
    }

    /**
    =========================================
    Owner Functions
    @dev these functions can only be called 
        by the owner of contract. some functions
        here are meant only for backup cases.
    =========================================
    */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        YieldToken = ISpaceMilk(_newTokenAddress);
    }

    function setSalesAddress(address _newSalesAddress) external onlyOwner {
        SaleContract = ISale(_newSalesAddress);
    }

    function migrateTokens(address _user, uint256[] memory _tokenId, uint256[] memory _rates) external onlyOwner {
        uint256 tmpRate;

        for (uint32 i = 0; i < _tokenId.length; i++) {
            uint256 tokenId = _tokenId[i];
            uint256 rate = _rates[i];
            _mint(_user, tokenId);
            mintingInfo[tokenId] = rate;
            _totalSupply.increment();

            unchecked {
                tmpRate += rate;
            }
        }

        unchecked {
            mintingRate[_user] += tmpRate;
        }
    }

    function updateTokenData(uint256 _tokenId, uint256 _rate) external onlyOwner {
        _updateTokenData(_tokenId, _rate);
    }

    /**
    ============================================
    Public & External Functions
    @dev functions that can be called by anyone
    ============================================
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeCustomName(uint256 _tokenId, string memory _newName) public override {
        address owner = ownerOf(_tokenId);
		require(_msgSender() == owner, "Caller don't own");

		YieldToken.burn(msg.sender, collectionIndex, nameChangePrice);
		super.changeCustomName(_tokenId, _newName);
	}

    function changeBio(uint256 _tokenId, string memory _newBio) public override {
        address owner = ownerOf(_tokenId);
		require(_msgSender() == owner, "Caller don't own");

		YieldToken.burn(msg.sender, collectionIndex, bioChangePrice);
		super.changeBio(_tokenId, _newBio);
	}

    function getMintingRate(address _address) external view returns (uint256) {
        return mintingRate[_address];
    }

    function getReward() external {
        address user = msg.sender;
        uint256 rate = mintingRate[user];

		YieldToken.fullRewardUpdate(user, rate, collectionIndex);
		YieldToken.getReward(user, collectionIndex);
	}

    function cowMint(address _user, uint256[] memory _tokenId)
    external {
        require(msg.sender == address(SaleContract), "Can't call this");
        _cowMint(_user, _tokenId);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        require(msg.sender == address(SaleContract), "Can't call this");
        return _exists(_tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current() - 1;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        uint256 _mintingRate = mintingInfo[tokenId];
        uint256 _fromRate = mintingRate[from];
        uint256 _toRate = mintingRate[to];
        YieldToken.updateReward(from, _fromRate, to, _toRate, collectionIndex);
        
        unchecked {
            mintingRate[from] = _fromRate - _mintingRate;
            mintingRate[to] = _toRate + _mintingRate;
        }
        ERC721.transferFrom(from, to, tokenId); 
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        uint256 _mintingRate = mintingInfo[tokenId];
        uint256 _fromRate = mintingRate[from];
        uint256 _toRate = mintingRate[to];
        YieldToken.updateReward(from, _fromRate, to, _toRate, collectionIndex);

        unchecked {
            mintingRate[from] = _fromRate - _mintingRate;
            mintingRate[to] = _toRate + _mintingRate;
        }
        ERC721.safeTransferFrom(from, to, tokenId, "");
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI;

        if(revealed == false) {
            currentBaseURI = notRevealedUri;
        } else {
            currentBaseURI = _baseURI();
        }

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
            : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    ============================================
    Internal Functions
    @dev functions that can be called by inside contract
    ============================================
    */
    function _cowMint(address _to, uint256[] memory _tokenId)
    internal {
        uint256 rate = 5 ether;

        for (uint256 i = 0; i < _tokenId.length; i++) {
            _mint(_to, _tokenId[i]);
            _totalSupply.increment();

            unchecked {
                mintingInfo[_tokenId[i]] = rate;
            }
        }

        unchecked {
            mintingRate[_to] += rate * _tokenId.length;
        }
    }

    function _updateTokenData(uint256 _tokenId, uint256 _rate) internal {
        uint256 oldRate = mintingInfo[_tokenId];
        address owner = ownerOf(_tokenId);

        unchecked {
            mintingInfo[_tokenId] = _rate;
            mintingRate[owner] += _rate - oldRate;
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}