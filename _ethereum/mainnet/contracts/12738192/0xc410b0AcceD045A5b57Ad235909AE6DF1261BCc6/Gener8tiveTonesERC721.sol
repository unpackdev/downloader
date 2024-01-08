//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721URIStorage.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

/*
Additional contract info will be added, as needed, to the contractInfo storage variable.
You can read this on etherscan by passing in incrementing indicies as parameter.
*/

contract Gener8tiveTonesERC721 is ERC721URIStorage, ERC721Holder, Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for bytes32;

    // =======================================================
    // EVENTS
    // =======================================================
    event CauseBeneficiaryChanged(address newCauseBeneficiary);
    event TokenUriUpdated(uint256 tokenId, string uri);
    event TokenPurchased(uint256 tokenId, address newOwner, TokenType tokenType);
    event TokenMinted(uint256 tokenIndex, bytes32 hashValue, TokenType tokenType);

    // =======================================================
    // STATE
    // =======================================================
    Counters.Counter public tokenId;
    address payable public causeBeneficiary;
    mapping(uint256 => TokenData) public tokenData;

    uint256 public maxSupply = 125;
    uint256 public mintPrice = 400000000 gwei;
    bool public preSalePurchaseEnabled = true;
    bool public mintingEnabled = false;
    mapping(uint256 => string) public contractInfo;
    
    string mintBaseUri;
    address kCompsContractAddress;
    mapping(address => uint16) numTokensByAddress;

    // =======================================================
    // ENUMS & STRUCTS
    // =======================================================
    enum TokenType { PRESALE, PRESALE_KCOMPSOWNER, OPEN, OPEN_KCOMPSOWNER }

    struct TokenData {
        uint256 price;
        bytes32 seed;
        string name;
        bool forSale;
        TokenType tokenType;
    }

    // =======================================================
    // CONSTRUCTOR
    // =======================================================
    constructor(
        string memory _name,
        string memory _symbol,
        address _kCompsContractAddress,
        string memory _mintBaseUri,
        address payable _causeBeneficiary
    )
        ERC721(_name, _symbol)
    {
        kCompsContractAddress = _kCompsContractAddress;
        mintBaseUri = _mintBaseUri;
        causeBeneficiary = _causeBeneficiary;
    }

    // =======================================================
    // ADMIN
    // =======================================================
    function disableMinting()
        public
        onlyOwner
    {
        mintingEnabled = false;
    }

    function enableMinting()
        public
        onlyOwner
    {
        mintingEnabled = true;
    }

    function disablePreSalePurchase()
        public
        onlyOwner
    {
        preSalePurchaseEnabled = false;
    }

    function enablePreSalePurchase()
        public
        onlyOwner
    {
        preSalePurchaseEnabled = true;
    }

    function setContractInfo(uint _index, string memory _info)
        public
        onlyOwner
    {
        contractInfo[_index] = _info;
    }

    function changeCauseBeneficiary(address payable newCauseBeneficiary)
        public
        onlyOwner
    {
        causeBeneficiary = newCauseBeneficiary;
        emit CauseBeneficiaryChanged(causeBeneficiary);
    }

    function changeMintPrice(uint256 newMintPrice)
        public
        onlyOwner
    {
        mintPrice = newMintPrice;
    }

    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyOwner
    {
        super._setTokenURI(_tokenId,  _newTokenURI);
        emit TokenUriUpdated(_tokenId, _newTokenURI);
    }

    function changePresaleTokenPrice(uint256 _tokenId, uint256 _newPrice)
        public
        onlyOwner
    {
        // ensure token is of PRESALE type
        require(tokenData[_tokenId].tokenType == TokenType.PRESALE, "Token is not of Presale Type");

        // ensure token is owned by the owner
        require(ownerOf(_tokenId) == owner(), "Token has already been sold");
        
        tokenData[_tokenId].price = _newPrice;
    }

    function preSaleMint(uint256 _price, string memory _tokenUri, bool _forSale)
        public
        onlyOwner
    {
        // check max supply
        require(tokenId.current() < maxSupply, "Collection max supply reached");

        // save token data
        tokenData[tokenId.current()] = TokenData({
            price: _price,
            name: string(abi.encodePacked("Tone ", tokenId.current().toString())),
            tokenType: TokenType.PRESALE,
            seed: getHashOfTokenIndex(tokenId.current()),
            forSale: _forSale
        });

        // mint and set tokenuri
        super._safeMint(msg.sender, tokenId.current());
        super._setTokenURI(tokenId.current(), _tokenUri);

        tokenId.increment();
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    // =======================================================
    // INTERNAL UTILS
    // =======================================================
    function getTokenAvailability()
        private
        view
        returns(bool[] memory availableTokens)
    {
        availableTokens = new bool[](tokenId.current());

        for (uint256 i = 0; i < tokenId.current(); i++) {
            if(ownerOf(i) == owner() && tokenData[i].forSale) {
                availableTokens[i] = true;
            }
            else {
                availableTokens[i] = false;
            }
        }
    }

    function div256(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mul256(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    // =======================================================
    // PUBLIC API
    // =======================================================
    function getHashOfTokenIndex(uint256 _tokenId)
        public
        pure
        returns(bytes32 idKeccak)
    {
        idKeccak = keccak256(abi.encodePacked(_tokenId));
    }

    function getSupplyData()
        public
        view
        returns(
            uint256 _currentTokenId,
            uint256 _maxSupply,
            uint256 _mintPrice,
            bool _mintingEnabled,
            bool _preSalePurchaseEnabled,
            bool _isKCompsOwner,
            bool[] memory _tokenAvailability,
            address payable _causeBeneficiary
        )
    {
        _currentTokenId = tokenId.current();
        _maxSupply = maxSupply;
        _mintPrice = mintPrice;
        _isKCompsOwner = isKCompsOwner(msg.sender);
        _mintingEnabled = mintingEnabled;
        _preSalePurchaseEnabled = preSalePurchaseEnabled;
        _tokenAvailability = getTokenAvailability();
        _causeBeneficiary = _causeBeneficiary;
    }

    function getTokenData(uint256 _tokenId)
        public
        view
        returns(TokenData memory _tokenData, string memory _tokenUri)
    {
        _tokenData = tokenData[_tokenId];
        _tokenUri = tokenURI(_tokenId);
    }

    function isKCompsOwner(address _address)
        public
        view
        returns(bool kCompsOwner)
    {
        AbstractKCompsContract abstractKcomps = AbstractKCompsContract(kCompsContractAddress);
        uint256 numTokensOwned = abstractKcomps.balanceOf(_address);

        if(numTokensOwned > 0) {
            return true;
        }
        return false;
    }

    function purchasePresaleToken(uint256 _tokenId)
        public
        payable
    {
        // ensure pre-sale purchasing is enabled
        require(preSalePurchaseEnabled, "Pre-Sale purchasing is disabled");

        // ensure the token exists
        require(_exists(_tokenId), "Requested token does not exist yet");

        // ensure token is for sale
        require(tokenData[_tokenId].forSale, "Token is not for sale");

        // ensure token is of PRESALE type
        require(tokenData[_tokenId].tokenType == TokenType.PRESALE, "Token is not of Presale Type");

        // ensure token is owned by the owner
        require(ownerOf(_tokenId) == owner(), "Token is not owned by the owner");

        // ensure sufficient funds were sent
        if(isKCompsOwner(msg.sender)) {
            require(msg.value >= div256(tokenData[_tokenId].price, 2), "Insufficient ETH sent");
            tokenData[_tokenId].tokenType = TokenType.PRESALE_KCOMPSOWNER;
        }
        else {
            require(msg.value >= tokenData[_tokenId].price, "Insufficient ETH sent");
        }

        // calculate gener8tive fee & send beneficiary portion
        uint256 gener8tiveFee = div256(mul256(85, msg.value), 100);
        causeBeneficiary.transfer(msg.value - gener8tiveFee);

        // remove from sale
        tokenData[_tokenId].forSale = false;

        _transfer(owner(), msg.sender, _tokenId);

        emit TokenPurchased(_tokenId, msg.sender, tokenData[_tokenId].tokenType);
    }

    function mint()
        public
        payable
    {
        // check mint handbrake
        require(mintingEnabled, "Minting is currently disabled");

        // check max supply
        require(tokenId.current() < maxSupply, "Collection max supply reached");

        // ensure sufficient funds were sent
        if(isKCompsOwner(msg.sender)) {
            require(msg.value >= div256(mintPrice, 2), "Insufficient ETH sent for mint");
        }
        else {
            require(msg.value >= mintPrice, "Insufficient ETH sent for mint");
        }

        TokenType tokenType = TokenType.OPEN;

        // set token type if k-comps owner
        if(isKCompsOwner(msg.sender)) {
            tokenType = TokenType.OPEN_KCOMPSOWNER;
        }

        // calculate gener8tive fee and send to beneficiary
        uint256 gener8tiveFee = div256(mul256(85, msg.value), 100);
        causeBeneficiary.transfer(msg.value - gener8tiveFee);

        // generate unique seed hash for tone
        uint16 numTokensOwnedNySender = numTokensByAddress[msg.sender];
        bytes32 _hash = keccak256(abi.encodePacked(tokenId.current(), numTokensOwnedNySender));

        numTokensByAddress[msg.sender] ++;

        // save token data
        tokenData[tokenId.current()] = TokenData({
            price: 0,
            name: string(abi.encodePacked("Tone ", tokenId.current().toString())),
            tokenType: tokenType,
            seed: _hash,
            forSale: false
        });

        // build mint token uri
        string memory tokenUri = string(abi.encodePacked(mintBaseUri, tokenId.current().toString()));

        super._safeMint(msg.sender, tokenId.current());
        super._setTokenURI(tokenId.current(), tokenUri);

        tokenId.increment();

        emit TokenMinted(tokenId.current() - 1, _hash, tokenType);
    }
}

contract AbstractKCompsContract
{
    function balanceOf(address addr)
        public
        pure
        returns(uint256)
    {
        return 0;
    }
}
