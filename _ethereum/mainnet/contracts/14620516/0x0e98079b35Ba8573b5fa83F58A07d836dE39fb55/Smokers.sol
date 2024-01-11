// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Smokers is ERC721A, Ownable {
    uint256 public constant CLOSED_SALE = 0;
    uint256 public constant ALLOWLIST_SALE = 1;
    uint256 public constant PUBLIC_SALE = 2;

    uint256 public saleState = CLOSED_SALE;

    mapping(address => uint256) private _allowList;

    address payable private _wallet;
    address payable private _devWallet;

    uint256 public maxSupply;
    bool public maxSupplyLocked;
    uint256 public allowListPrice;
    uint256 public publicMintPrice;

    // basis of 100
    uint256 private _devShare;
    string baseURI = "ipfs://";

    constructor(
        address payable wallet,
        address payable devWallet,
        uint256 initialMaxSupply,
        uint256 initialAllowListPrice,
        uint256 initialPublicMintPrice,
        uint256 devShare
    ) ERC721A("The Smokers", "SMOKER") {
        _wallet = wallet;
        _devWallet = devWallet;
        maxSupply = initialMaxSupply;
        allowListPrice = initialAllowListPrice;
        publicMintPrice = initialPublicMintPrice;

        _devShare = devShare;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function mint(uint256 count) external payable {
        require(saleState != CLOSED_SALE, "Smokers: sale is closed");
        require(totalSupply() + count <= maxSupply, "Smokers: none left");

        if (saleState == PUBLIC_SALE) {
            _mintFromPublicSale(count);
            return;
        }

        _mintFromAllowList(count);
    }

    function devMint(uint256 count) public payable onlyOwner {
        require(totalSupply() + count <= maxSupply, "Smokers: none left");
        _safeMint(msg.sender, count);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function lockMaxSupply() public onlyOwner {
        maxSupplyLocked = true;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(
            !maxSupplyLocked,
            "Smokers: cannot change max supply, it is locked"
        );
        require(
            newMaxSupply >= _totalMinted(),
            "Smokers: cannot set max supply less than current minted supply"
        );
        maxSupply = newMaxSupply;
    }

    function setAllowListPrice(uint256 newPrice) public onlyOwner {
        allowListPrice = newPrice;
    }

    function setPublicMintPrice(uint256 newPrice) public onlyOwner {
        publicMintPrice = newPrice;
    }

    function _mintFromAllowList(uint256 count) internal {
        require(
            msg.value >= allowListPrice * count,
            "Smokers: not enough funds sent"
        );

        uint256 numAllowedMints = _allowList[_msgSender()];

        require(
            numAllowedMints >= count,
            "Smokers: sender does not have enough allow list entries"
        );

        _allowList[_msgSender()] = numAllowedMints - count;

        _safeMint(msg.sender, count);
    }

    function _mintFromPublicSale(uint256 count) internal {
        require(
            msg.value >= publicMintPrice * count,
            "Smokers: not enough funds sent"
        );
        _safeMint(msg.sender, count);
    }

    function setSaleState(uint256 nextSaleState) public onlyOwner {
        require(
            nextSaleState >= 0 && nextSaleState <= 2,
            "Smokers: sale state out of range"
        );
        saleState = nextSaleState;
    }

    function setAllowListEntries(address allowLister, uint256 amount)
        public
        onlyOwner
    {
        _allowList[allowLister] = amount;
    }

    function setMultipleAllowListEntries(
        address[] memory allowListers,
        uint256 amount
    ) public onlyOwner {
        for (uint256 i; i < allowListers.length; i++) {
            _allowList[allowListers[i]] = amount;
        }
    }

    function numAllowListEntries(address allowLister)
        public
        view
        returns (uint256)
    {
        return _allowList[allowLister];
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devPayment = (balance * _devShare) / 100;
        uint256 remainder = balance - devPayment;

        (bool success, ) = _devWallet.call{value: devPayment}("");
        (bool success2, ) = _wallet.call{value: remainder}("");

        require(success && success2, "Smokers: withdrawl failed");
    }

    function allOwners() external view returns (address[] memory) {
        address[] memory _allOwners = new address[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i++) {
            if (_exists(i)) {
                address owner = ownerOf(i);
                _allOwners[i] = owner;
            } else {
                _allOwners[i] = address(0x0);
            }
        }

        return _allOwners;
    }

    // payable fallback
    fallback() external payable {}

    receive() external payable {}
}
