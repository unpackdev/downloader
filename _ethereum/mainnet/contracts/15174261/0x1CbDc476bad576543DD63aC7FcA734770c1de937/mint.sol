// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract FlyToken is ERC20, Pausable, Ownable {

    IERC721A public immutable dirty;
    IERC721A public immutable human;

    uint public immutable cap = 57880000000 ether;
    uint public immutable dirtyRewards = 500000;
    uint public immutable humanOgRewards = 2000000;
    uint public immutable humanRewards = 1500000;
    uint private immutable invalidTokenId = 999999;

    mapping(uint => bool) public dirtyClaimTokenIdsMap;
    mapping(uint => bool) public humanClaimTokenIdsMap;

    address public immutable deadAddr = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("Fly Token", "FT") {
        dirty = IERC721A(0x9984bD85adFEF02Cea2C28819aF81A6D17a3Cb96);
        human = IERC721A(0x01A75Fb1A4b1A8f699fd00ad051f9100EbEcec42);
        pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function claimableTokenIdsForDirty(address msgSender) public view returns (uint[] memory _tokenIds) {
        uint length = dirty.balanceOf(msgSender);
        uint j = 0;
        _tokenIds = new uint[](length);
        for (uint i = 0; i < dirty.totalSupply(); i++) {
            if (dirty.ownerOf(i) == msgSender && !dirtyClaimTokenIdsMap[i]) {
                _tokenIds[j++] = i;
            }
        }
        for (uint i = j; i < length; i++) {
            _tokenIds[i] = invalidTokenId;
        }
    }

    function claimableTokenIdsForHumanOg(address msgSender) public view returns (uint[] memory _tokenIds) {
        uint length = human.balanceOf(msgSender);
        uint j = 0;
        _tokenIds = new uint[](length);
        for (uint i = 0; i < human.totalSupply() && i < 726; i++) {
            if (human.ownerOf(i) == msgSender && !humanClaimTokenIdsMap[i]) {
                _tokenIds[j++] = i;
            }
        }
        for (uint i = j; i < length; i++) {
            _tokenIds[i] = invalidTokenId;
        }
    }

    function claimableTokenIdsForHuman(address msgSender) public view returns (uint[] memory _tokenIds) {
        uint length = human.balanceOf(msgSender);
        uint j = 0;
        _tokenIds = new uint[](length);
        for (uint i = 726; i < human.totalSupply(); i++) {
            if (human.ownerOf(i) == msgSender && !humanClaimTokenIdsMap[i]) {
                _tokenIds[j++] = i;
            }
        }
        for (uint i = j; i < length; i++) {
            _tokenIds[i] = invalidTokenId;
        }
    }

    function claim(uint[] memory dirtyTokenIds, uint[] memory humanOgTokenIds, uint[] memory humanTokenIds) external whenNotPaused {
        address msgSender = msg.sender;
        require(dirtyTokenIds.length != 0 || humanOgTokenIds.length != 0 || humanTokenIds.length != 0, "No tokens can claim.");

        for (uint i = 0; i < dirtyTokenIds.length; i++) {
            uint tokenId = dirtyTokenIds[i];
            require(dirty.ownerOf(tokenId) == msgSender && !dirtyClaimTokenIdsMap[tokenId], 'tokenId invalid');
            dirtyClaimTokenIdsMap[tokenId] = true;
        }
        for (uint i = 0; i < humanOgTokenIds.length; i++) {
            uint tokenId = humanOgTokenIds[i];
            require(human.ownerOf(tokenId) == msgSender && !humanClaimTokenIdsMap[tokenId], 'tokenId invalid');
            humanClaimTokenIdsMap[tokenId] = true;
        }
        for (uint i = 0; i < humanTokenIds.length; i++) {
            uint tokenId = humanTokenIds[i];
            require(human.ownerOf(tokenId) == msgSender && !humanClaimTokenIdsMap[tokenId], 'tokenId invalid');
            humanClaimTokenIdsMap[tokenId] = true;
        }

        uint amount = dirtyTokenIds.length * dirtyRewards + humanOgTokenIds.length * humanOgRewards + humanTokenIds.length * humanRewards;
        _mint(msgSender, amount * 1e18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Cannot have a non-address as reserve.");
        require(totalSupply() + amount <= cap, "total supply of tokens cannot exceed the cap");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
