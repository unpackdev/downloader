//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract BoredMeka is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKEN_SUPPLY = 7777;
    address public constant DEV_ADDRESS = 0xe59239D4d6706a0abbB5285a1BF51f0e0Acc8092;

    string public baseTokenURI;
    bytes32 public merkleRoot;

    bool private _whitelist;
    bool private _sale;
    uint256 private _price;
    uint256 private _maxSale;
    uint256 private _maxMintPerTx;
    mapping(address => bool) private _presaleListClaimed;

    constructor(string memory baseURI) ERC721A("BoredMeka", "BOREDMEKA") {
        setBaseURI(baseURI);
        _whitelist = true;
        _sale = false;
        _price = 0.077 ether;
        _maxSale = 7777;
        _maxMintPerTx = 10;

        // Mint the first token (id=0)
        _mintElements(msg.sender, 1);
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_TOKEN_SUPPLY, "Sale ended");
        _;
    }

    function mint(
        uint256 _count,
        uint256 _presaleMaxAmount,
        bytes32[] calldata _merkleProof
    ) public payable saleIsOpen {
        uint256 total = totalSupply();
        require(total <= MAX_TOKEN_SUPPLY, "BoredMeka: Max limit");
        require(total + _count <= MAX_TOKEN_SUPPLY, "BoredMeka: Max limit");
        require(total + _count <= _maxSale, "BoredMeka: Max sale limit");
        require(_count <= _maxMintPerTx, "BoredMeka: Max mint for tx limit");
        require(_sale, "BoredMeka: Sale is not active");
        require(msg.value >= getPrice(_count), "BoredMeka: Value below price");

        if (_whitelist == true) {
            // Verify if the account has already claimed
            require(
                !isPresaleListClaimed(msg.sender),
                "BoredMeka: account already claimed"
            );

            // Verify we cannot claim more than the max amount
            require(
                _count <= _presaleMaxAmount,
                "BoredMeka: can only claim less than or equal to the max amount"
            );

            // Verify the merkle proof.
            require(
                validClaim(msg.sender, _presaleMaxAmount, _merkleProof),
                "BoredMeka: invalid proof"
            );

            _presaleListClaimed[msg.sender] = true;
        }

        _mintElements(msg.sender, _count);
    }

    // @dev start of public/external views
    function isPresaleListClaimed(address account) public view returns (bool) {
        return _presaleListClaimed[account];
    }

    function validClaim(
        address claimer,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(claimer, maxAmount.toString()));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        return _price.mul(_count);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function whitelistActive() external view returns (bool) {
        return _whitelist;
    }

    function saleActive() external view returns (bool) {
        return _sale;
    }
    // @dev end of public/external views

    // @dev start of internal/private functions
    function _mintElements(address _to, uint256 _amount) private {
        _safeMint(_to, _amount);
        require(totalSupply() <= MAX_TOKEN_SUPPLY, "BoredMeka: limit reached");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _payout(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "BoredMeka: transfer failed");
    }
    // @dev end of internal/private functions

    // @dev start of only owner functions
    function mintReserve(uint256 _count, address _to) public onlyOwner {
        uint256 total = totalSupply();
        require(total <= MAX_TOKEN_SUPPLY, "BoredMeka: sale ended");
        require(total + _count <= MAX_TOKEN_SUPPLY, "BoredMeka: max limit");
        _mintElements(_to, _count);
    }

    function setMaxSale(uint256 maxSale) external onlyOwner {
        _maxSale = maxSale;
    }

    function setPrice(uint256 priceInWei) external onlyOwner {
        _price = priceInWei;
    }

    function setMaxMintPerTx(uint256 maxMintPerTx) external onlyOwner {
        _maxMintPerTx = maxMintPerTx;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleWhitelist() public onlyOwner {
        _whitelist = !_whitelist;
    }

    function toggleSale() public onlyOwner {
        _sale = !_sale;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "BoredMeka: malance should be above 0");
        _payout(DEV_ADDRESS, address(this).balance);
    }
    // @dev end of only owner functions
}
