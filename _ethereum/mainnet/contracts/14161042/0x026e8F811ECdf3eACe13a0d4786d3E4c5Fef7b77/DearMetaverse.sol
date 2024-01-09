pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

/*
 ______   _______  _______  ______      __   __  _______  _______  _______  __   __  _______  ______    _______  _______   
|      | |       ||   _   ||    _ |    |  |_|  ||       ||       ||   _   ||  | |  ||       ||    _ |  |       ||       |  
|  _    ||    ___||  |_|  ||   | ||    |       ||    ___||_     _||  |_|  ||  |_|  ||    ___||   | ||  |  _____||    ___|  
| | |   ||   |___ |       ||   |_||_   |       ||   |___   |   |  |       ||       ||   |___ |   |_||_ | |_____ |   |___   
| |_|   ||    ___||       ||    __  |  |       ||    ___|  |   |  |       ||       ||    ___||    __  ||_____  ||    ___|  
|       ||   |___ |   _   ||   |  | |  | ||_|| ||   |___   |   |  |   _   | |     | |   |___ |   |  | | _____| ||   |___   
|______| |_______||__| |__||___|  |_|  |_|   |_||_______|  |___|  |__| |__|  |___|  |_______||___|  |_||_______||_______|  
 
 A METACITZN COLLECTION

 developed by base64.tech 
 */
contract DearMetaverse is ERC1155, Ownable, Pausable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant TOTAL_MAX_SUPPLY = 2000;
    uint256 public constant MIN_TOKEN_INDEX = 0;
    uint256 public constant MAX_TOKEN_INDEX = 22; 
    string public constant name = "DearMetaverse"; 
    string public constant symbol = "DM";
    address constant METACITZN_CONTRACT = 0x2FFfDa1d3268681BB8B518E5ee6c049C1C53bdA9;

    IERC721 public metacitznContract;
    address public signatureVerifier;
    uint256 public totalTokenSupply = 0;

    mapping(address => uint256) public addressToAmountWLMintedSoFar; 
    mapping(uint256 => uint256) public tokenSupply; 
    mapping(uint256 => bool) public metaCITZNTokenIdsMinted;
    
    uint[] unmintedIndexArray = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22];
    uint[] unmintedIndexCountArray = [85,85,85,85,85,85,85,85,85,85,85,85,85,85,90,90,90,90,90,90,90,90,90];

    string private _tokenBaseURI; 

    event PermanentURI(string _value, uint256 indexed _id);
    event randomCollectionEvent(address, bytes, uint256, uint256);
    event randomCollectionGenerationEvent(uint256);
  
    constructor() ERC1155("") {
        _pause();
        metacitznContract = IERC721(METACITZN_CONTRACT);
    }

    function isValidTokenId(uint256 _id) internal pure returns (bool) {
        return _id >= MIN_TOKEN_INDEX && _id <= MAX_TOKEN_INDEX;
    }

    function getRandomCollectionId() internal returns (uint256) {
        uint256 randIndex = getRandomTokenIndex(unmintedIndexArray.length);

        uint256 collectionId = unmintedIndexArray[randIndex];
        unmintedIndexCountArray[collectionId]--;

        //if index count is zero, swap that index in unmintedIndexArray to end of array and pop
        //this is necessary to delete the item from the array
        if(unmintedIndexCountArray[collectionId] == 0) {
            unmintedIndexArray[randIndex] = unmintedIndexArray[unmintedIndexArray.length-1];
            unmintedIndexArray.pop();
        }
        emit randomCollectionGenerationEvent(collectionId);
        return collectionId;
    }

    function getRandomTokenIndex(uint256 _range) view internal returns (uint256) {
        uint randomHash = uint(keccak256(abi.encodePacked(totalTokenSupply, unmintedIndexArray.length, msg.sender,block.timestamp, block.difficulty)));
        return randomHash % _range;
    }

    function metaCitznMint(uint256[] memory _metaCitznTokenIds) whenNotPaused external {
        require(totalTokenSupply + _metaCitznTokenIds.length < TOTAL_MAX_SUPPLY + 1, "Max supply reached");
        
        for (uint256 i = 0; i < _metaCitznTokenIds.length; i++) {
            uint256 _metaCitznTokenId = _metaCitznTokenIds[i];
            require(metaCITZNTokenIdsMinted[_metaCitznTokenId] == false, "metaCITZN token provided has already been utilized to mint");
            require(metacitznContract.ownerOf(_metaCitznTokenId) == msg.sender, "You are not the owner of this token" );
        }

        for (uint256 i = 0; i < _metaCitznTokenIds.length; i++) {
            uint256 _metaCitznTokenId = _metaCitznTokenIds[i];
            metaCITZNTokenIdsMinted[_metaCitznTokenId] = true;

            uint256 collectionId = getRandomCollectionId();
            
            _mint(msg.sender, collectionId, 1, "");
            totalTokenSupply++;
            tokenSupply[collectionId]++;
        }
    }

    function hashMessage(address sender, uint256 nonce) public pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, nonce))));
        return hash;
    }

    function whitelistMint(bytes memory _signature, uint256 _nonce) whenNotPaused external {
        require(addressToAmountWLMintedSoFar[msg.sender] + 1 < 2, "1 WL mint per wallet allocation exceeded");
        require(totalTokenSupply + 1  < TOTAL_MAX_SUPPLY + 1, "Purchase would exceed max supply");
        
        bytes32 messageHash = hashMessage(msg.sender, _nonce);
        require(messageHash.recover(_signature) == signatureVerifier, "Unrecognizable Hash");
               
        addressToAmountWLMintedSoFar[msg.sender] += 1;

        uint256 collectionId = getRandomCollectionId();
        emit randomCollectionEvent(msg.sender, _signature, _nonce, collectionId) ;
        _mint(msg.sender, collectionId, 1, "");
        totalTokenSupply++;
        tokenSupply[collectionId]++;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(isValidTokenId(_tokenId), "invalid id");
        return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString(), ".json")); 
    }
    
    function totalSupply(uint256 _id) external view returns (uint256) {
        require(isValidTokenId(_id), "invalid id");
        return tokenSupply[_id]; 
    }

    
    function getUnmintedIndexLength() external view returns (uint256) {
        return unmintedIndexCountArray.length;
    }

    /* OWNER FUNCTIONS */

    function ownerMint(uint256 _numberToMint) external onlyOwner {
        require(totalTokenSupply + _numberToMint  < TOTAL_MAX_SUPPLY + 1, "Purchase would exceed max supply");
        
        for(uint256 i = 0; i < _numberToMint; i++) {
            uint256 collectionId = getRandomCollectionId();
            
            _mint(msg.sender, collectionId, 1, "");
            totalTokenSupply++;
        }
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint) external onlyOwner {
        require(totalTokenSupply + _numberToMint  < TOTAL_MAX_SUPPLY + 1, "Purchase would exceed max supply");
        
        for(uint256 i = 0; i < _numberToMint; i++) {
            uint256 collectionId = getRandomCollectionId();
            
            _mint(_recipient, collectionId, 1, "");
            totalTokenSupply++;
        }
    }

    function setMetacitznContract(IERC721 _metacitznContract) external onlyOwner {
        // this method is used to allow for mocking in testing
        metacitznContract = _metacitznContract;
    }

    function setSignatureVerifier(address _signatureVerifier) external onlyOwner {
        signatureVerifier = _signatureVerifier;
    }
    
    function freezeMetadata(uint256 _id) external onlyOwner {
        require(isValidTokenId(_id), "invalid id");
        emit PermanentURI(uri(_id), _id); 
    }
    
    function setBaseURI(string memory _URI) external onlyOwner {
        _tokenBaseURI = _URI;
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}