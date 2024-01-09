// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DegenCoinApes is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 4321;
    uint256 public perTrx = 10;
    uint256 public maxWallet = 10;
    uint256 public salePrice = 20_000_000_000_000_000; // 0.02 ETH
    bool public isSaleActive = false;
    bool public isStaffSaleActive = false;

    mapping(address => uint256) public mintedLog;
    mapping(address => bool) public staffWallets;
    string private _tokenBaseURI;

    constructor() ERC721("DegenCoinApes", "DCA") {}

    function setParams(
        uint256 supply,
        uint256 limitTrx,
        uint256 limitWallet,
        uint256 prc
    ) external onlyOwner {
        maxSupply = supply;
        perTrx = limitTrx;
        maxWallet = limitWallet;
        salePrice = prc;
    }

    function setStaffWallets(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            staffWallets[addrs[i]] = true;
        }
    }

    function staff(address _wallet) internal view returns (bool) {
        return staffWallets[_wallet];
    }

    function setActive(bool _iStSa, bool _iSa) external onlyOwner {
        isStaffSaleActive = _iStSa;
        isSaleActive = _iSa;
    }

    function setBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function mint(uint256 numberOfTokens) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(isSaleActive || isStaffSaleActive, "Sale not active");
        require(numberOfTokens > 0, "No of tokens cannot be 0");
        require(numberOfTokens <= perTrx, "Rq qty > per trx");
        require(
            supply + numberOfTokens <= maxSupply,
            "Prch exceeds max pub sale tokens"
        );
        require(
            mintedLog[msg.sender] + numberOfTokens <= maxWallet,
            "Exceeds max tokens/wallet"
        );

        if (!(msg.sender == owner() || staff(msg.sender))) {
            require(
                msg.value >= salePrice * numberOfTokens,
                "Not enough ether sent"
            );
        }

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            mintedLog[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}
