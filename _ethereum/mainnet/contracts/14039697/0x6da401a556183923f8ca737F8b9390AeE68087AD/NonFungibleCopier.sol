// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC1155.sol";

import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract NonFungibleCopier is ERC721Enumerable {
    using Strings for uint256;

    uint constant TONER_CAPACITY = 6000;
    uint constant MAX_COPIES_PER_NFT = 3;

    address constant DEV_WALLET = 0xF5C01c1E2E4676c874fbC91238595e1ce058AdF0;
    address constant TBD_WALLET = 0xd1d6c54260953fa3fA9d4096AA688d08eD5bf361;
    
    string private baseUri;
    bool private useExtension;
    bool private lockUri;
    bool private enabled;

    struct Photocopy {
        address originalContract;
        uint originalId;
        uint copyNumber;
    }

    mapping(address => mapping(uint => uint[])) private photocopyIds;
    mapping(address => uint) private freeCopies;
    mapping(uint => Photocopy) private photocopies;

    event NewPhotocopy(uint id);

    error NotFound(uint256 id);
    error Disabled();
    error SupplyCap();
    error InvalidCopyAmount();
    error WrongValue();
    error NotOwner();
    error CopyOfCopy();
    error EmptyBalance();
    error FailedTx();
    error LockedUri();
    
    constructor() ERC721("NonFungibleCopier", "COPY") {
        baseUri = "https://server.nonfungiblecopier.com/photocopy/";
    }

    modifier onlyOwners() {
        if (_msgSender() != DEV_WALLET && _msgSender() != TBD_WALLET) { revert NotOwner(); }
        _;
    }

    function isEnabled() public view returns (bool) {
        return enabled;
    }

    function getCopies(address nftContract, uint nftId) public view returns (uint[] memory) {
        return photocopyIds[nftContract][nftId];
    }

    function numberOfCopies(address nftContract, uint nftId) public view returns (uint) {
        return photocopyIds[nftContract][nftId].length;
    }

    function copiesAvailable(address nftContract, uint nftId) public view returns (uint) {
        uint totalCopiesLeft = TONER_CAPACITY - totalSupply();
        uint nftCopiesLeft = MAX_COPIES_PER_NFT - numberOfCopies(nftContract, nftId);
        if (nftCopiesLeft <= totalCopiesLeft) {
            return nftCopiesLeft;
        }
        return totalCopiesLeft;
    }

    function getCost(address minter, address nftContract, uint nftId, uint copies) public view returns (uint, uint) {
        if ((totalSupply() + copies) > TONER_CAPACITY) { revert SupplyCap(); }
        if ((photocopyIds[nftContract][nftId].length + copies) > MAX_COPIES_PER_NFT) { revert InvalidCopyAmount(); }

        uint availableFreeCopies = freeCopies[minter];
        uint usedFreeCopies = 0;

        uint startingCopy = photocopyIds[nftContract][nftId].length;
        uint totalCost;

        for (uint i=0; i< copies; i++) {
            if ((availableFreeCopies - usedFreeCopies) == 0) {
                if ((startingCopy + i) == 0) { totalCost += 12000000000000000; }
                if ((startingCopy + i) == 1) { totalCost += 23000000000000000; }
                if ((startingCopy + i) == 2) { totalCost += 35000000000000000; }
            } else {
                usedFreeCopies++;
            }
        }

        return (totalCost, usedFreeCopies);
    }

    function copy(address nftContract, uint nftId, bool is721, uint copies) public payable {
        if (!enabled) { revert Disabled(); }
        if (nftContract == address(this)) { revert CopyOfCopy(); }

        (uint totalCost, uint usedFreeCopies) = getCost(_msgSender(), nftContract, nftId, copies);

        if (msg.value != totalCost) { revert WrongValue(); }
        
        if (is721) {
           if (IERC721(nftContract).ownerOf(nftId) != _msgSender()) { revert NotOwner(); }
        } else {
            if (IERC1155(nftContract).balanceOf(_msgSender(), nftId) == 0) { revert NotOwner(); }
        }

        uint startingTokenId = totalSupply();
        uint startingCopies = photocopyIds[nftContract][nftId].length;
        
        for (uint i=0; i<copies; i++) {
            Photocopy memory newCopy;
            newCopy.originalContract = nftContract;
            newCopy.originalId = nftId;
            newCopy.copyNumber = startingCopies + i;

            uint newTokenId = startingTokenId + i;
            photocopies[newTokenId] = newCopy; 
            _safeMint(_msgSender(), newTokenId);
            emit NewPhotocopy(newTokenId);

            photocopyIds[nftContract][nftId].push(newTokenId);
        }

        if (usedFreeCopies > 0) {
            freeCopies[_msgSender()] -= usedFreeCopies;
        }
    }

    function getCopyInfo(uint copyId) public view returns (address, uint, uint) {
        if (!_exists(copyId)) { revert NotFound(copyId); }
        return (photocopies[copyId].originalContract, photocopies[copyId].originalId, photocopies[copyId].copyNumber);
    }
    
    function setEnable(bool b) public onlyOwners {
        enabled = b;
    }

    function setFreeCopies(address minter, uint copies) public onlyOwners {
        freeCopies[minter] = copies;
    }

    function freeCopiesAvailable(address minter) public view returns (uint) {
        return freeCopies[minter];
    }

    function withdraw() public onlyOwners {
        uint amount = address(this).balance;
        if(amount == 0) { revert EmptyBalance(); }
        (bool transfer1,) = payable(DEV_WALLET).call{value: amount/2}("");
        (bool transfer2,) = payable(TBD_WALLET).call{value: amount - (amount/2)}("");
        if (!(transfer1 && transfer2)) {revert FailedTx(); }
    }

    function tokenURI(uint256 copyId) public view override returns (string memory) {
        if (!_exists(copyId)) { revert NotFound(copyId); }
        return string(abi.encodePacked(_baseURI(), copyId.toString(), useExtension?".json":""));
    }

    function setBaseURI(string memory newUri, bool extension, bool lock) public onlyOwners {
        if(lockUri) { revert LockedUri(); }
        lockUri = lock;
        baseUri = newUri;
        useExtension = extension;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}