// SPDX-License-Identifier: MIT

/*
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  +
|__       __                                __        __            __       __             ______   __                |
|  \     /  \                              |  \      |  \          |  \     /  \           /      \ |  \               |
| $$\   /  $$ __    __  _______    _______ | $$____   \$$  ______  | $$\   /  $$  ______  |  $$$$$$\ \$$  ______       |
| $$$\ /  $$$|  \  |  \|       \  /       \| $$    \ |  \ /      \ | $$$\ /  $$$ |      \ | $$_  \$$|  \ |      \      |
| $$$$\  $$$$| $$  | $$| $$$$$$$\|  $$$$$$$| $$$$$$$\| $$|  $$$$$$\| $$$$\  $$$$  \$$$$$$\| $$ \    | $$  \$$$$$$\     |
| $$\$$ $$ $$| $$  | $$| $$  | $$| $$      | $$  | $$| $$| $$    $$| $$\$$ $$ $$ /      $$| $$$$    | $$ /      $$     |
| $$ \$$$| $$| $$__/ $$| $$  | $$| $$_____ | $$  | $$| $$| $$$$$$$$| $$ \$$$| $$|  $$$$$$$| $$      | $$|  $$$$$$$     |
| $$  \$ | $$ \$$    $$| $$  | $$ \$$     \| $$  | $$| $$ \$$     \| $$  \$ | $$ \$$    $$| $$      | $$ \$$    $$     |
|\$$      \$$  \$$$$$$  \$$   \$$  \$$$$$$$ \$$   \$$ \$$  \$$$$$$$ \$$      \$$  \$$$$$$$ \$$       \$$  \$$$$$$$     |
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  +
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

contract MunchieMafia is ERC721, ERC721Enumerable, Ownable, PaymentSplitter {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant PRICE_PER_TOKEN = 0.09 ether;

    mapping(address => uint16) private _allowList;

    constructor(address[] memory payees, uint256[] memory shares)
        ERC721("MunchieMafiaNightClub", "MMNC")
        PaymentSplitter(payees, shares)
    {}

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint16 numAllowedToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint16) {
        return _allowList[addr];
    }

    function mintAllowList(uint16 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(
            numberOfTokens <= _allowList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

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
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(
            numberOfTokens <= MAX_PUBLIC_MINT,
            "Exceeded max token purchase"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            PRICE_PER_TOKEN * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
