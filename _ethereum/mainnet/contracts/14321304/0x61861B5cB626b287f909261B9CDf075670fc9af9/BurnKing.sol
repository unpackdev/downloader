// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";



interface IERC20 {
    
    function balanceOf(address account) external view returns (uint);

    function decimals() external view  returns (uint8);

}

interface IERC20Burnable {

  function burn(uint256 _amount) external;

}

contract BurnKing is ERC721Enumerable, Ownable {
    uint256 public constant SECONDS_IN_DAY = 86400;

    // Base URI
    string private _nftBaseURI = "https://burnking.io/api/meta/";

    address public publicKey;

    uint256 private DEADLINE_TIME = 1200;

    // pools limits
    uint256 public constant COMMON_LIMIT = 100000;
    uint256 public constant UNCOMMIN_LIMIT = 20000;
    uint256 public constant RARE_LIMIT = 5000;
    uint256 public constant EPIC_LIMIT = 1000;
    uint256 public constant LEGENDARY_LIMIT = 150;
    uint256 public constant ULTIMATE_LIMIT = 20;
    uint256 public constant KING_LIMIT = 1;

    mapping (address => uint256) private _lastBurnedByUser;

    mapping(uint256 => Pools) private _nftIdTypes;
    mapping(Pools => uint256) public _nftTypesCount;

   enum Pools {
       Common,
       UnCommon,
       Rare,
       Epic,
       Legendary,
       Ultimate,
       King,
       Void
   }

   event BurnedEther(
       address indexed user,
       uint256 indexed amount,
       Pools indexed tokenType,
       uint256 totalMinted
   );

     event tokenMintedFor(
      address mintedFor,
      uint256 tokenId
    );


   constructor(address _publicKey)ERC721("Burn King", "BK"){
     publicKey = _publicKey;
   }

    function transferNftFromPool(address _burner, uint256 _burningUSD, Pools _poolType) internal {
       if(_poolType != Pools.Void){
        mintFor(_poolType, msg.sender);
       }
       uint256 keysCountByPool = _nftTypesCount[_poolType];
       _lastBurnedByUser[_burner] = block.timestamp;
       emit BurnedEther(_burner, _burningUSD, _poolType, keysCountByPool);
    }

     function burnEther(bytes memory _signature, uint256 _tokenCount,  uint256 _timestamp,uint256 _usdCost, uint8 _poolType) external payable{
      require(block.timestamp - _lastBurnedByUser[msg.sender] >= SECONDS_IN_DAY, "You can burn tokens only once per day!");
      require(block.timestamp - _timestamp < DEADLINE_TIME, "Transaction expired");
      require(msg.value >= _tokenCount, 'you do not have enough ethers');
      string memory concatenatedParams = concatParamsEth(_tokenCount, _timestamp, _usdCost, _poolType);
      bool isVerified = isCorrectParams(_signature, concatenatedParams);
      require(isVerified, "Your signature is not valid");
      (bool sent, ) = address(0).call{value: _tokenCount}("");
      require(sent, "Failed to burn Tokens");
      transferNftFromPool(msg.sender, _usdCost, Pools(_poolType));
     }

     function burnERC20(bytes memory _signature, uint256 _tokenCount, uint256 _timestamp, uint256 _usdCost, uint8 _poolType, address _tokenContractAddress) external{
       require(block.timestamp - _lastBurnedByUser[msg.sender] >= SECONDS_IN_DAY, "You can burn tokens only once per day!");
       require(block.timestamp - _timestamp < DEADLINE_TIME, "Transaction expired");
       string memory concatenatedParams = concatParamsERC(_tokenCount, _timestamp, _usdCost, _poolType, _tokenContractAddress);

       bool isVerified = isCorrectParams(_signature, concatenatedParams);  
       require(isVerified, "Your signature is not valid");

       IERC20 tokenContract = IERC20(_tokenContractAddress);
       IERC20Burnable tokenContractBurnable = IERC20Burnable(_tokenContractAddress);
       uint8 tokenDecimals = tokenContract.decimals();
       uint256 contractBalance = tokenContract.balanceOf(address(this));
       require(contractBalance >= _tokenCount * 10**tokenDecimals, "Not enough funds for burning");
       tokenContractBurnable.burn(_tokenCount * 10**tokenDecimals);
       transferNftFromPool(msg.sender, _usdCost, Pools(_poolType));
     }

    function mintFor(Pools tokenType, address receiver) internal {
      require(
        tokenType == Pools.Common
        || tokenType == Pools.UnCommon
        || tokenType == Pools.Rare
        || tokenType == Pools.Epic
        || tokenType == Pools.Legendary
        || tokenType == Pools.Ultimate
        || tokenType == Pools.King,
        "Unknown token type"
      );

      if (Pools(tokenType) == Pools.Common) require(_nftTypesCount[tokenType] + 1 <= COMMON_LIMIT, "You tried to mint more than the max allowed for common type");
      if (Pools(tokenType) == Pools.UnCommon) require(_nftTypesCount[tokenType] + 1 <= UNCOMMIN_LIMIT, "You tried to mint more than the max allowed for uncommon type");
      if (Pools(tokenType) == Pools.Rare) require(_nftTypesCount[tokenType] + 1 <= RARE_LIMIT, "You tried to mint more than the max allowed for rare type");
      if (Pools(tokenType) == Pools.Epic) require(_nftTypesCount[tokenType] + 1 <= EPIC_LIMIT, "You tried to mint more than the max allowed for epic type");
      if (Pools(tokenType) == Pools.Legendary) require(_nftTypesCount[tokenType] + 1 <= LEGENDARY_LIMIT, "You tried to mint more than the max allowed for legendary type");
      if (Pools(tokenType) == Pools.Ultimate) require(_nftTypesCount[tokenType] + 1 <= ULTIMATE_LIMIT, "You tried to mint more than the max allowed for ultimate type");
      if (Pools(tokenType) == Pools.King) require(_nftTypesCount[tokenType] + 1 <= KING_LIMIT, "You tried to mint more than the max allowed for king type");
      uint256 mintIndex = totalSupply() + 1;

      _nftIdTypes[mintIndex] = Pools(tokenType);
      _nftTypesCount[tokenType]++;

      _safeMint(receiver, mintIndex);

      emit tokenMintedFor(receiver, mintIndex);
    }

    function getTokenType(uint256 tokenId) external view returns (uint256) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return uint256(_nftIdTypes[tokenId]);
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId), "Token does not exist.");
      return string(abi.encodePacked(_nftBaseURI, Strings.toString(_tokenId)));
    }

   function isCorrectParams(bytes memory _signature, string memory _concatenatedParams) public view returns(bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return verifyMessage(_concatenatedParams, v, r, s) == publicKey;
    }

   function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

   function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function verifyMessage(string memory _concatenatedParams, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        uint messageLength = bytes(_concatenatedParams).length;
        bytes memory prefix = abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(messageLength));
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _concatenatedParams));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function concatParamsEth(uint256 _tokenCount, uint256 _timestamp, uint256 _usdCost, uint8 _poolType) internal pure returns(string memory){
        return string(abi.encodePacked(Strings.toString(_tokenCount),Strings.toString(_timestamp),Strings.toString(_usdCost),Strings.toString(_poolType)));
    }

     function concatParamsERC(uint256 _tokenCount, uint256 _timestamp, uint256 _usdCost, uint8 _poolType, address _contractAddress) internal pure returns(string memory){
        string memory contractStr = _addressToString(_contractAddress);
        return string(abi.encodePacked(Strings.toString(_tokenCount),Strings.toString(_timestamp),Strings.toString(_usdCost),Strings.toString(_poolType),contractStr));
    }

    function _addressToString(address _addr) private pure returns(string memory){
      bytes memory addressBytes = abi.encodePacked(_addr);

      bytes memory stringBytes = new bytes(42);

      stringBytes[0] = '0';
      stringBytes[1] = 'x';

      for(uint i = 0; i < 20; i++){
        uint8 leftValue = uint8(addressBytes[i]) / 16;
        uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

        bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
        bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

        stringBytes[2 * i + 3] = rightChar;
        stringBytes[2 * i + 2] = leftChar;
      }

      return string(stringBytes);
    }
}