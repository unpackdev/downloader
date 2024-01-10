// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";


interface IERC20Burnable {

  function balanceOf(address account) external view returns (uint);

  function decimals() external view  returns (uint8);

  function burn(uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;

  function allowance(address owner, address spender) external view returns(uint256);

}

contract BurnKing is ERC721Enumerable, Ownable {
    uint32 public constant SECONDS_IN_DAY = 86400;

    // Base URI
    string private _nftBaseURI = "https://burnking.io/api/meta/";

    address public publicKey;

    mapping (Pools => uint256) public poolTypeToLimit;
 
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
     poolTypeToLimit[Pools.Common] = 4000;
     poolTypeToLimit[Pools.UnCommon] = 2000;
     poolTypeToLimit[Pools.Rare] = 50;
     poolTypeToLimit[Pools.Epic] = 10;
     poolTypeToLimit[Pools.Legendary] = 3;
     poolTypeToLimit[Pools.Ultimate] = 2;
     poolTypeToLimit[Pools.King] = 1;
   }

    function transferNftFromPool(address _burner, Pools _poolType) internal {
       if(_poolType != Pools.Void){
        mintFor(_poolType, msg.sender);
       }
       _lastBurnedByUser[_burner] = block.timestamp;
    }

  function burnEther(bytes memory _signature, uint256 _tokenCount,  uint256 _expiredDateInSeconds,uint256 _usdCost, uint8 _poolType) external payable{
    require(SafeMath.sub(block.timestamp, _lastBurnedByUser[msg.sender], 'Once per day') >= SECONDS_IN_DAY, "You can burn tokens only once per day!");
    require(_expiredDateInSeconds >= block.timestamp, "Transaction expired");
    require(msg.value >= _tokenCount, 'You do not have enough ethers');

    string memory concatenatedParams = concatParamsEth(_tokenCount, _expiredDateInSeconds, _usdCost, _poolType);

    checkParamsVerification(_signature, concatenatedParams);

    (bool sent, ) = address(0).call{value: _tokenCount}("");
    require(sent, "Failed to burn Tokens");

    uint256 keysCountByPool = _nftTypesCount[Pools(_poolType)];
    transferNftFromPool(msg.sender, Pools(_poolType));

    emit BurnedEther(msg.sender, _usdCost, Pools(_poolType), keysCountByPool);
  }

  function burnERC20(bytes memory _signature, uint256 _tokenCount, uint256 _expiredDateInSeconds, uint256 _usdCost, uint8 _poolType, address _tokenContractAddress) external {
    require(block.timestamp - _lastBurnedByUser[msg.sender] >= SECONDS_IN_DAY, "You can burn tokens only once per day!");
    require(_expiredDateInSeconds >= block.timestamp, "Transaction expired");
    
    string memory concatenatedParams = concatParamsERC(_tokenCount, _expiredDateInSeconds, _usdCost, _poolType, _tokenContractAddress);

    checkParamsVerification(_signature, concatenatedParams);

    IERC20Burnable tokenContractBurnable = IERC20Burnable(_tokenContractAddress);
    // uint8 tokenDecimals = tokenContractBurnable.decimals();
    
    require(tokenContractBurnable.allowance(msg.sender, address(this)) >= _tokenCount, "Tokens for burning are not approved");

    tokenContractBurnable.burnFrom(msg.sender, _tokenCount);

    uint256 keysCountByPool = _nftTypesCount[Pools(_poolType)];
    transferNftFromPool(msg.sender, Pools(_poolType));

    emit BurnedEther(msg.sender, _usdCost, Pools(_poolType), keysCountByPool);
  }

    function mintFor(Pools tokenType, address receiver) internal {
      require(uint8(tokenType) >= 0 && uint8(tokenType) < 8, "Unknown token type");
      // require(_nftTypesCount[tokenType] + 1 <= poolTypeToLimit[tokenType], "You try to mint more than the max allowed for the type");

      if (_nftTypesCount[tokenType] + 1 <= poolTypeToLimit[tokenType]) {
      uint256 mintIndex = totalSupply() + 1;

      _nftIdTypes[mintIndex] = Pools(tokenType);
      _nftTypesCount[tokenType]++;

      _safeMint(receiver, mintIndex);

      emit tokenMintedFor(receiver, mintIndex);
      }
    }

    function getTokenType(uint256 tokenId) external view returns (uint256) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return uint8(_nftIdTypes[tokenId]);
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId), "Token does not exist.");
      return string(abi.encodePacked(_nftBaseURI, Strings.toString(_tokenId)));
    }

   function checkParamsVerification(bytes memory _signature, string memory _concatenatedParams) public {
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
      require(verifyMessage(_concatenatedParams, v, r, s) == publicKey, 'Your signature is not valid');
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

    function concatParamsEth(uint256 _tokenCount, uint256 _timestamp, uint256 _usdCost, uint8 _poolType) public pure returns(string memory) {
        return string(abi.encodePacked(Strings.toString(_tokenCount),Strings.toString(_timestamp),Strings.toString(_usdCost),Strings.toString(_poolType)));
    }

     function concatParamsERC(uint256 _tokenCount, uint256 _timestamp, uint256 _usdCost, uint8 _poolType, address _contractAddress) public pure returns(string memory){
        string memory contractStr = _addressToString(_contractAddress);
        return string(abi.encodePacked(Strings.toString(_tokenCount),Strings.toString(_timestamp),Strings.toString(_usdCost),Strings.toString(_poolType),contractStr));
    }

    function _addressToString(address _addr) internal pure returns(string memory){
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