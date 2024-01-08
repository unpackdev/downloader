// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./Ownable.sol";


contract LockableToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint => uint) public tokenLockedFromTimestamp;
    mapping (uint => bytes32) public tokenUnlockCodeHashes;
    mapping (uint => bool) public tokenUnlocked;

    string private _baseTokenURI;

    event TokenUnlocked(uint tokenId, address unlockerAddress);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(tokenLockedFromTimestamp[tokenId] > block.timestamp || tokenUnlocked[tokenId], "LockableToken: Token locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function unlockToken(bytes32 unlockHash, uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "LockableToken: Only the Owner can unlock the Token"); //not 100% sure about that one yet
        require(keccak256(abi.encode(unlockHash)) == tokenUnlockCodeHashes[tokenId], "LockableToken: Unlock Code Incorrect");
        tokenUnlocked[tokenId] = true;
        emit TokenUnlocked(tokenId, msg.sender);
    }

    /**
    * This one is the mint function that sets the unlock code, then calls the parent mint
    */
    function mint(address to, uint lockedFromTimestamp, bytes32 unlockHash) public {
        tokenLockedFromTimestamp[_tokenIds.current()] = lockedFromTimestamp;
        tokenUnlockCodeHashes[_tokenIds.current()] = unlockHash;
        
         require(msg.sender == owner(), "LockableToken: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIds.current());
        _tokenIds.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       return string(abi.encodePacked(abi.encodePacked(super.tokenURI(tokenId),".json")));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract ERC2981Rarible is Ownable, RoyaltiesV2Impl  {
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    struct RoyaltyPercentages {
        uint96 percentage;
        address beneficiary;
    }

    mapping(uint => RoyaltyPercentages) public tokenHasRoyaltyPercentage;

     function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (tokenHasRoyaltyPercentage[_tokenId].beneficiary, (tokenHasRoyaltyPercentage[_tokenId].percentage * _salePrice) / 10000);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        tokenHasRoyaltyPercentage[_tokenId].beneficiary = _royaltiesReceipientAddress;
        tokenHasRoyaltyPercentage[_tokenId].percentage = _percentageBasisPoints;
        _saveRoyalties(_tokenId, _royalties);
    }
   
}

contract AisthisiToken is ERC2981Rarible, LockableToken  {
    constructor() LockableToken("Aisthisi", "AIS", "https://aisthisi.art/metadata/") {}

     function supportsInterface(bytes4 interfaceId) public view virtual override(LockableToken) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == ERC2981Rarible._INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

}