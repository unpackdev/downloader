// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./CryptoNinjaSakuyaEndCard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract CryptoNinjaSakuyaEndCardSetMinterV1 is Ownable {
    enum Phase {
        BeforeMint,
        PublicMint
    }
    CryptoNinjaSakuyaEndCard public immutable endCard;

    Phase public phase = Phase.BeforeMint;

    uint256 public price = 1 ether;
    uint256[] public targetIds = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
    uint256[] public targetAmounts = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    uint256 public maxSupply = 50;

    constructor(CryptoNinjaSakuyaEndCard _endCard) {
        endCard = _endCard;
    }

    function _mintCheck() internal view {
        require(phase == Phase.PublicMint, 'PreMint is not active.');
        require(msg.value >= price, 'Not enough funds provided for mint');
        require(
            endCard.totalSupply(targetIds[0]) + 1 <= maxSupply,
            'Total supply cannot exceed maxSupply'
        );
    }

    function mint(address _to) public payable {
        _mintCheck();

        endCard.mintBatch(_to, targetIds, targetAmounts, '');
    }

    function publicMint() external payable {
        mint(msg.sender);
    }

    function totalSupply(uint256 _tokenId) external view returns (uint256) {
        return endCard.totalSupply(_tokenId);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
    function setTargetId(uint256 _targetId, uint256 _index) external onlyOwner {
        targetIds[_index] = _targetId;
    }

    function setTargetAmount(uint256 _targetAmount, uint256 _index) external onlyOwner {
        targetAmounts[_index] = _targetAmount;
    }

    function withdraw(address to) external onlyOwner {
        (bool os, ) = payable(to).call{value: address(this).balance}('');
        require(os);
    }
}
