// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

// release-v3.2.0-solc-0.7 openzeppelin
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./AccessControl.sol"; 
import "./IAddressController.sol";
import "./IERC2981.sol";

contract PropyNFT is ERC721Pausable, AccessControl {
    using Counters for Counters.Counter;

    struct RoyaltyInfo {
        address royaltyReceiver;
        uint16 royaltyBasisPoints;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); //mints tokens

    Counters.Counter private tokenIdCounter;
    IAddressController private addressController;
    mapping(uint256 => bytes32) internal tokenHashes;
    mapping(uint256 => RoyaltyInfo) internal tokenIdToRoyaltyInfo;

    event AddressControllerChanged(address indexed who, address new_controller);

    constructor(address _admin, address _addressController) ERC721("PropyNFT", "pNFT") {
        addressController = IAddressController(_addressController);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _admin);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PropyNFT: Caller is not a Admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "PropyNFT: Caller is not a Minter");
        _;
    }

    function mintWithURI(address _to, string memory _tokenURI, address _royaltyReceiver, uint16 _royaltyBasisPoints)
        public onlyMinter
        returns (uint256)
    {
        uint256 newItemId = _mintInternal(_to, _royaltyReceiver, _royaltyBasisPoints);
        _setTokenURI(newItemId, _tokenURI);
        return newItemId;
    }

    function mintWithHash(address _to, bytes32 _hash, address _royaltyReceiver, uint16 _royaltyBasisPoints)
        public onlyMinter
        returns (uint256)
    {
        uint256 newItemId = _mintInternal(_to, _royaltyReceiver, _royaltyBasisPoints);
        tokenHashes[newItemId] = _hash;
        return newItemId;
    }

    function setAddressController(address _addressController) onlyAdmin public {
        addressController = IAddressController(_addressController);
        emit AddressControllerChanged(msg.sender, _addressController);
    }

    /**
    * set contract on hold. Paused contract doesn't accepts Deposits but allows to withdraw funds. 
    */
    function pause() onlyAdmin public {
        super._pause();
    }

    /**
    * unpause the contract (enable deposit operations)
    */
    function unpause() onlyAdmin public {
        super._unpause();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "PropyNFT: URI query for nonexistent token");
        //return ipfs://hash if exists
        if(tokenHashes[tokenId]> 0) {
            return concatStrings("ipfs://", encode(tokenHashes[tokenId])); 
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function _mintInternal(address _recipient, address _royaltyReceiver, uint16 _royaltyBasisPoints) private 
        returns (uint256)
    {
        tokenIdCounter.increment();
        uint256 newItemId = tokenIdCounter.current();
        _mint(_recipient, newItemId);
        RoyaltyInfo storage newRoyaltyInfo = tokenIdToRoyaltyInfo[newItemId];
        newRoyaltyInfo.royaltyReceiver = _royaltyReceiver;
        newRoyaltyInfo.royaltyBasisPoints = _royaltyBasisPoints;
        return newItemId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override { 
        super._beforeTokenTransfer(from, to, tokenId);
        require(address(addressController) != address(0), "PropyNFT: invalid address controller");
        require(addressController.isVerified(to), "PropyNFT: Please proceed to https://propy.com/nft to verify your wallet");       
    }
    /******************************** IPFS LIB ************************************/

    // @title verifyIPFS
    // @author Martin Lundfall (martin.lundfall@consensys.net)
    // @rewrited by Vakhtanh Chikhladze to new version solidity 0.8.0
    bytes constant private sha256MultiHash = "\x12\x20";
    bytes constant private ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    //@dev generates the corresponding IPFS hash (in base 58) to the given stroraged decoded hash
    //@param contentString The content of the IPFS object
    //@return The IPFS hash in base 58
    function encode(bytes32 decodedHash) private pure returns (string memory) {
        bytes memory content=toBytes(decodedHash);
        return toBase58(concat(sha256MultiHash, content));
    }
  
    // @dev Converts hex string to base 58
    /*
        some comment-proof about array size of digits:
        source is the number with base 256. 
        Example: for given input 0x414244 it can be presented as 0x41*256^2+0x42*256+0x44;
        How many digits are needed to write such a number n in base 256?
        (P.S. All all of the following formulas may be checked in WolframAlpha.)
        We need rounded up logarithm of number n with base 256 , in formula presentation: roof(log(256,n))
        Example: roof(log(256,0x414244))=|in decimal 0x414244=4276804|=roof(log(256,4276804))~=roof(2.4089)=3;
        Encoding Base58 works with numbers in base 58.
        Example: 0x414244 = 21 53 20 0 = 21*58^3 + 53*58^2 + 20*58+0
        How many digits are needed to write such a number n in base 58?
        We need rounded up logarithm of number n with base 58 , in formula presentation: roof(log(58,n))
        Example: roof(log(58,0x414244))=|in decimal 0x414244=4276804|=roof(log(58,4276804))~=roof(3.7603)=4;
        
        And the question is: How many times the number in base 58 will be bigger than number in base 256 represantation?
        The aswer is lim n->inf log(58,n)/log(256,n)
        
        lim n->inf log(58,n)/log(256,n)=[inf/inf]=|use hopitals rule|=(1/(n*ln(58))/(1/(n*ln(256))=
        =ln(256)/ln(58)=log(58,256)~=1.36
        
        So, log(58,n)~=1.36 * log(256,n); (1)
        
        Therefore, we know the asymptoyic minimal size of additional memory of digits array, that shoud be used.
        But calculated limit is asymptotic value. So it may be some errors like the size of n in base 58 is bigger than calculated value.
        Hence, (1) will be rewrited as: log(58,n) = [log(256,n) * 136/100] + 1; (2)
        ,where square brackets [a] is valuable part of number [a] 
        In code exist @param digitlength which dinamically calculates the explicit size of digits array.
        And there are correct statement that digitlength <= [log(256,n) * 136/100] + 1 .
    */
    function toBase58(bytes memory source) private pure returns (string memory) {
        uint8[] memory digits = new uint8[]((source.length*136/100)+1); 
        uint digitlength = 1;
        for (uint i = 0; i<source.length; ++i) {
            uint carry = uint8(source[i]);
            for (uint j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return string(toAlphabet(reverse(truncate(digits, digitlength))));
    }

    function toBytes(bytes32 input) private pure returns (bytes memory) {
        return abi.encodePacked(input);
    }
    

    function truncate(uint8[] memory array, uint length) pure private returns (uint8[] memory) {
        if(array.length==length){
            return array;
        }else{
            uint8[] memory output = new uint8[](length);
            for (uint i = 0; i<length; i++) {
                output[i] = array[i];
            }
            return output;
        }
    }
    
    function reverse(uint8[] memory input) pure private returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint i = 0; i<input.length; i++) {
            output[i] = input[input.length-1-i];
        }
        return output;
    }
    
    function toAlphabet(uint8[] memory indices) pure private returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint i = 0; i<indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function concat(bytes memory byteArray1, bytes memory byteArray2) pure private returns (bytes memory) {
        return abi.encodePacked(byteArray1,byteArray2);
    }
    
    function concatStrings(string memory a,string memory b) private pure returns(string memory){
        return string(abi.encodePacked(a,b));
    }

    function to_binary(uint256 x) private pure returns (bytes memory) {
         return abi.encodePacked(x);
    }

    // We signify support for ERC2981, ERC721 & ERC721Metadata

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ERC2981 logic

    function updateRoyaltyInfo(uint256 _tokenId, address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyAdmin {
        require(_exists(_tokenId), "PropyNFT: updateRoyaltyInfo for non-existent token");
        tokenIdToRoyaltyInfo[_tokenId].royaltyReceiver = _royaltyReceiver;
        tokenIdToRoyaltyInfo[_tokenId].royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Takes a _tokenId and _price (in wei) and returns the royalty receiver's address and how much of a royalty the royalty receiver is owed
    function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "PropyNFT: royaltyInfo query for non-existent token");
        receiver = tokenIdToRoyaltyInfo[_tokenId].royaltyReceiver;
        royaltyAmount = getPercentageOf(_price, tokenIdToRoyaltyInfo[_tokenId].royaltyBasisPoints);
    }

    // Represent percentages as basisPoints (i.e. 100% = 10000, 1% = 100)
    function getPercentageOf(
        uint256 _amount,
        uint16 _basisPoints
    ) internal pure returns (uint256 value) {
        value = (_amount * _basisPoints) / 10000;
    }

}