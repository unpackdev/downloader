// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// @title: This Shard Does Not Exist
// @author: Jonathan Howard

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
// ████████╗██╗░░██╗██╗░██████╗  ░██████╗██╗░░██╗░█████╗░██████╗░██████╗░  //
// ╚══██╔══╝██║░░██║██║██╔════╝  ██╔════╝██║░░██║██╔══██╗██╔══██╗██╔══██╗  //
// ░░░██║░░░███████║██║╚█████╗░  ╚█████╗░███████║███████║██████╔╝██║░░██║  //
// ░░░██║░░░██╔══██║██║░╚═══██╗  ░╚═══██╗██╔══██║██╔══██║██╔══██╗██║░░██║  //
// ░░░██║░░░██║░░██║██║██████╔╝  ██████╔╝██║░░██║██║░░██║██║░░██║██████╔╝  //
// ░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═════╝░  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░  //
//                                                                         //
//      ██████╗░░█████╗░███████╗░██████╗  ███╗░░██╗░█████╗░████████╗       //
//      ██╔══██╗██╔══██╗██╔════╝██╔════╝  ████╗░██║██╔══██╗╚══██╔══╝       //
//      ██║░░██║██║░░██║█████╗░░╚█████╗░  ██╔██╗██║██║░░██║░░░██║░░░       //
//      ██║░░██║██║░░██║██╔══╝░░░╚═══██╗  ██║╚████║██║░░██║░░░██║░░░       //
//      ██████╔╝╚█████╔╝███████╗██████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░       //
//      ╚═════╝░░╚════╝░╚══════╝╚═════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░       //
//                                                                         //
//                ███████╗██╗░░██╗██╗░██████╗████████╗                     //
//                ██╔════╝╚██╗██╔╝██║██╔════╝╚══██╔══╝                     //
//                █████╗░░░╚███╔╝░██║╚█████╗░░░░██║░░░                     //
//                ██╔══╝░░░██╔██╗░██║░╚═══██╗░░░██║░░░                     //
//                ███████╗██╔╝╚██╗██║██████╔╝░░░██║░░░                     //
//                ╚══════╝╚═╝░░╚═╝╚═╝╚═════╝░░░░╚═╝░░░                     //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

// OpenZeppelin
import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./IERC2981.sol";
import "./Ownable.sol";

import "./FNTNConverter.sol";

interface FntnInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ThisShardDoesNotExist is IERC2981, ERC721, Ownable, ReentrancyGuard, FNTNConverter {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using Strings for string;

  // Max NFTs total
  uint public constant MAX_TOKENS = 666;

  // Price in gwei per shard (0.069 ETH)
  uint public constant SHARD_PRICE = 69000000000000000;

  // Allow for starting/pausing sale
  bool public hasSaleStarted = false;

  // Next tokenId eligible to be minted
  // First 175 are reserved for shard-hodlers
  uint internal nextTokenId = 176;

  //FNTN Contract
  FntnInterface fntnContract = FntnInterface(0x2Fb704d243cFA179fFaD4D87AcB1D36bcf243a44);

	// Royalty, in basis points
	uint8 internal royaltyBPS = 100;

  // ERC2891 royalty function, for ERC2891-compatible platforms. See IERC2891
	function royaltyInfo(uint256, uint256 _salePrice) override external view returns (
      address receiver, uint256 royaltyAmount) {
		return (owner(), (_salePrice * royaltyBPS) / 10_000);
	}

  // Update it need be, but no ability to rug
	function updateRoyaltyBPS(uint8 newRoyaltyBPS) public onlyOwner {
		require(royaltyBPS <= 300, "No royalty greater than 30%");
		royaltyBPS = newRoyaltyBPS;
	}

  /*
   * Set up the basics
   *
   * @dev It will NOT be ready to start sale immediately upon deploy
   */
  constructor(string memory baseURI) ERC721("This Shard Does Not Exist","AIFNTN") {
    setBaseURI(baseURI);
  }

  /*
   * Get the tokens owned by _owner
   */
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  /*
   * Main function for the sale
   *
   * prerequisites
   *  - not at max supply
   *  - sale has started
   */
  function mint() external payable nonReentrant {
    require(nextTokenId <= MAX_TOKENS, "We are at max supply");
    require(hasSaleStarted, "Sale hasn't started");
    require(msg.value == SHARD_PRICE, "Ether value required is 0.069");

    _safeMint(msg.sender, nextTokenId++);
  }

  /*
   * Buy the token reserved for your shard
   *
   * Prerequisites:
   *  - not at max supply
   *  - sale has started
   *  - your wallet owns the shard ID in question
   *
   * Example input: To mint for FNTN // 137, you would not input
   * 137, but the tokenId in its shared contract. If you don't know this
   * ID, your best bet is the website. But it will also be after the final '/'
   * in the URL of your shard on OpenSea, eg https://opensea.io/0xetcetcetc/shardId
   */
  function mintWithShard(uint tokenId) external payable nonReentrant {
    require(hasSaleStarted, "Sale hasn't started");
    require(msg.value == SHARD_PRICE, "Ether value required is 0.069");
    // Duplicate this here to potentially save people gas
    require(tokenId >= 1229 && tokenId <= 1420, "Enter a sharId from 1229 to 1420");

    // Ensure sender owns shard in question
    require(fntnContract.ownerOf(tokenId) == msg.sender, "Not the owner of this shard");

    // Convert to the shard ID (the number in "FNTN // __")
    uint shardId = tokenIdToShardId(tokenId);

    // Mint if token doesn't exist
    require(!_exists(shardId), "This token has already been minted");
    _safeMint(msg.sender, shardId);
  }

  // TODO: selector for 2981
	// Handy while calculating XOR of all function selectors
	function calculateSelector() public pure returns (bytes4) {
		return type(IERC2981).interfaceId;
	}

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
    return ERC165.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(
			baseURI(),
			Strings.toString(tokenId),
			"/index.json"
		));
  }
    

  // Admin functions
  function setFntnContract(address contractAddress) public onlyOwner {
    fntnContract = FntnInterface(contractAddress);
  }

  function getFntnContract() public view returns(address) {
    return address(fntnContract);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function getNextPublicTokenId() public view returns(uint) {
    return nextTokenId;
  }

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

	function withdrawAll() external onlyOwner {
		// This forwards all available gas. Be sure to check the return value!
		(bool success, bytes memory data) = msg.sender.call{value: address(this).balance}("");
		require(success, "Transfer failed.");
	}
}
