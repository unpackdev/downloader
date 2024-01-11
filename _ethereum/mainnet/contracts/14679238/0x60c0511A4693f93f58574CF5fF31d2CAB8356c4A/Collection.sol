// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ProxyBaseStorage.sol";
import "./ERC721Enumerable.sol";
import "./CollectionStorage.sol";
import "./Ownable.sol";
/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract Collection is  ProxyBaseStorage, ERC721Enumerable, Ownable, CollectionStorage {
using Counters for Counters.Counter;

  constructor() ERC721("Galler Collection", "galler")  public {
    
  
  }
modifier isValid() {
  require(_allowAddress[msg.sender], "not authorize");
  _;
}
function changeLaunchPadAddress(address _add) isValid public {
  launchPadAddress = _add;
}
/**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }
 function getMaxLaunchpadSupply() public view returns (uint256){
         return maxLaunchPadSupply;
     }
     function getLaunchpadSupply() public view returns (uint256){
         return launchPadSupply.current();
     }

     modifier onlyLaunchpad() {
         require(msg.sender == launchPadAddress, "only launch pad");
         _;
     }

     function mintTo(address to, uint256 size) onlyLaunchpad public {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(maxLaunchPadSupply > 0,"no supply");
        require(launchPadSupply.current() + size <= maxLaunchPadSupply, "max supply reached");
        for (uint256 index = 0; index < size; index++) {
        tokenIds.increment();
        _safeMint(to, tokenIds.current());
        launchPadSupply.increment();
        dex.addBlindBoxData( address(this), to, tokenIds.current(),  royalty, authorAddress);
      }
        
    }

    function setLaunchPadConfig( uint256 _maxlaunchPadSupply, address _authorAddress, uint256 _royalty) onlyOwner public {
       maxLaunchPadSupply = _maxlaunchPadSupply;
      authorAddress = _authorAddress;
      royalty = _royalty;
   }

    /**
@notice function resposible of minting new NFTs of the collection.
 @param to_ address of account to whom newely created NFT's ownership to be passed
 @param countNFTs_ URI of newely created NFT
 Note only owner can mint NFT
 */
  function mint(address to_, uint256 countNFTs_) isValid() public returns (uint256, uint256) {
      uint from = tokenIds.current() + 1;
      for (uint256 index = 0; index < countNFTs_; index++) {
        tokenIds.increment();
        _safeMint(to_, tokenIds.current());
      }
      
    //   _setTokenURI(tokenIds.current(), tokenURI_);
    // TODO:
    // Base TokenURI logic to be added [DONE]
    // DEX modifications to support non-tokenURI and countNFTs minted

      return (from, tokenIds.current());
  }

  function burnAdmin(uint256 tokenId) isValid() public {
    _burn(tokenId);
    emit Burn(tokenId);
  }

  function TransferFromAdmin(uint256 tokenId, address to) isValid() public {
    _transfer(ERC721.ownerOf(tokenId), to, tokenId);
    emit AdminTransfer(ERC721.ownerOf(tokenId), to, tokenId);
  }
  function addAllowAddress(address _add) onlyOwner() public {
    _allowAddress[_add] = true;
  }

  
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
    emit BaseURI(baseURI);
  }

   /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) public view returns (uint256[] memory t) {
        unchecked {
            if (start > stop) return t;
            uint256 tokenIdsIdx;
            uint256 stopLimit = tokenIds.current() + 1;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIdsArr = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIdsArr;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            address ownership = _owners[start];
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (ownership != address(0x0)) {
                currOwnershipAddr = ownership;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _owners[i];
                if (ownership == address(0x0)) {
                    continue;
                }
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == owner) {
                    tokenIdsArr[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIdsArr, tokenIdsIdx)
            }
            return tokenIdsArr;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIdsArr = new uint256[](tokenIdsLength);
            address ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _owners[i];
                if (ownership == address(0x0)) {
                    continue;
                }
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == owner) {
                    tokenIdsArr[tokenIdsIdx++] = i;
                }
            }
            return tokenIdsArr;
        }
    }
  
  

  // events
  event BaseURI(string uri);
  event Burn(uint256 tokenId);
  event AdminTransfer(address from, address to, uint256 indexed tokenId);
}