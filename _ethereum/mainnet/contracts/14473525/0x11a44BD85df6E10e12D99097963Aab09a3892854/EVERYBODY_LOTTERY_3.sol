// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";

contract EVERYBODY_LOTTERY_3 is ERC721A {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 888;
    uint256 public PRICE = 0.01 ether;
    string public baseTokenURI;

    mapping(address => uint256) public CLAIM_LIST;
    mapping(address => uint256) public AWARD_ADDRESSES;
    mapping(string => uint256) public REFERRAL_LIST;

    address private _owner;

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0, "Invalid mint quantity");
        require(totalSupply() + quantity <= MAX_SUPPLY, "exceed 888 supply");
        require(PRICE * quantity <= msg.value, "Insufficient funds");
        _;
    }

    modifier claimCompliance() {
        require(CLAIM_LIST[_msgSender()] >= 1, "Address not in Claim List");
        _;
    }

    constructor(string memory baseURI)
        ERC721A("EVERYBODY LOTTERY 3", "E LOTTERY 3")
    {
        baseTokenURI = baseURI;
        _owner = _msgSender();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 p) external onlyOwner {
        PRICE = p;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        MAX_SUPPLY = max;
    }

    function setClaimList(
        address[] calldata addresses,
        uint256[] calldata quantities
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            CLAIM_LIST[addresses[i]] = quantities[i];
        }
    }

    function setAwardAddresses(
        address[] calldata addresses,
        uint256[] calldata values
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            AWARD_ADDRESSES[addresses[i]] = values[i];
        }
    }

    function deposit() external payable {}

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata quantities
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantities[i]);
        }
    }

    function claim() external claimCompliance {
        _safeMint(_msgSender(), CLAIM_LIST[_msgSender()]);
        delete CLAIM_LIST[_msgSender()];
    }

    function mint(uint256 quantity, string calldata referral)
        external
        payable
        mintCompliance(quantity)
    {
        _safeMint(_msgSender(), quantity);
        REFERRAL_LIST[referral] += quantity;
    }

    function awardPrize() external {
        address addr = _msgSender();
        require(AWARD_ADDRESSES[addr] > 0, "not in award list");
        (bool success, ) = addr.call{value: AWARD_ADDRESSES[addr]}("");
        require(success, "failed award, contact everybody");
        delete AWARD_ADDRESSES[addr];
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(_owner).call{value: address(this).balance}("");
        require(os);
    }
}
