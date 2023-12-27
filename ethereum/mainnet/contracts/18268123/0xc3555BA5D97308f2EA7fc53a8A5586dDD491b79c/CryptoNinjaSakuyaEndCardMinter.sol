// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./CryptoNinjaSakuyaEndCard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract CryptoNinjaSakuyaEndCardMinter is Ownable {
    enum Phase {
        BeforeMint,
        PublicMint
    }
    CryptoNinjaSakuyaEndCard public immutable endCard;

    mapping(uint256 => bool) public canMint;
    mapping(uint256 => uint256) public maxSupply;

    Phase public phase = Phase.BeforeMint;

    uint256 public price = 0.1 ether;
    uint256 public mintPerTx = 1;
    uint256 public maxTokenId = 10;

    constructor(CryptoNinjaSakuyaEndCard _endCard) {
        endCard = _endCard;
        canMint[1] = true;
        maxSupply[1] = 51;
    }

    function _mintCheck(uint256 _mintAmount, uint256 _tokenId) internal view {
        require(phase == Phase.PublicMint, 'PreMint is not active.');
        require(msg.value >= (price * _mintAmount), 'Not enough funds provided for mint');
        require(canMint[_tokenId], 'This token is not allowed to mint');
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(
            endCard.totalSupply(_tokenId) + _mintAmount <= maxSupply[_tokenId],
            'Total supply cannot exceed maxSupply'
        );
        require(mintPerTx >= _mintAmount, 'Mint amount cannot be mintPerTx');
    }

    function mint(
        uint256 _mintAmount,
        uint256 _tokenId,
        address _to
    ) public payable {
        _mintCheck(_mintAmount, _tokenId);

        endCard.mint(_to, _tokenId, _mintAmount, '');
    }

    function getCanMintArray() external view returns (bool[] memory) {
        bool[] memory _canMint = new bool[](maxTokenId);
        for (uint256 i = 1; i <= maxTokenId; i++) {
            _canMint[i] = canMint[i];
        }
        return _canMint;
    }

    function getMaxSupplyArray() external view returns (uint256[] memory) {
        uint256[] memory _maxSupply = new uint256[](maxTokenId);
        for (uint256 i = 1; i <= maxTokenId; i++) {
            _maxSupply[i] = maxSupply[i];
        }
        return _maxSupply;
    }

    function publicMint(uint256 _mintAmount, uint256 _tokenId) external payable {
        mint(_mintAmount, _tokenId, msg.sender);
    }

    function totalSupply(uint256 _tokenId) external view returns (uint256) {
        return endCard.totalSupply(_tokenId);
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setCanMint(uint256 _tokenId, bool _canMint) external onlyOwner {
        canMint[_tokenId] = _canMint;
    }

    function setMaxSupply(uint256 _tokenId, uint256 _maxSupply) external onlyOwner {
        maxSupply[_tokenId] = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    
    function setMintPerTx(uint256 _mintPerTx) external onlyOwner {
        mintPerTx = _mintPerTx;
    }

    function setMaxTokenId(uint256 _maxTokenId) external onlyOwner {
        maxTokenId = _maxTokenId;
    }

    function withdraw(address to) external onlyOwner {
        (bool os, ) = payable(to).call{value: address(this).balance}('');
        require(os);
    }
}
