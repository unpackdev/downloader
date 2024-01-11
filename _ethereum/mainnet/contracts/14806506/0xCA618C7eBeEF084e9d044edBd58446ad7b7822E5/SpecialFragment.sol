// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./console.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IGhostsProject.sol";

contract SpecialFragment is Initializable, ERC1155Upgradeable, OwnableUpgradeable {

    using StringsUpgradeable for uint256;

    uint256 internal constant FRAGMENT_ID = 0;
    uint256 internal constant KEY_LENGTH = 40;

    IGhostsProject ghostsProject;

    uint256[KEY_LENGTH] internal verifiedGhostKeys;
    mapping(uint256 => bool) internal claimedGhosts;
    mapping(uint256 => uint256) public totalSupply;

    bool public isActive;
    uint256 public maxSupply;

    string private uriBase;

    modifier ownerOfGhost(uint256 _ghostId) {
        require(ghostsProject.ownerOf(_ghostId) == msg.sender, "");
        _;
    }

    modifier ownerOfGhosts(uint256[] memory _ghostIds) {
        for (uint256 idx = 0; idx < _ghostIds.length; idx++)
            require(ghostsProject.ownerOf(_ghostIds[idx]) == msg.sender, "");
        _;
    }

    modifier onlyInActive() {
        require(isActive, "");
        _;
    }

    function initialize(string memory newUri) initializer public {
        __ERC1155_init_unchained(newUri);
        __Ownable_init_unchained();
    }

    function connectGhostsProject(address _address) public onlyOwner {
        IGhostsProject candidateContract = IGhostsProject(_address);
        require(candidateContract.isGhostsProject());
        ghostsProject = IGhostsProject(_address);
    }

    function setVerifiedGhosts(uint256 _maxSupply, uint256[] memory ghostKeys) public onlyOwner {
        require(ghostKeys.length == KEY_LENGTH, "length of keys should be 40");
        for (uint256 idx = 0; idx < KEY_LENGTH; idx++) {
            verifiedGhostKeys[idx] = ghostKeys[idx];
        }
        maxSupply = _maxSupply;
    }

    function getTotalSupply(uint256 _tokenId) public view returns (uint256) {
        return totalSupply[_tokenId];
    }

    function isVerified(uint256 _ghostId) public view returns (bool) {
        uint256 idx = _ghostId / 250;
        uint256 indicator = 1 << (_ghostId % 250);
        return (verifiedGhostKeys[idx] & indicator) != 0;
    }

    function claimed(uint256 _ghostId) public view returns (bool) {
        return claimedGhosts[_ghostId];
    }

    function isClaimable(uint256 _ghostId) public view returns (bool) {
        return isVerified(_ghostId) && !claimedGhosts[_ghostId];
    }

    function areClaimable(uint256[] memory _ghostIds) public view returns (bool) {
        bool claimable = true;
        for (uint256 idx = 0; idx < _ghostIds.length; idx++) {
            claimable = claimable && isClaimable(_ghostIds[idx]);
        }
        return claimable;
    }

    function claimSpecialFragments(uint256[] memory _ghostIds) public onlyInActive ownerOfGhosts(_ghostIds) {
        require(areClaimable(_ghostIds), "");
        require(totalSupply[FRAGMENT_ID] + _ghostIds.length <= maxSupply);
        for (uint256 idx = 0; idx < _ghostIds.length; idx++) {
            claimedGhosts[_ghostIds[idx]] = true;
        }
        totalSupply[FRAGMENT_ID] += _ghostIds.length;
        _mint(msg.sender, FRAGMENT_ID, _ghostIds.length, "");
    }

    function setURI(string memory _newUri) public onlyOwner {
        uriBase = _newUri;
//        _setURI(_newUri);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return bytes(uriBase).length > 0 ? string(abi.encodePacked(uriBase, _id.toString())) : "";
    }

    function updateState(bool _newState) public onlyOwner {
        isActive = _newState;
    }

    function mintByTreasury() public onlyOwner {
        uint256 numToMint = maxSupply - totalSupply[FRAGMENT_ID];
        totalSupply[FRAGMENT_ID] += numToMint;
        _mint(msg.sender, FRAGMENT_ID, numToMint, "");
    }
}
