// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract NFT is
    Initializable,
    UUPSUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant TIER1_ROLE = keccak256("TIER1_ROLE");
    bytes32 public constant TIER2_ROLE = keccak256("TIER2_ROLE");
    bytes32 public constant TIER3_ROLE = keccak256("TIER3_ROLE");
    bytes32 public constant TIER4_ROLE = keccak256("TIER4_ROLE");
    
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint16;

    // Mapping user address to check if token is claimed by user.
    mapping(address => mapping(bytes32 => bool)) public claimed;
    // Mapping to track the total supply by the end of each tier
    mapping(bytes32 => uint256) public tierTotalSupply;
    // Mapping to keep track of the claimed token. It will mint new token after the current token
    mapping(bytes32 => uint256) public tierTotalClaimed;
    mapping(bytes32 => mapping(uint256 => uint256)) public chapterMintCount;
    // Mapping to keep track of the total claimable tokens.
    mapping(address => mapping(bytes32 => uint256)) public tierTotalClaimableToken;
    mapping(address => mapping(bytes32 => mapping(uint256 => uint256))) public tierTotalClaimableChapter;

    uint256 public constant MAX_SUPPLY = 10000;
    string private _baseURIValue;
    bytes32[4] public tiers;
    bool public teamNFTStatus;
    uint256 public constant totalChapters = 14;

    function initialize() public initializer {
        ERC721Upgradeable.__ERC721_init("Crypto Investing Guide", "CIG");
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tiers[0] = TIER1_ROLE;
        tiers[1] = TIER2_ROLE;
        tiers[2] = TIER3_ROLE;
        tiers[3] = TIER4_ROLE;
        tierTotalSupply[TIER1_ROLE] = 8890;
        tierTotalSupply[TIER2_ROLE] = 9890;
        tierTotalSupply[TIER3_ROLE] = 9990;
        tierTotalSupply[TIER4_ROLE] = 10000;
        tierTotalClaimed[TIER2_ROLE] = 8890;
        tierTotalClaimed[TIER3_ROLE] = 9890;
        tierTotalClaimed[TIER4_ROLE] = 9990;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) external onlyOwner {
        _baseURIValue = newBase;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setClaimableRole(address[] memory claimableAddress, uint256[] memory _role, uint256[] memory _chapter, uint256[] memory _tokenAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require((claimableAddress.length == _tokenAmount.length), "Invalid Data");
        for (uint256 i = 0; i < claimableAddress.length; i++) {
            require(tierTotalSupply[tiers[_role[i]]] > 0, "Role not added");
            _setupRole(tiers[_role[i]], claimableAddress[i]);
            if(tiers[_role[i]] == TIER3_ROLE) {
                tierTotalClaimableToken[claimableAddress[i]][tiers[_role[i]]] = tierTotalClaimableToken[claimableAddress[i]][tiers[_role[i]]].add(_tokenAmount[i]);
                if(tierTotalClaimableChapter[claimableAddress[i]][tiers[_role[i]]][_chapter[i]] > 0) {
                    tierTotalClaimableToken[claimableAddress[i]][tiers[_role[i]]] = tierTotalClaimableToken[claimableAddress[i]][tiers[_role[i]]].sub(tierTotalClaimableChapter[claimableAddress[i]][tiers[_role[i]]][_chapter[i]]);
                    tierTotalClaimableChapter[claimableAddress[i]][tiers[_role[i]]][_chapter[i]] = _tokenAmount[i];
                } else {
                    tierTotalClaimableChapter[claimableAddress[i]][tiers[_role[i]]][_chapter[i]] = _tokenAmount[i];
                }
            } else {
                tierTotalClaimableToken[claimableAddress[i]][tiers[_role[i]]] = _tokenAmount[i];
            }
        }
    }

    function claimAllNFT() external whenNotPaused nonReentrant {
        require(teamNFTStatus != false, "Can not claim before team NFT distribution");
        uint256 _nftAmount = 0;
        require(totalSupply() < MAX_SUPPLY, "Max supply limit reached");
        for(uint256 i=0; i<tiers.length; i++) {
            if(tiers[i] == TIER3_ROLE && tierTotalClaimableToken[msg.sender][tiers[i]] > 0) {
                for(uint256 j=0; j<totalChapters; j++) {
                    uint256 _chapterMintCount = tierTotalClaimableChapter[msg.sender][tiers[i]][j];
                    if(_chapterMintCount > 0) {
                        uint256 _chapterCurrentIndex = tierTotalSupply[tiers[i.sub(1)]].add(uint256(100).div(totalChapters).mul(j)).add(chapterMintCount[tiers[i]][j]);
                        uint256 _chapterMaxLimit = tierTotalSupply[tiers[i.sub(1)]].sub(1).add(uint256(100).div(totalChapters).mul(j.add(1)));
                        if(j < totalChapters.sub(2)) {
                            require(chapterMintCount[tiers[i]][j] <= 7 && _chapterCurrentIndex.add(_chapterMintCount.sub(1)) <= _chapterMaxLimit, "Chapter NFT already claimed");
                        } else {
                            if(j == 13) {
                                _chapterCurrentIndex = _chapterCurrentIndex.add(1);
                                _chapterMaxLimit = _chapterMaxLimit.add(2);
                            } else {
                                _chapterCurrentIndex = _chapterCurrentIndex;
                                _chapterMaxLimit = _chapterMaxLimit.add(1);
                            }
                            require(chapterMintCount[tiers[i]][j] <= 8 && _chapterCurrentIndex.add(_chapterMintCount.sub(1)) <= _chapterMaxLimit, "Chapter NFT already claimed");
                        }
                        _nftAmount = _claimNFT(_msgSender(), tiers[i], _chapterCurrentIndex, _chapterMintCount, j);
                    }
                }
            }
            else {
                if(tierTotalClaimableToken[msg.sender][tiers[i]] > 0) {
                    _nftAmount = _claimNFT(_msgSender(), tiers[i], tierTotalClaimed[tiers[i]], tierTotalClaimableToken[msg.sender][tiers[i]], 0);
                }
            }
        }
        require(_nftAmount > 0, "Caller cannot claim");
    }

    function _claimNFT(address _claimable, bytes32 _role, uint _tierCurrentIndex, uint256 _tierTotalClaimable, uint256 _chapter) internal returns(uint256 _nftAmount) {
        require(tierTotalSupply[_role] > 0, "Role not added");
        require(
            tierTotalClaimed[_role].add(_tierTotalClaimable) <= tierTotalSupply[_role],
            "Max supply limit reached for tier"
        );
        require(_tierCurrentIndex < MAX_SUPPLY, "Invalid NFT Index");
        for(uint256 i=0; i<_tierTotalClaimable; i++) {
            _safeMint(_claimable, _tierCurrentIndex);
            _tierCurrentIndex = _tierCurrentIndex.add(1);
            tierTotalClaimed[_role] = tierTotalClaimed[_role].add(1);
            if(teamNFTStatus == true) {
                tierTotalClaimableToken[_claimable][_role] = tierTotalClaimableToken[_claimable][_role].sub(1);
            }
            _nftAmount = _nftAmount.add(1);
            if(_role == TIER3_ROLE) {
                chapterMintCount[_role][_chapter] = chapterMintCount[_role][_chapter].add(1);
                if(teamNFTStatus == true) {
                    tierTotalClaimableChapter[_claimable][_role][_chapter] = tierTotalClaimableChapter[_claimable][_role][_chapter].sub(1);
                }
            }
        }
        return _nftAmount;
    }

    function claimAllTeamNFT(address[] memory claimableAddress, uint256[] memory _role, uint256[] memory _chapter) external whenNotPaused nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(claimableAddress.length == _role.length, "Invalid Data");
        require(totalSupply() < MAX_SUPPLY, "Max supply limit reached");
        teamNFTStatus = false;
        for(uint256 i=0 ; i<claimableAddress.length; i++) {
            if(tiers[_role[i]] == TIER3_ROLE) {
                uint256 _chapterCurrentIndex = tierTotalSupply[tiers[_role[i].sub(1)]].add(uint256(100).div(totalChapters).mul(_chapter[i])).add(chapterMintCount[tiers[_role[i]]][_chapter[i]]);
                uint256 _chapterMaxLimit = tierTotalSupply[tiers[_role[i].sub(1)]].sub(1).add(uint256(100).div(totalChapters).mul(_chapter[i].add(1)));
                if(_chapter[i] < totalChapters.sub(2)) {
                    require(chapterMintCount[tiers[_role[i]]][_chapter[i]] <= 7 && _chapterCurrentIndex <= _chapterMaxLimit, "Chapter NFT already claimed");
                } else {
                    if(_chapter[i] == 13) {
                        _chapterCurrentIndex = _chapterCurrentIndex.add(1);
                        _chapterMaxLimit = _chapterMaxLimit.add(2);
                    } else {
                        _chapterCurrentIndex = _chapterCurrentIndex;
                        _chapterMaxLimit = _chapterMaxLimit.add(1);
                    }
                    require(chapterMintCount[tiers[_role[i]]][_chapter[i]] <= 8 && _chapterCurrentIndex <= _chapterMaxLimit, "Chapter NFT already claimed");
                }
                _claimNFT(claimableAddress[i], tiers[_role[i]], _chapterCurrentIndex, 1, _chapter[i]);
            } else {
                _claimNFT(claimableAddress[i], tiers[_role[i]], tierTotalClaimed[tiers[_role[i]]], 1, 0);
            }
        }
        teamNFTStatus = true;
    }

    function _authorizeUpgrade(address) internal override {
        require(owner() == msg.sender, "Only owner can upgrade implementation");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}