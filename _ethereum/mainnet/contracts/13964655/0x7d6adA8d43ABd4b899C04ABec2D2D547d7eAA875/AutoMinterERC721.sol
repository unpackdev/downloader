// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

// import "./ERC721.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";

contract AutoMinterERC721 is Initializable, ERC721Upgradeable, OwnableUpgradeable
{
    string private baseURI;
    address public shareAddress;
    uint256 public mintFee;
    bool private mintSelectionEnabled;
    bool private mintRandomEnabled;
    
    uint256 public remaining;
    mapping(uint256 => uint256) public cache;
    mapping(uint256 => uint256) public cachePosition;

    constructor(){}

    function initialize(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address shareAddress_,
        address ownerAddress_,
        uint256 mintFee_,
        uint256 size_,
        bool mintSelectionEnabled_,
        bool mintRandomEnabled_) public initializer  {

        __ERC721_init(name_, symbol_);
        baseURI = baseURI_;
        shareAddress = shareAddress_;
        mintFee = mintFee_;
        mintSelectionEnabled = mintSelectionEnabled_;
        mintRandomEnabled = mintRandomEnabled_;
        _transferOwnership(ownerAddress_);
        remaining = size_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    /* Mint specific token if individual token selection is enabled */
    function mintToken(uint256 tokenID) payable public
    {
        require(mintSelectionEnabled == true, 'Specific token minting is not enabled for this contract');
        require(msg.value == mintFee, 'Eth sent does not match the mint fee');
        
        _splitPayment();
        
        _drawIndex(tokenID);
        
        _safeMint(msg.sender, tokenID);
    }
    
    /* Mint random token if random minting is enabled */
    function mintRandom() payable public
    {
        require(mintRandomEnabled == true, 'Random minting is not enabled for this contract');
        require(msg.value == mintFee, 'Eth sent does not match the mint fee');
        
        _splitPayment();
        
        uint256 tokenID = _drawRandomIndex();
        
        _safeMint(msg.sender, tokenID);
    }
    
    /* Mint if have been pre-approved using signature of the owner */
    function mintPreSelected(bool isFree, address to, uint256 tokenID, bytes calldata signature) payable public
    {
        /* Hash the content (isFree, to, tokenID) and verify the signature from the owner address */
        address signer = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(isFree, to, tokenID))),
                signature);
            
        require(signer == owner());
        
        /* If isFree then do not splitPayment, else splitPayment */
        if(!isFree){
            _splitPayment();
        }
        
        /* Mint the token for the provided to address */
        _drawIndex(tokenID);
        
        _safeMint(to, tokenID);
    }
    
    /* Mint a token to a specific address */
    function mintToAccount(address to, uint256 tokenID) onlyOwner() public
    {
        _drawIndex(tokenID);
        _safeMint(to, tokenID);
    }
    
    function _splitPayment() internal
    {
        if(msg.value != 0){
            uint256 splitValue = msg.value / 10;
            uint256 remainingValue = msg.value - splitValue;
            
            payable(shareAddress).transfer(splitValue);
            payable(owner()).transfer(remainingValue);
        }
    }
    
    function _drawRandomIndex() internal returns (uint256 index) {
        //RNG
        uint256 i = uint(keccak256(abi.encodePacked(block.timestamp))) % remaining;

        // if there's a cache at cache[i] then use it
        // otherwise use i itself
        index = cache[i] == 0 ? i : cache[i];

        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        
        // store the position of moved token in cache to be looked up (add 1 to avoid 0, remove when recovering)
        cachePosition[cache[i]] = i + 1;
        
        remaining = remaining - 1;
    }
    
    function _drawIndex(uint256 tokenID) internal {
        // recover the index, subtract 1 from cachePosition as an additional 1 was added to avoid 0 conflict
        uint256 i = cachePosition[tokenID] == 0 ? tokenID : cachePosition[tokenID] - 1;
        
        require(i <= remaining);
        
        // grab a number from the tail
        cache[i] = cache[remaining - 1] == 0 ? remaining - 1 : cache[remaining - 1];
        
        // store the position of moved token in cache to be looked up (add 1 to avoid 0, remove when recovering)
        cachePosition[cache[i]] = i + 1;
        
        remaining = remaining - 1;
    }
    
    function isTokenAvailable(uint256 tokenID) external view returns (bool)
    {
        return !_exists(tokenID) && tokenID < remaining;
    }
}
