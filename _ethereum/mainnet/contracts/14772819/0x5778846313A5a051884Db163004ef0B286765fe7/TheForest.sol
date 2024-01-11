// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/ether-tree/TheForest.sol)
// https://omnuslab.com/ethertree
// https://ethertree.org

// EtherTree 100 total supply ERC721

/**
*
* @dev EtherTree
*
* Distribution contract for the ether tree project. This token implements a few innovations:
* - Pre minted token supply. The total supply was minted on contract creation (which saves gas). 
* - All metadata is revealed, opensea site is up etc. so people know exactly what they are buying in to.
* - Which creates the issue of random assignment, which is solved by RandomlyAlloacted and IceRing, in their first mainnet incarnation.
*   For more details see  https://omnuslab.com/RandomlyAllocated and https://omnuslab.com/IceRing
*/

pragma solidity ^0.8.13;
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./RandomlyAllocatedEtherTree.sol"; 

/**
*
* @dev Contract implements RandomlyAllocated and IceRing (which is in RandomlyAllocated)
*
*/
contract TheForest is Ownable, RandomlyAllocated, IERC721Receiver {

  IERC721 public immutable etherTree; 
  IERC721 public immutable wassiesByWassies;
  address payable public immutable etherTreesury; 
  address public immutable ice; 
  address public immutable oat; 

  uint256 public constant PRICE        =  5000000000000000; // 0.005 eth
  uint256 public constant WASSIE_PRICE =  1000000000000000; // 0.001 eth

  mapping(address => bool) private youveGotOneAlready;

  constructor(address etherTree_, address wassiesByWassies_, address payable etherTreesury_, address ice_, address oat_) 
    RandomlyAllocated(100, oat_, ice_, 0, 0, 0) {
    
    etherTree = IERC721(etherTree_);
    wassiesByWassies = IERC721(wassiesByWassies_);
    etherTreesury = etherTreesury_;
    ice = ice_;
    oat = oat_;
  }

  /**
  *
  * @dev Events
  *
  */
  event EthWithdrawal(uint256 indexed withdrawal);

  /**
  *
  * @dev Do not accept random calls:
  *
  */
  
  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }

  /** 
  *
  * @dev owner can withdraw eth to treasury:
  *
  */ 
  function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = etherTreesury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount);
    return true;
  }

  /**
  *
  * @dev claimTree
  *
  */
  function claimTree(bool wassie) payable external {

    uint256 requiredPrice;
    if (wassie) {
      requiredPrice = WASSIE_PRICE;
    }
    else {
      requiredPrice = PRICE;
    }

    bool isEligible;
    string memory reason;

    (isEligible, reason) = canClaimATree(wassie, msg.value, requiredPrice);

    require(isEligible, reason);

    // Send them their randomly selected tree!
    etherTree.safeTransferFrom(address(this), msg.sender, _getItem(0));

    youveGotOneAlready[msg.sender] = true;

  }

  /**
  *
  * @dev canClaimATree - check is the caller address is eligible
  *
  */
  function canClaimATree(bool wassie, uint256 payment, uint256 price) public view returns(bool isEligible, string memory message) {

    // 1) See if they have already claimed one - it's one per address:
    if (youveGotOneAlready[msg.sender]) {
      return(false, "Hey, one each please!");
    }

    // 2) Check passed payment:
    if (payment != price) {
      return(false, "Incorrect ETH amount passed.");
    }

    // 3) If claiming to be a wassie, check for a wassie:
    if (wassie && wassiesByWassies.balanceOf(msg.sender) < 1) {
      return(false, "Must have a wassie for this price. Pay normie price, or checkout yellowbird.ethertree.org");
    }

    // 3) If claiming to not be a wassie, check for a wassie:
    if (!wassie && wassiesByWassies.balanceOf(msg.sender) > 0) {
      return(false, "You have a wassie! Press the other button it's cheaper!");
    }

    // 4) We got here? Good to go:
    return(true, "");

  }

  /**
  *
  * @dev onERC721Received: Always returns `IERC721Receiver.onERC721Received.selector`. We need this to custody NFTs on the contract:
  *
  */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

}