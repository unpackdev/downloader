// SPDX-License-Identifier: MIT

import "./ERC721B.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.4;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// Developer: uglyrobot.eth
contract HouseOfFinns is ERC721B, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /*
     * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

    string public hofProvenance; // Hash of all images
    
    string private _licenseText;
    bool public licenseLocked; // Init false. Team can't edit the license after this is flipped.
    
    string private _baseTokenURI; // Will be updated with IPFS url once minted out
    bool public baseURILocked; // Init false. Team can't change the baseURI after flipping this, making the metadata truly locked forever.
    string public contractURI; //used by OpenSea, not an official standard
    
    uint256 public hofPrice = 80000000000000000; // 0.08 ETH
    uint96 private _royaltyBPS = 500; // 5% royalty for Rarible/Mintable
    address private _royaltyReceiver; //address of wallet to receive royalties. Defaults to owner().

    uint256 public constant HOF_MAX = 10000; //cannot be changed
    uint256 public maxHofPurchase = 50; //max per mint, to make sale fairer.

    bool public saleIsActive;// Init false.

    uint256 public marketingReserve = 850; // Reserve for marketing - Giveaways/Prizes etc

    address public withdrawAddress; //address of profits wallet
    

    event licenseIsLocked(string _licenseText);
    event metadataLocked(string _baseTokenURI);

    constructor(
        address _teamWallet, 
        string memory _initLicenseText, 
        string memory _initBaseTokenURI,
        string memory _ContractURI
    ) ERC721B("House of Finns", "HOF") payable {
        withdrawAddress = _teamWallet; //set marketing team address
        _royaltyReceiver = _teamWallet; //default to owner
        _licenseText = _initLicenseText;
        _baseTokenURI = _initBaseTokenURI;
        contractURI = _ContractURI;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier contractOwner() {
        _isOwner();
        _;
    }

    /**
    * This actually saves a chunk of contract deployment gas when modifier is used multiple times.
    */
    function _isOwner() internal view {
        require(owner() == _msgSender(), "Ownable: not the owner");
    }
    
    function withdraw() public {
        require(withdrawAddress == msg.sender, "Withdrawl wallet only");

        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //Rarible royalty interface new
    function getRaribleV2Royalties(uint256 /*id*/) external view returns (LibPart.Part[] memory) {
         LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _royaltyBPS;
        _royalties[0].account = payable(_royaltyReceiver);
        return _royalties;
    }

    //Mintable royalty handler
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
       return (_royaltyReceiver, (_salePrice * _royaltyBPS)/10000);
    }

    // Register support for our two royalty standards, falling back to inherited contracts
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721B) returns (bool) {
        if(interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * Slightly more gas efficient than balanceOf for merely returning ownership status.
     */
    function isFinnsOwner(address owner) public view virtual returns (bool) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i = 0; i < qty; i++) {
                if (owner == ownerOf(i)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Returns array of tokens only from the last mint in descending order. Transfers
     * will affect this, it's only useful right after minting.
     * It is not recommended to call this function from another smart contract
     * as it can become quite expensive -- call this function off chain instead.
     */
    function latestMinted(address owner) public view virtual returns (uint256[] memory) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        
        if (totalSupply() == 0) {
            return new uint256[](0);
        }

        uint256 count;
        uint256 start;
        bool started;
        for (uint256 tokenId = _owners.length-1; tokenId >= 0; tokenId--) {
            if (!started && _owners[tokenId] == owner) {
                start = tokenId;
                started = true;
                count++;
            } else if (_owners[tokenId] == address(0)) {
                count++;
            } else if (count >= 1) {
                break;
            }

            if (tokenId == 0) {
                break;
            }
        }

        uint256 i;
        uint256 end = 0;
        if (count <= start) { //prevent underflow
            end = start - count;
        }
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 tokenId = start; tokenId > end; tokenId--) {
            tokenIds[i] = tokenId;
            i++;
        }

        return tokenIds;
    }

    // see https://medium.com/coinmonks/the-elegance-of-the-nft-provenance-hash-solution-823b39f99473
    function setProvenanceHash(string memory provenanceHash) public contractOwner {
        hofProvenance = provenanceHash;
    }

    //change the metadata baseURI
    function setBaseURI(string memory baseURI) public contractOwner {
        require(baseURILocked == false, "Already locked");
        _baseTokenURI = baseURI;
    }

    // Locks the baseURI to prevent further metadata changes. Only lock if it's all in onchain storage, and you will never need to update it again, or you're screwed!
    function lockBaseURI() public contractOwner {
        baseURILocked = true;
        emit metadataLocked(_baseTokenURI);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString())) : "";
    }

    //used by OpenSea
    function setContractURI(string memory _uri) public contractOwner {
        contractURI = _uri;
    }

    //This enables minting
    function flipSaleState() public contractOwner {
        saleIsActive = !saleIsActive;
    }

    // Returns the license for tokens
    function tokenLicense(uint256 _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid token");
        return _licenseText;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public contractOwner {
        licenseLocked = true;
        emit licenseIsLocked(_licenseText);
    }
    
    // Change the license
    function changeLicense(string memory _license) public contractOwner {
        require(licenseLocked == false, "Already locked");
        _licenseText = _license;
    }
    
    // Change the mintPrice
    function setMintPrice(uint256 _newPrice) public contractOwner {
        require(_newPrice != hofPrice, "Not new value");
        hofPrice = _newPrice;
    }
    
    // Change the royaltyBPS
    function setRoyaltyBPS(uint96 _newRoyaltyBPS) public contractOwner {
        require(_newRoyaltyBPS != _royaltyBPS, "Not new value");
        _royaltyBPS = _newRoyaltyBPS;
    }
    
    // Change the royalty receiver address
    function setRoyaltyReceiver(address _account) public contractOwner {
        require(_account != _royaltyReceiver, "Not new value");
        _royaltyReceiver = _account;
    }

    //calculate the mint limit factoring in balances of all reserves
    function _mintLimit() internal virtual returns (uint256 limit) {
        if (marketingReserve > HOF_MAX) {
            return HOF_MAX;
        } else {
            return HOF_MAX - marketingReserve;
        }
    }
    
    // Change per-mint limit
    function setMaxHofPurchase(uint256 _limit) public contractOwner {
        require(maxHofPurchase != _limit, "Not new value");
        maxHofPurchase = _limit;
    }

    /*---------------- Mint Functions -----------*/
    
    // Mint function for marketing reserve
    function reserveMintMarketing(address _to, uint256 _reserveAmount) public contractOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= marketingReserve, "Exceeds reserve remaining");
        require(totalSupply() + _reserveAmount < HOF_MAX, "Exceeds  supply");

        marketingReserve -= _reserveAmount;
        _safeMint(_to, _reserveAmount);
    }
    
    // Mint function for marketing reserve to multiple addresses
    function reserveMintMarketingMass(address[] memory _to, uint256[] memory _reserveAmount) public contractOwner { 
        require(_to.length == _reserveAmount.length, "To and amount length mismatch");
        require(_to.length > 0, "No tos");

        uint256 totalReserve = 0;
        for (uint256 i = 0; i < _to.length; i++) {
            totalReserve += _reserveAmount[i];
        }       
        require(totalReserve > 0 && totalReserve <= marketingReserve, "Exceeds reserve remaining");
        require(totalSupply() + totalReserve < HOF_MAX, "Exceeds  supply");

        marketingReserve -= totalReserve;
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _reserveAmount[i]);
        }
    }

    //Mint for the hof minting drop
    function mintFinns(uint256 numberOfTokens) public payable nonReentrant {
        require(saleIsActive, "Sale Inactive");
        require(numberOfTokens > 0 && numberOfTokens <= maxHofPurchase, "Exceeds transaction max");
        require(totalSupply() + numberOfTokens < _mintLimit(), "Exceeds max supply");
        require(msg.value == hofPrice * numberOfTokens, "Check price");
        
        _safeMint(msg.sender, numberOfTokens);
    }
}