pragma solidity ^0.8.10;
// SPDX-License-Identifier: UNLICENSED

import "./Initializable.sol";
import "./IERC2981Upgradeable.sol";
import "./ERC165StorageUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessRole.sol";

contract Serum is IERC2981Upgradeable, ERC165StorageUpgradeable, OwnableUpgradeable, IERC1155MetadataURIUpgradeable, ERC1155Upgradeable
    , AccessRole, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // merkle tree root
    bytes32 public gcfRoot;
    bytes32 public communityRoot;

    string public name;
    string public symbol;

     //Token URI prefix
    string public tokenURIPrefix;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    address public royalty;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    uint256 public constant royaltyPercent = 5;

    mapping(uint256 => uint256) public totalsupplyById;

    mapping(uint256 => uint256) public totalReservedSupplyById;

    mapping(uint256 => uint256) public maxsupplyById;

    /// @dev max mint count per transaction
    uint256 public maxMintCount;

    ///@dev mint price
    uint256 public mintprice; 

    ///@dev drop phase
    uint256 public dropPhase;

    /// @dev reserve count mapping
    mapping(address => mapping(uint => uint)) public reserveCount;

    /// @dev mapping for minted of GCF whiltelist minting
    mapping(address => mapping(uint256 => bool)) public mintedForGCF;

    /// @dev mapping for minted of community whiltelist minting
    mapping(address => mapping(uint256 => bool)) public mintedForCommunity;

    /// @dev mapping for free minting
    mapping(uint256 => bool) public mintedForFreeMint;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _tokenURIPrefix token URI Prefix
    */
    function initialize(string memory _name, string memory _symbol, string memory _tokenURIPrefix, address _royalty,
        bytes32 _gcfRoot, bytes32 _communityRoot) public initializer {
        ERC165StorageUpgradeable.__ERC165Storage_init();
        OwnableUpgradeable.__Ownable_init();
        ERC1155Upgradeable.__ERC1155_init(_tokenURIPrefix);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AccessRole.initialize();

        name = _name;
        symbol = _symbol;
        tokenURIPrefix = _tokenURIPrefix;
        gcfRoot = _gcfRoot;
        communityRoot = _communityRoot;
        royalty = _royalty;
        mintprice = 0.027 ether;
        maxMintCount = 6;
        dropPhase = 0;

        maxsupplyById[1] = 30;
        maxsupplyById[2] = 297;
        maxsupplyById[3] = 470;
        maxsupplyById[4] = 788;
        maxsupplyById[5] = 1389;
        maxsupplyById[6] = 6000;
        maxsupplyById[7] = 6000;
        maxsupplyById[8] = 6000;
        maxsupplyById[9] = 6000;
        maxsupplyById[10] = 6000;
        maxsupplyById[11] = 6000;       

        addAdmin(_msgSender());
        addMinter(_msgSender());
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * @dev Creates a new token type and assings _initialSupply to minter
     * @param _beneficiary address where mint to
     * @param _id token Id
     * @param _supply mint supply
    */
    function safeMint(address _beneficiary, uint256 _id, uint256 _supply) internal {
        require(_supply != 0, "Supply should be positive");

        _mint(_beneficiary, _id, _supply, "");
    }

    /**
     * @dev burn token with id and value
     * @param _owner address where mint to
     * @param _id token Id which will burn
     * @param _value token count which will burn
    */
    function burn(address _owner, uint256 _id, uint256 _value) external {
        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender) == true, "Need operator approval for 3rd party burns.");

        _burn(_owner, _id, _value);
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param _tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
    }

    /**
     * @dev function which return token URI
     * @param _id token Id
     */
    function uri(uint256 _id) override(ERC1155Upgradeable, IERC1155MetadataURIUpgradeable) virtual public view returns (string memory) {
        return bytes(tokenURIPrefix).length > 0 ? string(abi.encodePacked(tokenURIPrefix, _id.toString())) : "";
    }

    /**
     * @dev reserve function for reserve mint.
     */
    function reserve(uint256 _tokenId, uint256 _count) external payable {
        require(dropPhase == 2, "not general minting period");
        require(_tokenId >= 6 && _tokenId <= 11, "not on token range");
        if(_tokenId >= 6 && _tokenId <= 9 && mintedForFreeMint[_tokenId] == false) {
            require(
                (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= (maxsupplyById[_tokenId] / 10 * 9), 
                "overflow maxsupply"
            );
        } else {
            require(
                (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= maxsupplyById[_tokenId], 
                "overflow maxsupply"
            );
        }
        require(_count <= maxMintCount, "too many count for one transaction");
        require(msg.value >= (mintprice * _count), "mintprice is not enough");
        reserveCount[msg.sender][_tokenId] += _count;
        totalReservedSupplyById[_tokenId] += _count;
    }

    function claimForGCFHolders(uint256 _tokenId, uint256 _count, bytes32[] calldata _merkleProof) external {
        require(_tokenId >= 1 && _tokenId <= 5, "not on token range");
        require(
            (totalsupplyById[_tokenId] + _count) <= maxsupplyById[_tokenId], 
            "overflow maxsupply"
        );

        require(mintedForGCF[msg.sender][_tokenId] == false, "have already minted to this address");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId, _count));
        require(MerkleProofUpgradeable.verify(_merkleProof, gcfRoot, leaf), "Invalid Proof");
        safeMint(msg.sender, _tokenId, _count);
        mintedForGCF[msg.sender][_tokenId] = true;
        totalsupplyById[_tokenId]+=_count;
    }

    function mint(uint256 _tokenId, uint256 _count, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(dropPhase > 0, "not the drop period");
        require(_tokenId >= 6 && _tokenId <= 11, "not on token range");
        require(_count <= maxMintCount, "too many count for one transaction");

        if(dropPhase == 1) {
            if(_tokenId >= 6 && _tokenId <= 9 && mintedForFreeMint[_tokenId] == false) {
                require(
                    (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= (maxsupplyById[_tokenId] / 10 * 9), 
                    "overflow maxsupply"
                );
            } else {
                require(
                    (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= maxsupplyById[_tokenId], 
                    "overflow maxsupply"
                );
            }
            require(mintedForCommunity[msg.sender][_tokenId] == false, "have already minted to this address");
            require(msg.value >= (mintprice * _count), "mintprice is not enough");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId, _count));
            require(MerkleProofUpgradeable.verify(_merkleProof, communityRoot, leaf), "Invalid Proof");
            safeMint(msg.sender, _tokenId, _count);
            mintedForCommunity[msg.sender][_tokenId] = true;
            totalsupplyById[_tokenId]+=_count;
        } else if(dropPhase == 2) {
            if(reserveCount[msg.sender][_tokenId] == 0) {
                if(_tokenId >= 6 && _tokenId <= 9 && mintedForFreeMint[_tokenId] == false) {
                    require(
                        (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= (maxsupplyById[_tokenId] / 10 * 9), 
                        "overflow maxsupply"
                    );
                } else {
                    require(
                        (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= maxsupplyById[_tokenId], 
                        "overflow maxsupply"
                    );
                }
                require(msg.value >= (mintprice * _count), "mintprice is not enough");
            } else {
                if(_tokenId >= 6 && _tokenId <= 9 && mintedForFreeMint[_tokenId] == false) {
                    require(
                        (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId]) <= (maxsupplyById[_tokenId] / 10 * 9), 
                        "overflow maxsupply"
                    );
                } else {
                    require(
                        (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId]) <= maxsupplyById[_tokenId], 
                        "overflow maxsupply"
                    );
                }
                require(reserveCount[msg.sender][_tokenId] >= _count, "not enough reserved token");
            }

            safeMint(msg.sender, _tokenId, _count);
            totalsupplyById[_tokenId]+=_count;
            
            if(reserveCount[msg.sender][_tokenId] >= _count) {
                reserveCount[msg.sender][_tokenId] -= _count;
                totalReservedSupplyById[_tokenId] -= _count;
            }
        } else {}
    }

    function freeMint(uint256 _tokenId, uint256 _count) external onlyOwner {
        require(_tokenId >= 6 && _tokenId <= 9, "not on token range");
        require(
            (totalsupplyById[_tokenId] + totalReservedSupplyById[_tokenId] + _count) <= maxsupplyById[_tokenId], 
            "overflow maxsupply"
        );
        require(_count == (maxsupplyById[_tokenId] / 10), "too many count for one transaction");
        require(mintedForFreeMint[_tokenId] == false, "have already minted for this tokenId");

        safeMint(msg.sender, _tokenId, _count);
        mintedForFreeMint[_tokenId] = true;
        totalsupplyById[_tokenId]+=_count;
    }

    function setMintPrice(uint256 _mintprice) external onlyOwner {
        require(_mintprice > 0, "mint price shold be not 0");
        mintprice = _mintprice;
    }

    function setMaxMintCount(uint256 _maxMintCount) external onlyOwner {
        require(_maxMintCount > 0, "max mint count should be not 0");
        maxMintCount = _maxMintCount;
    }

    /**
     * @dev set maxsupply function
     */
    function setMaxSupplyById(uint256 _tokenId, uint256 _maxsupply) external onlyAdmin {
        maxsupplyById[_tokenId] = _maxsupply;
    }

    /**
     * @dev set gcfRoot function
     */
    function setGCFRoot(bytes32 _gcfRoot) external onlyAdmin {
        gcfRoot = _gcfRoot;
    }

    /**
     * @dev set communityRoot function
     */
    function setCommunityRoot(bytes32 _communityRoot) external onlyAdmin {
        communityRoot = _communityRoot;
    }

    /**
     * @dev set dropPhase function
     */
    function setDropPhase(uint256 _dropPhase) external onlyOwner {
        dropPhase = _dropPhase;
    }

    /**
     * @dev total supply function
     */
    function totalsupply() external view returns(uint256) {
        uint256 supply;

        for(uint256 i = 1; i <= 11; i++)
            supply += totalsupplyById[i];
        
        return supply;
    }

    /**
     * @dev total supply function
     */
    function totalReservedSupply() external view returns(uint256) {
        uint256 supply;

        for(uint256 i = 6; i <= 11; i++)
            supply += totalReservedSupplyById[i];
        
        return supply;
    }

    /**
     * @dev max supply function
     */
    function maxsupply() external view returns(uint256) {
        uint256 supply;

        for(uint256 i = 1; i <= 11; i++)
            supply += maxsupplyById[i];
        
        return supply;
    }

    /**
     * @dev withdraw all ethers to owner.
     */
    function withdraw() public payable onlyOwner {
        address payable ownerAddress =  payable(msg.sender);
        ownerAddress.transfer(address(this).balance);
    }

    function royaltyInfo(uint256 , uint256 salePrice) external view override(IERC2981Upgradeable) returns (address receiver, uint256 royaltyAmount) {
        receiver = royalty;
        royaltyAmount = salePrice.mul(royaltyPercent).div(100);
    }

    function supportsInterface(bytes4 interfaceId) public view 
        override(IERC165Upgradeable, ERC165StorageUpgradeable, ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}