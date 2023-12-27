// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC721Receiver.sol";
import "./CryptoNinjaChildren.sol";
import "./IERC721Lockable.sol";
import "./CNCExternalURISupplier.sol";

contract CNCBurnin is Ownable, IERC721Receiver {
    address payable public withdrawalAddress;
    CryptoNinjaChildren public cnc;
    CNCExternalURISupplier public cncExternalURISupplier;
    uint256 public tokenIndex = 11111; // start from
    uint256 public presaleRarePrice = 0.1 ether;
    uint256 public presaleNormalPrice = 0.01 ether;
    uint256 public publicSaleRarePrice = 0.15 ether;
    uint256 public publicSaleNormalPrice = 0.015 ether;
    bytes32 public merkleRoot = 0x0;

    mapping (address => uint256) public userMintedAmount;
    struct PauseData {
        bool isPresaleUnpaused; // default false
        bool isPublicSaleUnpaused; // default false
    }
    PauseData public pauseData;

    constructor(address _cnc, address _cncExternalURISupplier) Ownable(msg.sender) {
        cnc = CryptoNinjaChildren(_cnc);
        cncExternalURISupplier = CNCExternalURISupplier(_cncExternalURISupplier);
    }

    modifier verifyMerkle(
        uint248 _allowedAmount,
        bytes32[] calldata _merkleProof
    ) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _allowedAmount));
        require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node),
            "invalid proof."
        );
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    modifier ownerAndTokenIdCheck(uint256[] calldata _cncTokenIds, address _to) {
        for(uint256 i = 0; i < _cncTokenIds.length; i++) {
            require(cnc.ownerOf(_cncTokenIds[i]) == _to, "CNCBurnin: not owner");
            require(0 <= _cncTokenIds[i] && _cncTokenIds[i] < 11111, "CNCBurnin: invalid token id");
        }
        _;
    }

    function _burnAndMint(uint256[] calldata _cncTokenIds, uint256 _normalAmount, uint256 _rareAmount, address _to) private
        ownerAndTokenIdCheck(_cncTokenIds, msg.sender)
    {
        require(_normalAmount + _rareAmount == _cncTokenIds.length, "CNCBurnin: invalid amount");

        bytes32[] memory emptyProof;
        cnc.exchange(_cncTokenIds, 11111, emptyProof);

        uint256 baseTokenId = tokenIndex;
        // normal
        for(uint256 i = 0; i < _normalAmount; ) {
            cncExternalURISupplier.setTokenType(baseTokenId + i, CNCExternalURISupplier.TokenType.NORMAL);
            cnc.safeTransferFrom(address(this), _to, baseTokenId + i);

            unchecked {
                ++i;
            }
        }
        // rare
        for(uint256 j = _normalAmount; j < _cncTokenIds.length; ) {
            cncExternalURISupplier.setTokenType(baseTokenId + j, CNCExternalURISupplier.TokenType.RARE);
            cnc.safeTransferFrom(address(this), _to, baseTokenId + j);

            unchecked {
                ++j;
            }
        }
        tokenIndex += _cncTokenIds.length;
    }

    // for token id: 11111-11444
    function adminSpecialBurnin(uint256[] calldata _cncTokenIds, address _to) public onlyOwner ownerAndTokenIdCheck(_cncTokenIds, _to) {
        bytes32[] memory emptyProof;
        cnc.exchange(_cncTokenIds, 11111, emptyProof);

        uint256 amount = _cncTokenIds.length;
        uint256 baseTokenId = tokenIndex;
        for(uint256 i = 0; i < amount; ++i) {
            cnc.safeTransferFrom(address(this), _to, baseTokenId + i);
        }
        tokenIndex += amount;
    }

    function adminBurnin(uint256[] calldata _cncTokenIds, uint256 _normalAmount, uint256 _rareAmount, address _to) public onlyOwner {
        _burnAndMint(_cncTokenIds, _normalAmount, _rareAmount, _to);
    }

    function setIsPresaleUnPaused(bool _isPresaleUnpaused) public onlyOwner {
        pauseData.isPresaleUnpaused = _isPresaleUnpaused;
    }

    function setPresaleRarePrice(uint256 _presaleRarePrice) public onlyOwner {
        presaleRarePrice = _presaleRarePrice;
    }

    function setPresaleNormalPrice(uint256 _presaleNormalPrice) public onlyOwner {
        presaleNormalPrice = _presaleNormalPrice;
    }

    function presaleBurnin(uint256[] calldata _cncTokenIds, uint256 _normalAmount, uint256 _rareAmount, uint248 _allowedAmount, bytes32[] calldata _merkleProof)
        external payable verifyMerkle(_allowedAmount, _merkleProof)
    {
        require(pauseData.isPresaleUnpaused, "CNCBurnin: presale paused");
        require(msg.value == (presaleNormalPrice * _normalAmount + presaleRarePrice * _rareAmount), "CNCBurnin: invalid value");
        require(userMintedAmount[msg.sender] + _cncTokenIds.length <= _allowedAmount, "CNCBurnin: exceed allowed amount");

        _burnAndMint(_cncTokenIds, _normalAmount, _rareAmount, msg.sender);
        userMintedAmount[msg.sender] += _cncTokenIds.length;
    }

    function setIsPublicSaleUnPaused(bool _isPublicSaleUnpaused) public onlyOwner {
        pauseData.isPublicSaleUnpaused = _isPublicSaleUnpaused;
    }

    function setPublicSaleRarePrice(uint256 _publicSaleRarePrice) public onlyOwner {
        publicSaleRarePrice = _publicSaleRarePrice;
    }

    function setPublicSaleNormalPrice(uint256 _publicSaleNormalPrice) public onlyOwner {
        publicSaleNormalPrice = _publicSaleNormalPrice;
    }

    function publicSaleBurnin(uint256[] calldata _cncTokenIds, uint256 _normalAmount, uint256 _rareAmount) external payable {
        require(pauseData.isPublicSaleUnpaused, "CNCBurnin: public sale paused");
        require(msg.value == (publicSaleNormalPrice * _normalAmount + publicSaleRarePrice * _rareAmount), "CNCBurnin: invalid value");

        _burnAndMint(_cncTokenIds, _normalAmount, _rareAmount, msg.sender);
    }

    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CNCBurnin: balance is 0");

        withdrawalAddress.transfer(balance);
    }

    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
