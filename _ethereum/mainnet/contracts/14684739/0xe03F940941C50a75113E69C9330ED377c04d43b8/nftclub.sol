// contracts/nftclub.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Import Ownable from the OpenZeppelin Contracts library
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract NToken is ERC721A, Ownable {
    // Mint price in pre-sale period
    uint256 public _preSalePrice;

    // Mint price in sale period
    uint256 public _salePrice;

    // Use for tracing
    uint256 public clubId;
    mapping(uint256 => bool) public _clubIds;
    
    address public factory;

    // Wallet for receive mint value
    address payable _wallet;

    // Total amount of minted
    uint256 public mintedAmount;

    // Max number allow to mint
    uint256 public _maxSupply;

    // Presale and Publicsale start time
    uint256 public presaleStartTime;
    uint256 public saleStartTime;

    event TokenMinted(address minter, uint256 tokenId , uint256 mintPrice, uint256 platformFee);
    
    event ContractDeployed(address sender, address contract_address, uint256 reserveQuantity, uint256 clubId);

    using Strings for uint256;


    // Max token supply
    //uint256 private _totalSupply;
    uint256 public _maxId;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    
    constructor(string memory name_, string memory symbol_, uint256 reserveQuantity, uint256 maxSupply_, uint256 clubId_, uint256 presaleStartTime_, uint256 saleStartTime_, uint256 presalePrice_, uint256 salePrice_) ERC721A(name_, symbol_) {   
        // 0. Check if is able to create NFT
        if (_clubIds[clubId_] == true) {
            revert("ERC721(ByNFTClub): Duplicated clubId");
        }
        _clubIds[clubId_] = true;
        clubId = clubId_;

        // 1. Deplay and log the create event
        factory = msg.sender;
        setSaleTimes(presaleStartTime_, saleStartTime_);
        setMintPrice(presalePrice_, salePrice_);
        setMaxSupply(maxSupply_);
        setWallet(payable(tx.origin));
        transferOwnership(tx.origin);
        

        emit ContractDeployed(tx.origin, address(this), reserveQuantity, clubId_);

        /// 2. Reserve tokens for creator
        if (reserveQuantity > 0) {
            uint256 currentIndex = _currentIndex;
            _mint(tx.origin, reserveQuantity, "", false);
            for (uint256 i = currentIndex; i < currentIndex + reserveQuantity; i++) {
                emit TokenMinted(tx.origin, i, 0, 0);
            }
        }
    }
    
    
    // Minted token will be sent to minter
    // mint_price is salePrice or presalePrice. Caller should send (mint_price * (1 + platformFeePPM / 1e6)) wei.
    function mint(address minter, uint256 mint_price) payable public returns (uint256) {
        // 0. Check is mintable
        if (block.timestamp < presaleStartTime) {
            // Period: Sale not started
            revert("ERC721(ByNFTClub): Not in sale or presale period");
        } else if (block.timestamp >= presaleStartTime && block.timestamp < saleStartTime) {
            // Period: Pre-sale period
            require(msg.value >= _preSalePrice, "ERC721(ByNFTClub): insufficant value for presale period");
        } else if (block.timestamp >= saleStartTime) {
            // Period: Public sale perild
            require(msg.value >= _salePrice, "ERC721(ByNFTClub): insufficant value for sale peroid");
        } else {
            revert("ERC721(ByNFTClub): Invalid _period");
        }
        
        require(totalMinted() < _maxSupply, "ERC721(ByNFTClub): No more tokens could be mint");

        uint256 expectPlatformFee = mint_price * NFTClubFactory(factory).platformFeePPM() / 10e6 ;
        uint256 actualPlatformFee = msg.value - mint_price;
        require(actualPlatformFee >= expectPlatformFee, "ERC721(ByNFTClub): insufficant platform fee");


        // 1. Mint it
        uint256 currentIndex = _currentIndex;

        _mint(minter, 1, "", false);

        // 2. Send mint value to creator and platform
        _wallet.transfer(mint_price);
        NFTClubFactory(factory).wallet().transfer(actualPlatformFee);

        // 3. Do stats
        mintedAmount = mintedAmount + mint_price;

        // 4. Log events
        emit TokenMinted(minter, currentIndex, mint_price, actualPlatformFee);
        
        return currentIndex;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setMaxSupply(uint256 newMaxSupply ) public onlyOwner {
        require(newMaxSupply >= totalMinted(), "ERC721(ByNFTClub): maxSupply must bigger than totalMinted()");
        _maxSupply = newMaxSupply;
    }

    function _baseURI() override internal view returns (string memory) {
        string memory factoryBaseURI = NFTClubFactory(factory).factoryBaseURI();
        return string(abi.encodePacked(factoryBaseURI, toString(abi.encodePacked(this)), "/"));
    }
    
    // Set the mint price for sale and presale period
    function setMintPrice(uint256 pre_sale_price, uint256 sale_price) public onlyOwner {
        require(pre_sale_price < sale_price, "ERC721(ByNFTClub): preSalePirce must be smaller than salePrice");

        _preSalePrice = pre_sale_price;
        _salePrice = sale_price;
    }

    function setSaleTimes(uint256 preSaleStartTime_, uint256 saleStartTime_) public onlyOwner {
        require(preSaleStartTime_ <= saleStartTime_, "ERC721(ByNFTClub): preSaleStartTime must be smaller than saleStartTime");
        presaleStartTime = preSaleStartTime_;
        saleStartTime = saleStartTime_;
    }

    // Set a new totalSupply
    // function setTotalSupply(uint256 newTotalSupply) public onlyOwner {
    //     _totalSupply = newTotalSupply;
    // }

    // Set wallet address for receive mint value
    function setWallet(address payable newWallet) public onlyOwner {
        _wallet = newWallet;
    }
} 


contract NFTClubFactory is Ownable {
    uint256 public platformFeePPM = 12 * 10e3;

    address[] public contracts;

    address payable public wallet;

    string public factoryBaseURI = "https://nft.tinyclub.com/";

    constructor() {
        wallet = payable(msg.sender);
    }

    function deploy(string memory name_, string memory symbol_, uint256 reserveQuantity, uint256 totalSupply, uint256 clubId, uint256 presaleStartTime_, uint256 saleStartTime_, uint256 presalePrice_, uint256 salePrice_ ) public returns (address) {
        NToken c = new NToken(name_, symbol_, reserveQuantity, totalSupply, clubId, presaleStartTime_, saleStartTime_, presalePrice_, salePrice_);
        contracts.push(address(c));
        return address(c);
    }

    function setPlatformFeePPM(uint256 newFeePPM) public onlyOwner {
        platformFeePPM = newFeePPM;
    }

    /// Set the factoryBaseURI, must include trailing slashes
    function setFactoryBaseURI(string memory newBaseURI) public onlyOwner {
        factoryBaseURI = newBaseURI;
    }

    function setWallet(address payable newWallet) public onlyOwner {
        wallet = newWallet;
    }
}

function toString(bytes memory data) pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}