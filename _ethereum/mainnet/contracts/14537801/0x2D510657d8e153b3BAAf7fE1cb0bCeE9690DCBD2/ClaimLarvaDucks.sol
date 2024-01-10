// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

contract ClaimLarvaDucks is Ownable, ReentrancyGuard, IERC721Receiver {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // Set of approved controllers
    EnumerableSet.AddressSet contractController;
    // Set of owned LD
    EnumerableSet.UintSet claimableLarvaDucks;

    // LarvaDucks
    address public larvaDucksAddress;
    ERC721 LarvaDucksNFT;

    // Mapping has claimed collection
    mapping(address => mapping(address => bool)) public walletHasClaimedCollection;
    // Mapping of collections allow listed
    mapping(address => bool) public isCollectionAllowListed;

    // Array of collections allow listed
    address[] public allowListedCollections;

    uint256 public claimPerCollection = 2;

    bool public claimOpened;

    event LarvaDucksClaimed(address indexed claimer, uint256 id);
    event ContractControllerEvent(address indexed controller, bool allowed);

    constructor(address _larvaDucksAddress) {
        larvaDucksAddress = _larvaDucksAddress;
        LarvaDucksNFT = ERC721(_larvaDucksAddress);
    }

    // Claim for a list of collections
    function claimForCollections(address wallet, address[] calldata collections) external nonReentrant {
        require(claimOpened, 'Claim is closed');
        uint256 count;
        for (uint256 i; i<collections.length; i++) {
            address collection = collections[i];
            if (isClaimAvailableForCollection(wallet, collection)) {
                walletHasClaimedCollection[wallet][collection] = true;
                count += claimPerCollection;
            }
        }
        require(count > 0, 'No LarvaDucks to claim');
        require(count <= claimableLarvaDucks.length(), 'Not enough LarvaDucks available to claim');
        _claimLarvaDucks(wallet, count);
    }

    // Add allow listed collection
    function addAllowListedCollection(address collection) external onlyAllowed {
        isCollectionAllowListed[collection] = true;
        allowListedCollections.push(collection);
    }

    // Remove allow listed collection
    function removeAllowListedCollection(uint256 indexCollection) external onlyAllowed {
        address collection = allowListedCollections[indexCollection];
        isCollectionAllowListed[collection] = false;
        allowListedCollections[indexCollection] = allowListedCollections[allowListedCollections.length - 1];
        allowListedCollections.pop();
    }

    // Is claim available for a specific collection
    function isClaimAvailableForCollection(address wallet, address collection) public view returns (bool) {
        return isCollectionAllowListed[collection] &&
                !walletHasClaimedCollection[wallet][collection] &&
                ERC721(collection).balanceOf(wallet) > 0;
    }

    // List of allow listed collections
    function getAllowListedCollections() external view returns (address[] memory) {
        return allowListedCollections;
    }

    // List of held LarvaDucks
    function getClaimableLarvaDucks() external view returns (uint256[] memory) {
        uint256[] memory ld = new uint256[](claimableLarvaDucks.length());
        for (uint256 i; i<claimableLarvaDucks.length(); i++) {
            ld[i] = claimableLarvaDucks.at(i);
        }
        return ld;
    }

    // List of collections where claim is available
    function getClaimableCollections(address wallet) public view returns (address[] memory) {
        uint256 count;
        address[] memory claimableCollections = new address[](allowListedCollections.length);
        for (uint256 i; i<allowListedCollections.length; i++) {
            address collection = allowListedCollections[i];
            if (isClaimAvailableForCollection(wallet, collection)) {
                claimableCollections[count] = collection;
                count++;
            }
        }
        address[] memory trimmedClaimableCollections = new address[](count);
        for (uint256 j; j<count; j++) {
            trimmedClaimableCollections[j] = claimableCollections[j];
        }
        return trimmedClaimableCollections;
    }

    function switchClaimOpened() external onlyOwner {
        claimOpened = !claimOpened;
    }

    function addClaimableLarvaDucks(uint256[] calldata ids) external onlyAllowed {
        for (uint256 i; i<ids.length; i++) {
            claimableLarvaDucks.add(ids[i]);
        }
    }

    function removeClaimableLarvaDucks(uint256[] calldata ids) external onlyAllowed {
        for (uint256 i; i<ids.length; i++) {
            claimableLarvaDucks.remove(ids[i]);
        }
    }

    function updateClaimPerCollection(uint256 _claimPerCollection) external onlyOwner {
        claimPerCollection = _claimPerCollection;
    }

    function _claimLarvaDucks(address wallet, uint256 count) internal {
        uint256 randomIdIndex = _randomIdIndex(claimableLarvaDucks.length() - count + 1);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i; i<count; i++) {
            ids[i] = claimableLarvaDucks.at(i+randomIdIndex);
        }

        for (uint256 j; j<ids.length; j++) {
            uint256 id = ids[j];
            LarvaDucksNFT.safeTransferFrom(address(this), wallet, id);
            claimableLarvaDucks.remove(id);
            emit LarvaDucksClaimed(wallet, id);
        }
    }

    function _randomIdIndex(uint256 _limit) internal view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp, msg.sender)))) % _limit;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Controllers
    function setContractController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            contractController.add(_controller);
        } else {
            contractController.remove(_controller);
        }
        emit ContractControllerEvent(_controller, _mode);
    }

    function getContractControllerLength() public view returns (uint256) {
        return contractController.length();
    }

    function getContractControllerAt(uint256 _index) public view returns (address) {
        return contractController.at(_index);
    }

    function getContractControllerContains(address _addr) public view returns (bool) {
        return contractController.contains(_addr);
    }

    function getContractControllers()
        external
        view
        returns (address[] memory _allowed)
    {
        _allowed = new address[](contractController.length());
        for (uint256 i = 0; i < contractController.length(); i++) {
            _allowed[i] = contractController.at(i);
        }
        return _allowed;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() || contractController.contains(msg.sender),
            "Not Authorised"
        );
        _;
    }

    // Withdraw NFTs
    function withdrawNFTs(address recipient, uint256[] calldata ids) external onlyAllowed {
        for (uint256 i; i<ids.length; i++) {
            LarvaDucksNFT.safeTransferFrom(address(this), recipient, ids[i]);
        }
    }

    function withdrawCollectionNFTs(address collection, address recipient, uint256[] calldata ids) external onlyAllowed {
        ERC721 NFTCollection = ERC721(collection);
        for (uint256 i; i<ids.length; i++) {
            NFTCollection.safeTransferFrom(address(this), recipient, ids[i]);
        }
    }

    // Withdraw ETH
    function withdraw() external payable onlyOwner returns (bool success) {
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw Error");
    }
}