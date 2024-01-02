// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./ERC721VotesUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Memberships.sol";

interface IERC20 {
    function mint(address to, uint256 amount) external;
}
/// @custom:security-contact mechahubtrack@protonmail.com
contract MechaHubOriginal is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, 
EIP712Upgradeable, ERC721VotesUpgradeable, ReentrancyGuardUpgradeable, Memberships {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");
    uint256 private _nextTokenId;
    uint256 public MAX_SUPPLY;
    address private rewardToken;
    string private _baseTokenURI;
    event Claimed(address indexed sender, uint256 amount);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event ContractURIUpdated();
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function initialize(address defaultAdmin) initializer public {
        __ERC721_init("Mecha HUB Original", "MHOG");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __EIP712_init("Mecha HUB Original", "1");
        __ERC721Votes_init();
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(REWARD_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _initPeriod();
        _nextTokenId = 1;
    }
    
    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        require (_nextTokenId <= MAX_SUPPLY, "Max supply reached");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract")) : "";
    }
    function getMax() public view returns(uint256){
        return MAX_SUPPLY;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
        emit ContractURIUpdated();
        _baseTokenURI = newuri;
    }
    function setRewardToken(address _token) public onlyRole(REWARD_ROLE){
        rewardToken = _token;
    }
    function setNewMax(uint256 _newMax) public onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY = _newMax;
    }
    function activeReward(uint256 _totalReward) public onlyRole(REWARD_ROLE){
        return _activeRewards(_totalReward, totalSupply());
    }
    function stopReward() public onlyRole(REWARD_ROLE){
        return _stopRewards();
    }
    function viewRewards (uint256 _tokenId) public view returns(uint256, uint256){
        return _viewRewards(_tokenId);
    }
    function claim(uint256 _tokenId) public nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        uint256 toClaim = 0;
        _calculateRewards(_tokenId);
        toClaim = _claim(msg.sender);
        IERC20(rewardToken).mint(msg.sender, toClaim);
        emit Claimed(msg.sender, toClaim);
    }
    function claimAll() public nonReentrant{
        uint256 claimingAll = 0;
        for (uint256 i = 0; i < balanceOf(msg.sender); i++){
            _calculateRewards(tokenOfOwnerByIndex(msg.sender, i));
        }
        claimingAll = _claim(msg.sender);
        IERC20(rewardToken).mint(msg.sender, claimingAll);
        emit Claimed(msg.sender, claimingAll);
    }
    function calculateRewards(uint256 _tokenId) public{
        _calculateRewards(_tokenId);
    }
    fallback() external payable {
        revert("Not payable");
    } 
    receive() external payable {
        revert("Not payable");
    }
    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721VotesUpgradeable)
        returns (address)
    {
        _updatePeriod(to, tokenId, auth);
        return super._update(to, tokenId, auth);
    }
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721VotesUpgradeable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
