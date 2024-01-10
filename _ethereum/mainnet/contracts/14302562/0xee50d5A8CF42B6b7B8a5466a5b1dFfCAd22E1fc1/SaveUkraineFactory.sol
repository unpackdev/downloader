// SPDX-License-Identifier: MIT

/*

    888b. 8888    db    .d88b 8888
    8  .8 8www   dPYb   8P    8www
    8wwP' 8     dPwwYb  8b    8
    8     8888 dP    Yb `Y88P 8888

    Yb        dP 888 8    8
    Yb  db  dP   8  8    8
    YbdPYbdP    8  8    8
    YP  YP    888 8888 8888

    888b. 888b. 8888 Yb    dP    db    888 8
    8  .8 8  .8 8www  Yb  dP    dPYb    8  8
    8wwP' 8wwK' 8      YbdP    dPwwYb   8  8
    8     8  Yb 8888    YP    dP    Yb 888 8888

                                    .d88b  8
                                    8P www 8
                                    8b  d8 8
                                    `Y88P' 8888


Visit https://www.sunflowers4ukraine.org/ for project details.
Contract Developed by https://hcode.tech/
*/

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractMintTokenFactory.sol";

contract SaveUkraineFactory is  AbstractMintTokenFactory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public fundsRaised;

    Counters.Counter private mtCounter;
  
    mapping(uint256 => MintToken) public mintTokens;
    
    event Claimed(uint index, address indexed account, uint amount);
    event ClaimedMultiple(uint[] index, address indexed account, uint[] amount);

    struct MintToken {
        uint256 mintPrice;
        string ipfsMetadataHash;
        mapping(address => uint256) claimedMTs;
    }

    string internal _contractURI;
   
function addMintToken(
        uint256 _mintPrice,
        string memory _ipfsMetadataHash
        
    ) public onlyOwner {
        
        uint256 _tokenIndex = mtCounter.current();
        MintToken storage mt = mintTokens[_tokenIndex];
        _update_mt(mt, _mintPrice, _ipfsMetadataHash);
        mtCounter.increment();

    }


    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/") {
        name_ = "Sunflowers4Ukraine";
        symbol_ = "S4U";
       addMintToken(100000000000000000, "QmVq9Kq6tnkRztExvGo51NWeSYM5R831ASTpV2cRYpaK3U");
       addMintToken(200000000000000000, "QmUvwp6t1rJQBDCz2hJB24TYoZBKrottxht66gznRuLR2j");
       addMintToken(500000000000000000, "QmaecMjV2L4U9aCJ5u72sXnBSKaZ4tTVTLM5ociqYZZCtD");
       addMintToken(1000000000000000000, "QmWfx7DCzUq762kg4VL88d3dLQGsu7RZ18LCgt1RUAwSa3");
       addMintToken(4000000000000000000, "QmYQDZPhfwihYXXjPFgv6aAdmXSTxtkY3KVT2NT3b5Q5Pb");
       addMintToken(40000000000000000000, "QmZZfV9BCxKsMEW4oiB3tdyLF9Xz4KNPkUbwfSehSh1UPa"); 
       addMintToken(400000000000000000000, "QmUQ6QfQFCQaPHBL47pJMazXPBR3s2iaSkuksmCmukUAkf");
    }

    function _update_mt( 
        MintToken storage mt,
        uint256 _mintPrice,
        string memory _ipfsMetadataHash
    ) internal {
        require(_mintPrice > 0, "addMintToken: _mintPrice must be non zero");
        mt.mintPrice = _mintPrice;  
        mt.ipfsMetadataHash = _ipfsMetadataHash;
    }

    

    function editMintToken(
        uint256 _tokenIndex,
        uint256 _mintPrice, 
       
        string memory _ipfsMetadataHash
        
    ) external onlyOwner {
        _update_mt(mintTokens[_tokenIndex], _mintPrice,_ipfsMetadataHash);
    }   

     

    function editTokenIPFSMetaDataHash(
        string memory _ipfsMetadataHash, 
        uint256 _tokenIndex
    ) external  onlyOwner{
        mintTokens[_tokenIndex].ipfsMetadataHash = _ipfsMetadataHash;
    } 


    function editTokenMintPrice(
        uint256 _mintPrice, 
        uint256 _tokenIndex
    ) external onlyOwner {
        mintTokens[_tokenIndex].mintPrice = _mintPrice;
    } 

   
    function claim(
        uint256 numTokens,
        uint256 tokenIndex
    ) external payable {
        // verify call is valid
        require(isValidClaim(numTokens,tokenIndex));
        uint256 tokenCost = numTokens.mul(mintTokens[tokenIndex].mintPrice);
        require(!paused(), "Claim: claiming is paused");
        
        mintTokens[tokenIndex].claimedMTs[msg.sender] = mintTokens[tokenIndex].claimedMTs[msg.sender].add(numTokens);
        fundsRaised = fundsRaised.add(tokenCost);
         emit Claimed(tokenIndex, msg.sender, numTokens);
        _mint(msg.sender, tokenIndex, numTokens, "");

       
    }

    function claimMultiple(
        uint256[] calldata numTokens,
        uint256[] calldata tokenIndexs
    ) external payable {
        // duplicate merkle proof indexes are not permitted
        require(arrayIsUnique(tokenIndexs), "Claim: claim cannot contain duplicate indexes");

         // verify contract is not paused
        require(!paused(), "Claim: claiming is paused");

        //validate all tokens being claimed and aggregate a total cost due
       
        for (uint i=0; i< tokenIndexs.length; i++) {
            require(isValidClaim(numTokens[i],tokenIndexs[i]), "One or more claims are invalid");
        }

        for (uint i=0; i< tokenIndexs.length; i++) {
            mintTokens[tokenIndexs[i]].claimedMTs[msg.sender] = mintTokens[tokenIndexs[i]].claimedMTs[msg.sender].add(numTokens[i]);
        }

        emit ClaimedMultiple(tokenIndexs, msg.sender, numTokens);
        _mintBatch(msg.sender, tokenIndexs, numTokens, "");

        

    
    }

    function getPrices() public view returns(uint256[] memory) {
        uint256 len = mtCounter.current();
        uint256[] memory prices = new uint256[](len);

        for (uint i=0; i < len; i++) {
            prices[i] = mintTokens[i].mintPrice;
        }

        return prices;
    
    }

    function mint(
        address to,
        uint256 numTokens,
        uint256 tokenIndex) public onlyOwner
    {   
        _mint(to, tokenIndex, numTokens, "");
    }

    function mintBatch(
        address to,
        uint256[] calldata numTokens,
        uint256[] calldata tokenIndexs) public onlyOwner
    {
        _mintBatch(to, tokenIndexs, numTokens, "");
    }

    function isValidClaim( uint256 numTokens,
        uint256 tokenIndex) internal view returns (bool) {
         // verify contract is not paused
        require(!paused(), "Claim: claiming is paused");
        require(tokenIndex < mtCounter.current(),"Invalid tokenIndex");
        // Verify minting price
        require(msg.value >= numTokens.mul(mintTokens[tokenIndex].mintPrice), "Claim: Ether value incorrect");
        
        
        return true;         

    }


   function isSaleOpen() public view returns (bool) {
            return !paused();
   }

    function getTokenSupply(uint256 tokenIndex) public view returns (uint256) {
        return totalSupply(tokenIndex);
    }
    
    function arrayIsUnique(uint256[] memory items) internal pure returns (bool) {
        // iterate over array to determine whether or not there are any duplicate items in it
        // we do this instead of using a set because it saves gas
        for (uint i = 0; i < items.length; i++) {
            for (uint k = i + 1; k < items.length; k++) {
                if (items[i] == items[k]) {
                    return false;
                }
            }
        }

        return true;
    }

    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        require(_to != 0x0000000000000000000000000000000000000000 , "cant send money to null address");
        _to.transfer(_amount);
    }

    function getClaimedMTs(uint256 _tokenIndex, address userAdress) public view returns (uint256) {
        return mintTokens[_tokenIndex].claimedMTs[userAdress];
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < mtCounter.current(), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), mintTokens[_id].ipfsMetadataHash));
    } 
}