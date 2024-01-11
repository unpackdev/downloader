// SPDX-License-Identifier: MIT
// RightClik NFT collection contract

/*

``````````````````$$$$$
`````````````$$$$$$´´´´$$$$$$
``````````$$$´´´´´´´´´´´´´´´´$$$
````````$`$$´´´´´´´´´´´´´´´´´´´´$$
```````$´$$$´´´´´´´´´´´´´´´´´´´´´$$$$
`````$´´$$$$´´´´´´´´´´´´´´´´´´´´´´´´´´$
````$´´$$$$$´´´´´´´´´´$$$$$$$´´´´´´´´´$$
```$´´´$$$$$$$´´´$$$$$$$$$$$$$$$$$´´´´´$$
``$´´´´$$$$$$$$$$$$$$$$$$$$$$$$$$$$$´´´´$$
`$´´´´´´$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$´´$
`$´´´´´´$$$$$$$$$$$´´´´$$$$$$$$$$$$$$$$$$$
$´´´´´´´´$$$$$$$$´´´´´´´´$$$$$$$´´´´´´´´$$
$´´´´´´´´´$$$$$$´´´´´´´´´´$$$$´´´´´´´´´´´$
`$´´´´´´´´´$$$$$´´´´´´´´´´$$$´´´´´´´´´´´$
`$´´´´´´´´´´$$$$$´´´´´´´´$$$$´´´´´´´´´´´$
`$´´´´´´´´´´´$$$$$$´´´´$$$$$´´´´´´´´´´´$$
``$´´´´´´´´´´´$$$$$$$$$$$$$$´´´´´´´´´´´$
``$$´´´´´´´´´´´´$$$$$$$$$$$$´´´´´´´´´´$$
```$$´´´´´´´´´´´´$$$$$$$$$$´´´´´´´´´´$$
````$´´´´´´´´´´´´$$$$$$$$$´´´´´´´´´´´$
`````$´´´´´´´´´´´$$$$$$$$´´´´´´´´´´´$
``````$$´´´´´´´´´$$$$$$´´´´´´´´´´´$$
````````$$´´´´´´$$$$$´´´´´´´´´´´$$
``````````$$$´$$$$´´´´´´´´´´´$$$
`````````````$$$$$´´´´´´$$$$$
``````````````````$$$$$$

*/

pragma solidity ^0.8.13;

import "./IERC165.sol";
import "./IERC721Metadata.sol";
import "./IERC1155MetadataURI.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ERC721A.sol";

/**
 * @title A right click tool NFT contract
 * @author jack.liu
 *
 * @notice Implementation of right click NFT function based on openzepping's ERC721 contract.
 * player can synthesize a new NFT in this contract from existing NFT collection.
 * player has to pay some ether for synthesizing, he can refund the ether when burning the 
 * new NFT.
 *
 * @dev the existing NFT or ERC1155 contract must implement ERC165 standard.
 */
contract RightClik is ERC721A {

  /// mapping from new tokenId to original contract address
  mapping(uint256 => address) public tokenIdToContract;
  
  /// mapping from new tokenId to original tokenId
  mapping(uint256 => uint256) public tokenIdToOriTokenId;

  /// used to keep unique original existing NFT.
  mapping(address => mapping(uint256 => uint256)) public uniques;
  
  /// mapping from tokenId to ether balance which change when mint, transfer
  mapping(uint256 => uint256) public etherBalances;

  /// constant interface signator for ERC721
  bytes4 constant internal INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;

  /// constant interface signator for ERC1155
  bytes4 constant internal INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /// bonding curve M parameter, bonding curve formula is y = mx^2
  uint256 constant internal BOND_CURVE_M = 1 * 10**8;
  
  /// base ether price for minting
  uint256 constant internal BASE_PRICE = 0.001 ether;

  // max NFT total supply
  uint256 constant internal MAX_TOTAL_SUPPLY = 50000;

  // free mint amount 
  uint256 constant internal FREE_MINT_AMOUNT = 1000;

  /**
   * @dev Emitted when `newTokenId` token is minted to `to` based on `contractAddr` and `tokenId`, msg.sender will pay `amount` ether.
   */
  event Mint(address indexed to, address indexed contractAdddr, uint256 indexed tokenId, uint256 newTokenId, uint256 amount);

  /**
   * @dev Emitted when `tokenId` token is burnt, `amount` is leftover ether before burn.
   */
  event Refund(uint256 indexed tokenId, uint256 amount);

  /**
   * @dev contruct a new ERC721 collection
   * @param name NFT collection name
   * @param symbol NFT collection symbol
   */
  constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
  }

  /**
   * @dev calculate current ether price for minting based on NFT total supply
   * @return uint256 ether price for minting
   */
  function calcMintPrice() public view returns (uint256) {
    uint totalSupply = totalSupply();
    if(totalSupply < FREE_MINT_AMOUNT) {
      return 0;
    }
    return BASE_PRICE + BOND_CURVE_M * totalSupply * totalSupply;
  }

  /**
   * @dev Get the delegated original URI from new generated tokenId.
   * @param tokenId The id of the token.
   * @return string memory url of originial NFT 
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "RightClik: URI query for nonexistent token");

    IERC165 tokenInterface = IERC165(tokenIdToContract[tokenId]);

    address originContract = tokenIdToContract[tokenId];
    uint originTokenId = tokenIdToOriTokenId[tokenId];

    string memory uri;

    if(tokenInterface.supportsInterface(INTERFACE_SIGNATURE_ERC1155)) {
      uri = IERC1155MetadataURI(originContract).uri(originTokenId);
    } else
    if(tokenInterface.supportsInterface(INTERFACE_SIGNATURE_ERC721)) {
      uri = IERC721Metadata(originContract).tokenURI(originTokenId);
    } else {
      revert("only support 721 or 1155 token");
    }

    uri = stringReplace(uri, "0x{id}", Strings.toHexString(originTokenId));
    uri = stringReplace(uri, "{id}", Strings.toString(originTokenId));

    return uri;
  }

  /**
   * @dev check if token exist.
   * @param tokenId The id of the token.
   * @return bool 
   */
  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /**
    * override To change the starting tokenId, .
    */
  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

  /**
   * @dev synthetic new NFT from existing NFT, in this contract tokenURI() will return the original URI,
   * every mint will charge some ether.
   *
   * @param to owner of new synthetic Token
   * @param contractAddr contract address of existing NFT collection, must implement tokenURI function
   * @param tokenId tokenId of existing NFT
   * @return uint256 minted new tokenId of this NFT collection
   */
  function mint(
    address to, 
    address contractAddr, 
    uint256 tokenId
    ) payable external returns (uint256) {

    uint price = calcMintPrice();
    require(msg.value >= price, "RightClik: insufficient ether"); 

    require(uniques[contractAddr][tokenId] == 0, "RightClik: already minted");

    require(totalSupply() < MAX_TOTAL_SUPPLY, "RightClik: already max totalSupply");

    uint curr = _currentIndex;
    uniques[contractAddr][tokenId] = curr;

    tokenIdToContract[curr] = contractAddr;
    tokenIdToOriTokenId[curr] = tokenId;

    if(msg.value > 0) {
      etherBalances[curr] += msg.value;
    }

    _mint(to, 1);

    emit Mint(to, contractAddr, tokenId, curr, msg.value);
    return curr;
  }  

  /**
   * @dev burn token and return the mint price to the token owner.
   * @param tokenId The id of the token to refund.
   */
  function refund(uint256 tokenId) external {
    require(_exists(tokenId), "RightClik: refund for nonexistent token");
    require(ownerOf(tokenId) == msg.sender, "RightClik: must own token");
    
    _burn(tokenId);

    uint256 amount = etherBalances[tokenId];
    address contractAddr = tokenIdToContract[tokenId];
    uint256 oriTokenId = tokenIdToOriTokenId[tokenId];

    delete uniques[contractAddr][oriTokenId];
    delete tokenIdToContract[tokenId];
    delete tokenIdToOriTokenId[tokenId];
    delete etherBalances[tokenId];

    // Refund the token owner the mint price.
    if(amount > 0) {
      Address.sendValue(payable(msg.sender), amount);
    }

    emit Refund(tokenId, amount);
  }

  /**
   * @dev utils bytes compare function used by stringReplace
   */
  function bytesCompare(
    bytes memory buf, 
    uint idx, 
    bytes memory rep
    ) internal pure returns (bool) {

    if((buf.length-idx) < rep.length) {
        return false;
    }

    for(uint i=0; i<rep.length; i++) {
        if(buf[i+idx] != rep[i]) {
            return false;
        }
    }
    return true;
  }

  /**
   * @dev utils string function to replace '0x{id}' to actual tokenId
   */
  function stringReplace(
    string memory str, 
    string memory src, 
    string memory dst
    ) internal pure returns (string memory) {

    bytes memory bstr = bytes(str);
    bytes memory bsrc = bytes(src);
    bytes memory bdst = bytes(dst);

    uint len = 0;
    for(uint i=0; i<bstr.length; i++) {
        if(bytesCompare(bstr, i, bsrc)) {
            len = len + bdst.length;
            i += bsrc.length - 1;
        } else {
            len++;
        }
    }

    bytes memory ret = new bytes(len);
    uint j = 0;
    for(uint i=0; i<bstr.length; i++) {
        if(bytesCompare(bstr, i, bsrc)) {
            for(uint k=0; k<bdst.length; k++) {
                ret[j++] = bdst[k];
            }
            i += bsrc.length - 1;
        } else {
            ret[j++] = bstr[i];
        }
    }

    return string(ret);
  } 

}



