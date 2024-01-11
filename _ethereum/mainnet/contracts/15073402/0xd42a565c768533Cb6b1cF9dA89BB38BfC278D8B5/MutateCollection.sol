// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MutateCollection is ERC721, ERC721Enumerable, Ownable {
    using Address for address;
    using MerkleProof for bytes32[];

    mapping(address => uint256) private _mintCount;
    uint256 private _totalRevenue;
    bytes32 private _merkleRoot;
    string private _tokenBaseURI;

    address private _mutateActor;

    // Sales Parameters
    uint256 private _maxAmount;
    uint256 private _maxPerMint;
    uint256 private _maxPerWallet;
    uint256 private _price;

    // Auction Parameters
    uint256 private _startPrice;
    uint256 private _endPrice;
    uint256 private _duration;
    uint256 private _startedAt;

    // States
    bool private _mutateActive;
    bool private _presaleActive;
    bool private _saleActive;
    bool private _auctionActive;

    modifier onlyMintable(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "Greater than 0");
        require(
            _mintCount[_msgSender()] + numberOfTokens <= _maxPerWallet,
            "Exceeded max"
        );
        require(totalSupply() + numberOfTokens <= _maxAmount, "Exceeded max");
        _;
    }

    modifier onlyMutatable() {
        require(
            _msgSender() == _mutateActor || _msgSender() == owner(),
            "Unpermitted"
        );
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _mutateActive = true;
        _presaleActive = false;
        _saleActive = false;
        _auctionActive = false;
    }

    function mint(uint256 numberOfTokens)
        public
        payable
        onlyMintable(numberOfTokens)
    {
        require(!_mutateActive && !_presaleActive, "Not active");
        require(_auctionActive || _saleActive, "Not active");

        _purchaseMint(numberOfTokens, _msgSender());
    }

    function presaleMint(uint256 numberOfTokens, bytes32[] calldata proof)
        public
        payable
        onlyMintable(numberOfTokens)
    {
        require(!_mutateActive && _presaleActive, "Not active");
        require(_merkleRoot != "", "Not active");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not active"
        );

        _purchaseMint(numberOfTokens, _msgSender());
    }

    function mutateMint(uint256 tokenId, address recipient)
        external
        onlyMutatable
    {
        require(_mutateActive, "Not active");
        _safeMint(recipient, tokenId); // duplication check will be done in ERC721Upgradeable
    }

    function batchMutateMint(
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external onlyMutatable {
        require(_mutateActive, "Not active");
        require(tokenIds.length == recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], tokenIds[i]);
        }
    }

    function batchAirdrop(
        uint256[] calldata numberOfTokens,
        address[] calldata recipients
    ) external onlyOwner {
        require(!_mutateActive, "Not active");
        require(numberOfTokens.length == recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(numberOfTokens[i], recipients[i]);
        }
    }

    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        _merkleRoot = newRoot;
    }

    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) public onlyOwner {
        _saleActive = true;
        _presaleActive = presale;

        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _price = newPrice;
    }

    function startAuction(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newStartPrice,
        uint256 newEndPrice,
        uint256 newDuration,
        bool presale
    ) public onlyOwner {
        _auctionActive = true;
        _presaleActive = presale;

        _startedAt = block.timestamp;
        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _endPrice = newEndPrice;
        _startPrice = newStartPrice;
        _duration = newDuration;
    }

    function stopSale() public onlyOwner {
        _saleActive = false;
        _auctionActive = false;
        _presaleActive = false;
    }

    function activeMutate(bool flag) public onlyOwner {
        _mutateActive = flag;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function setMutateActor(address newMutateActor) public onlyOwner {
        _mutateActor = newMutateActor;
    }

    function mutateActor() external view returns (address) {
        return _mutateActor;
    }

    function maxAmount() external view returns (uint256) {
        return _maxAmount;
    }

    function maxPerMint() external view returns (uint256) {
        return _maxPerMint;
    }

    function maxPerWallet() external view returns (uint256) {
        return _maxPerWallet;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function totalRevenue() external view returns (uint256) {
        return _totalRevenue;
    }

    function mutateActive() external view returns (bool) {
        return _mutateActive;
    }

    function presaleActive() external view returns (bool) {
        return _presaleActive;
    }

    function saleActive() external view returns (bool) {
        return _saleActive;
    }

    function auctionActive() external view returns (bool) {
        return _auctionActive;
    }

    function auctionStartedAt() external view returns (uint256) {
        return _startedAt;
    }

    function auctionDuration() external view returns (uint256) {
        return _duration;
    }

    function auctionPrice() public view returns (uint256) {
        if ((block.timestamp - _startedAt) >= _duration) {
            return _endPrice;
        } else {
            return
                ((_duration - (block.timestamp - _startedAt)) *
                    (_startPrice - _endPrice)) /
                _duration +
                _endPrice;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _purchaseMint(uint256 numberOfTokens, address sender) internal {
        uint256 mintPrice = _auctionActive
            ? auctionPrice() * numberOfTokens
            : _price * numberOfTokens;
        require(mintPrice <= msg.value, "Value incorrect");

        _totalRevenue = _totalRevenue + msg.value;
        _mintCount[sender] = _mintCount[sender] + numberOfTokens;
        _mint(numberOfTokens, sender);
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        require(
            _maxAmount > 0
                ? totalSupply() + numberOfTokens <= _maxAmount
                : true,
            "Exceeded max"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(sender, mintIndex);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
