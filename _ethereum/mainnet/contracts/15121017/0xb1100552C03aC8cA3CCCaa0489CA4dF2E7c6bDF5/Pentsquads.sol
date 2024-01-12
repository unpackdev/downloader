// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Pentsquads is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 constant MINT_PRICE = 22000000000000000; // 0.022 ETH
    uint256 constant MAX_AMOUNT = 5000;

    mapping(address=>bool) public whitelisted;
    mapping(address=>uint256) public totalMinted;
    mapping(address=>bool) public gotFreeOne;
    uint256 totalFree = 800;

    uint256 constant PREMINT_STARTS = 1657544400;
    uint256 constant MINT_STARTS = 1657555200;

    bool giveawaysMinted;

    constructor() ERC721("Pentsquads", "PSQ") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://pentsquads.wtf/api/metadata/";
    }

    function mintPentsquads(uint256 _total) public payable {
        require(block.timestamp > PREMINT_STARTS, "Premint didn't start yet");
        require(block.timestamp > MINT_STARTS || whitelisted[msg.sender], "Mint didn't start yet");
        require(totalMinted[msg.sender] + _total <= 5, "Max 5 Pentsquads in total");
        require(_tokenIdCounter.current() + _total <= MAX_AMOUNT, "Max reached");
        require(msg.value >= MINT_PRICE * _total, "Invalid amount");

        totalMinted[msg.sender] += _total;

        if (!gotFreeOne[msg.sender] && totalFree > 0) {
            gotFreeOne[msg.sender] = true;
            totalFree -= 1;
            _safeMint(msg.sender);
        }

        for (uint i = 0; i < _total; i++) {
            _safeMint(msg.sender);
        }
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _setWhitelisted(address[] memory _wallets, bool _whitelisted) public onlyOwner {
        for (uint i=0; i < _wallets.length; i++) {
            whitelisted[_wallets[i]] = _whitelisted;
        }
    }

    function _mintGiveaways() public {
        require(!giveawaysMinted, "Already minted");
        giveawaysMinted = true;
        for (uint i = 0; i < 200; i++) { 
            _safeMint(owner());
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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

    uint256 devFees = 407489000000000000;
    address devWallet = 0x5401837746C9bCc480dCC41AF1Ef430012C65bD5;

    function _withdrawFees() public {
        if (devFees > address(this).balance) {
            devFees -= address(this).balance;
            payable(devWallet).transfer(address(this).balance);
        } else if (devFees > 0) {
            uint256 remaining = address(this).balance - devFees;
            payable(devWallet).transfer(devFees);
            devFees = 0;
            if (remaining > 0) {
                payable(owner()).transfer(remaining);
            }
        } else {
            payable(owner()).transfer(address(this).balance);
        }
    }
}
