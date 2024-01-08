// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 *                                   0  0
 *      0    0       0 0  0 0       00  00
 *    0000000000     00000000      00000000
 *    00 0000 00    0000  0000    00  00  00
 *    0000000000    0000000000    0000000000
 *      0    0        000000       000  000
 *     0 0  0 0        0  0       0        0
 *     0      0       0    0       0      0
 *
 *              _  _|_|         _
 *             |_). | |_     _ (_
 *             |_)| | |_)|_|(_| _)
 *                           _|
 *                 Enjoy life. 
 *
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./BitbugsData.sol";

/**
 *  @title Bitbugs
 *  @author Ladera Software Studio
 *  @notice This contract implements Bitbugs NFT logic
 *  @dev All function calls are currently implemented without side effects
 */
contract Bitbugs is ERC721, Ownable, Pausable, ReentrancyGuard, ERC721Enumerable, BitbugsData {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    
    /**
     *  @dev Event emitted when a bitbug is minted.
     */
    event Mint(uint indexed tokenId, address indexed minter);

    /**
     *  @dev Event emitted when a bitbug price is set to 0.
     */
    event FreeBitbug(uint indexed index, uint indexed tokenId, address indexed minter);
    
    /**
     *  @dev Event emitted when sale begins.
     */
    event SaleBegins();

    /**
     *  @dev Event emitted when sale ends.
     */
    event SaleEnds();

    string internal constant nftName = "Bitbugs";
    string internal constant nftSymbol = "BTG";
    
    /**
     *  @dev Signature to verify the image file containing all bitbugs.
     *  Image file: bitbugs.png
     *  IPFS: https://ipfs.io/ipfs/QmS85uvEnYsMHuHeDr8DVLxN3DQ9fXC2N1TGCcPi61bw71
     *  Signature obtained with ImageMagick version 6.8.9-9 Q16 x86_64 with Ubuntu 16.04
     */
    string internal constant imageSignature = "a26be426ce93142424ebaf0b86d8b6c48948d6901935895c594c9a3928ff2324";

    /**
     *  @dev Sha256 hash to verify the file containing each bitbug signature.
     *  Image file: bitbugs_signatures.txt
     *  IPFS: https://ipfs.io/ipfs/QmfJsmrnMPfSyzuAzoWtG1DMLdD2gF8KDAvYJ6HeEfhArf
     *  Each signature obtained with ImageMagick version 6.8.9-9 Q16 x86_64 with Ubuntu 16.04
     */
    string internal constant fileHash = "1e248091b102cfcb59f645e6ac388d6b4f51e7af268fbdb1233d7a95e4330116";
    
    uint internal constant TOKEN_LIMIT = 10800;
    uint public saleStartTime = block.timestamp;
    uint public saleStopTime;

    /**
     *  @dev mintPrice is 0.02 ETH (in wei).
     *  assert(1 wei == 1);
     *  assert(1 ETH == 1e18);
     */
    uint internal constant mintPrice = 20000000000000000;
    
    address payable immutable beneficiary;
    bool public sale = false;

    constructor(address payable _b) ERC721(nftName, nftSymbol) {
	beneficiary = _b;
    }


    /**
     * @dev Function to define decimal (not required but helps to configure eth wallet)
     * NFT lack decimals field (returns 0) since each token is distinct and cannot be partitioned.
     * returns uint8(0) - https://eips.ethereum.org/EIPS/eip-721
     */
    function decimals() public pure returns (uint) {
	return 0;
    }
    
    
    /**
     * @dev Function to start sale.
     * Requirements: Sale must be stopped.
     * Note: At contract's deployment sale is true.
     */
    function startSale() external onlyOwner {
	require(!sale, "Sale is active.");
	saleStartTime = block.timestamp;
	sale = true;
	emit SaleBegins();
    }

    
    /**
     * @dev Function to stop sale.
     * Requirements: Sale must be active.
     */
    function stopSale() external onlyOwner {
	require(sale, "Sale is closed.");
	saleStopTime = block.timestamp;
	sale = false;
	emit SaleEnds();
    }

    
    /**
     * @dev Function to pause the contract.
     * @notice ERC721Pausable-_pause.
     */
    function pause() external whenNotPaused onlyOwner {
    	_pause();
    }

    /**
     * @dev Function to return to normal.
     * @notice ERC721Pausable-_unpause.
     */
    function unpause() external whenPaused onlyOwner {
    	_unpause();
    }

    
    /**
     * @dev The owner can optionally mint 1000 bitbugs (without paying):
     * - 200 bitbugs can be traded.
     * - 800 bitbugs physically available at owners' discretion.
     * Developer can start minting after 50% of sale is made, so community can choose first.
     * @notice ERC721-_safeMint.
     */
    function devMint(uint[] memory tokens, address recipient) external onlyOwner {
	require(bitbugIdTracker.current() > 5400, "Not yet developer.");
	uint quantity = tokens.length;
	for (uint i = 0; i < quantity; i++) {
	    require(devMintTracker.current() < 1000, "Owner 1000 limit.");
	    devMintTracker.increment();
	    _safeMint(recipient, tokens[i]);
    	}
    }

    
    /**
     * @dev Function to retrieve number of bitbugs available to mint.
     * Note: ERC721-_burn not implemented so always decreasing.
     */
    function mintsRemaining() external view returns (uint) {
    	return TOKEN_LIMIT.sub(bitbugIdTracker.current());
    }

    
    /**
     * @dev Function to mint a bitbug.
     * Notes:
     * - tokenId is choosen by msg.sender in website in range [1,TOKEN_LIMIT]
     * - tokenId would be available on the emitted {IERC721-Transfer} event), 
     * - token URI autogenerated based on the base URI.
     * - Each 100th bitbug is free. 
     * - bitbugIdTracker [0,10799)
     * @return A tokenId if the operation was successful.
     * @notice ERC721-_safeMint.
     */
    function mint(uint256 tokenId) external payable whenNotPaused nonReentrant returns (uint) { 
	require(sale, "Sale is closed.");
	require(tokenId > 0, "Id at least 1.");
	require(tokenId <= TOKEN_LIMIT, "Id less than TOKEN_LIMIT.");
	require(bitbugIdTracker.current() < TOKEN_LIMIT, "TOKEN_LIMIT reached.");
	require(msg.value >= mintPrice, "Sender has insufficient funds.");

	uint price;
	if ( (bitbugIdTracker.current().add(1)).mod(100) == 0 ) { // Queries next bitbug to be minted ...
	    price = 0;
	    emit FreeBitbug(bitbugIdTracker.current().add(1), tokenId, msg.sender);
	} else {
	    price = mintPrice;
	}
	
	if (msg.value > price) { 
	    payable(msg.sender).transfer(msg.value.sub(price));
	}
	payable(beneficiary).transfer(price);
	_safeMint(msg.sender, tokenId);
	return tokenId; 
    }

    
    /**
     * @dev Owner can query beneficiary address set in constructor.
     */
    function getBeneficiary() external view onlyOwner returns (address) {
	return beneficiary;
    }


    /**
     * @dev Query how much Ether the contract has
     */
    function getBal() public view onlyOwner returns (uint) {
	return address(this).balance;
    }

    
    /**
     * @dev Withdraw ether from contract to beneficiary
     * Note: Might never be needed as mint transfer price to beneficiary.
     */
    function withdraw() public onlyOwner {
	payable(beneficiary).transfer(address(this).balance);
    }
    
    
    /* /\*****************/
    /*  *  METADATA      */
    /*  **************\/ */

    /**
     * @dev Base URI for computing {tokenURI}. 
     * The resulting URI is the concatenation of the `baseURI` and the `tokenId`. 
     * @notice ERC721Metadata-_baseURI (override).
     */
    function _baseURI() internal view virtual override returns (string memory) {
	return "https://www.bitbugs.info/api/token/";
    }

    
    /* /\*************** */
    /*  *  ENUMERABLE    */
    /*  **************\/ */

    /**
     * @dev Both ERC721 and ERC721Enumerable implement _beforeTokenTransfer.
     * @notice Calls parents hook with super before overriding.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
	super._beforeTokenTransfer(from, to, tokenId);  
	if (from == address(0)) {
	    bitbugIdTracker.increment();
	    mintedBitbugs.push(tokenId);
	    emit Mint(tokenId, msg.sender);
	}
    }

    
    /**
     * @dev Both ERC721 and ERC721Enumerable implement supportsInterface.
     * @notice ERC165-supportsInterface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
	return super.supportsInterface(interfaceId);
    }

}
