// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./WizNFT.sol";
import "./Shroom.sol";
import "./Skull.sol";

contract WizAssassinate is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    event WizAssassinated(uint256 tokenId, address killer, address victim);

    WizNFT private _wizNFTContract;
    Shroom private _shroomContract;
    Skull private _skullContract;
    address private _dompiAddress;
    address private _shroomBank;
    uint256 private _skullQuantityKiller = 1;
    uint256 private _skullQuantityVictim = 1;

    constructor(address wizNftAddress, address shroomAddress, address skullAddress) {
        _pause();

        _wizNFTContract = WizNFT(wizNftAddress);
        _shroomContract = Shroom(shroomAddress);
        _skullContract = Skull(skullAddress);
        _dompiAddress = _msgSender();
        _shroomBank = _msgSender();
    }

    function assassinate(bytes calldata signature, uint256 tokenId, uint256 shroomToBurn, address currentOwner, uint256 timeLimit, uint256 nonce) external nonReentrant whenNotPaused {
        require(timeLimit >= block.timestamp, 'Invalid assassination attempt');
        require(currentOwner == _wizNFTContract.ownerOf(tokenId), 'Not owned by currentOwner');
        require(_isValidSignature(signature, tokenId, shroomToBurn, currentOwner, timeLimit, nonce), 'Invalid signature');
        require(_shroomContract.balanceOf(_msgSender()) >= shroomToBurn, 'Not enough shrooms to assassinate');
        _wizNFTContract.burnFromAltar(tokenId);
        _shroomContract.transferFrom(_msgSender(), _shroomBank, shroomToBurn);
        _skullContract.mint(_msgSender(), 0, _skullQuantityKiller, "0x0");
        _skullContract.mint(currentOwner, 0, _skullQuantityVictim, "0x0");
        emit WizAssassinated(tokenId, _msgSender(), currentOwner);
    }

    function _isValidSignature(bytes memory signature, uint256 tokenId, uint256 shroomToBurn, address currentOwner, uint256 timeLimit, uint256 nonce) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(tokenId, shroomToBurn, currentOwner, timeLimit, nonce));
        return _dompiAddress == data.toEthSignedMessageHash().recover(signature);
    }

    function setAssassin(address assassin) public onlyOwner {
        _dompiAddress = assassin;
    }

    function setShroomBank(address shroomBankAddress) public onlyOwner {
        _shroomBank = shroomBankAddress;
    }

    function setSkullQuantityKiller(uint256 quantity) public onlyOwner {
        _skullQuantityKiller = quantity;
    }

    function setSkullQuantityVictim(uint256 quantity) public onlyOwner {
        _skullQuantityVictim = quantity;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
