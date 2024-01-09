// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Wicked is ERC721A, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;
  uint256 private _mintCost;
  uint256 private _maxSupply;
  bool private _isPublicMintEnabled;
  uint256 private _freeSupply;
  
  string private _tokenBaseURI = "ipfs://QmVQpiCuQmURdqwpVqCij7K62kkcvUyTLCn7FjnA2YRxtw/";


  /**
  * @dev Initializes the contract setting the `tokenName` and `symbol` of the nft, `cost` of each mint call, and maximum `supply` of the nft.
  * Note: `cost` is in wei. 
  */

   constructor() ERC721A("Wicked Gorilla Warriors", "WGW") Ownable() {
    _mintCost = 0.03 ether;
    _maxSupply = 1337;
    _isPublicMintEnabled = false;
    _freeSupply = 500;
  }

  /**
  * @dev Changes contract state to enable public access to `mintTokens` function
  * Can only be called by the current owner.
  */
  function allowPublicMint()
  public
  onlyOwner{
    _isPublicMintEnabled = true;
  }

  /**
  * @dev Changes contract state to disable public access to `mintTokens` function
  * Can only be called by the current owner.
  */
  function denyPublicMint()
  public
  onlyOwner{
    _isPublicMintEnabled = false;
  }

  /**
  * @dev Mint `count` tokens if requirements are satisfied.
  * 
  */
  function mintTokens(uint256 count)
  public
  payable
  nonReentrant{
    require(_isPublicMintEnabled, "Mint disabled");
    require(count > 0 && count <= 20, "You can drop minimum 1, maximum 20 NFTs");
    require(count.add(totalSupply()) < (_maxSupply+1), "Exceeds max supply");
    require(owner() == msg.sender || msg.value >= _mintCost.mul(count),
           "Ether value sent is below the price");
    
    _mint(msg.sender, count);
  }

  /**
  * @dev Mint a token to each Address of `recipients`.
  * Can only be called if requirements are satisfied.
  */
  function mintTokensTo(address[] calldata recipients)
  public
  payable
  nonReentrant{
    require(recipients.length>0,"Missing recipient addresses");
    require(owner() == msg.sender || _isPublicMintEnabled, "Mint disabled");
    require(recipients.length > 0 && recipients.length <= 20, "You can drop minimum 1, maximum 20 NFTs");
    require(recipients.length.add(totalSupply()) < (_maxSupply+1), "Exceeds max supply");
    require(owner() == msg.sender || msg.value >= _mintCost.mul(recipients.length),
           "Ether value sent is below the price");
    for(uint i=0; i<recipients.length; i++){
        _mint(recipients[i], 1);
     }
  }

  /**
  * @dev Mint `count` tokens if requirements are satisfied.
  */
  function freeMint(uint256 count) 
  public 
  payable 
  nonReentrant{
    require(owner() == msg.sender || _isPublicMintEnabled, "Mint disabled");
    require(totalSupply() + count <= _freeSupply, "Exceed max free supply");
    require(count == 1, "Cant mint more than 1");
    require(count > 0, "Must mint at least 1 token");

    _safeMint(msg.sender, count);
  }

  /**
  * @dev Update the cost to mint a token.
  * Can only be called by the current owner.
  */
  function setCost(uint256 cost) public onlyOwner{
    _mintCost = cost;
  }

  /**
  * @dev Update the max supply.
  * Can only be called by the current owner.
  */
  function setMaxSupply(uint256 max) public onlyOwner{
    _maxSupply = max;
  }

  /**
  * @dev Update the max free supply.
  * Can only be called by the current owner.
  */
  function setFreeSupply(uint256 max) public onlyOwner{
    _freeSupply = max;
  }

  /**
  * @dev Transfers contract balance to contract owner.
  * Can only be called by the current owner.
  */
  function withdraw() public onlyOwner{
    payable(owner()).transfer(address(this).balance);
  }

  /**
  * @dev Used by public mint functions and by owner functions.
  * Can only be called internally by other functions.
  */
  function _mint(address to, uint256 count) internal virtual returns (uint256){
    _safeMint(to, count);

    return count;
  }

  function getCost() public view returns (uint256){
    return _mintCost;
  }
  function getMaxSupply() public view returns (uint256){
    return _maxSupply;
  }
  function getCurrentSupply() public view returns (uint256){
    return totalSupply();
  }
  function getMintStatus() public view returns (bool) {
    return _isPublicMintEnabled;
  }
  function getFreeSupply() public view returns (uint256) {
    return _freeSupply;
  }
  function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
  }
  function _baseURI() override internal view returns (string memory) {
    return _tokenBaseURI;
  }

}