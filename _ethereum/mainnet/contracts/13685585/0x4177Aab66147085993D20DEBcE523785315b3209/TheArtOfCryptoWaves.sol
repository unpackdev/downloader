// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TheArtOfCryptoWaves is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant TOTAL_NUMBER_OF_TOKENS = 3139;

    uint256 public limitPerWallet = 5;
    uint256 public giveawayReserved = 39;
    address public wavesWallet;

    string private _baseTokenURI = "";

    constructor(
        string memory _name,
        string memory _symbol,
        address _wavesWallet
    ) ERC721(_name, _symbol) {
        wavesWallet = _wavesWallet;
        super._pause();
    }

    receive() external payable {}

    fallback() external payable {}

    function giveAway(uint8 n) external onlyOwner {
        require(
            giveawayReserved >= n,
            "TheArtOfCryptoWaves: Exceeds giveaway reserved supply"
        );
        giveawayReserved -= n;
        uint256 supply = totalSupply();
        for (uint256 i; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 num) public payable whenNotPaused {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require(
            tokenCount + num <= limitPerWallet,
            "TheArtOfCryptoWaves: You reached the minting limit per wallet"
        );
        require(
            supply + num <= TOTAL_NUMBER_OF_TOKENS - giveawayReserved,
            "TheArtOfCryptoWaves: Exceeds maximum supply"
        );
        require(
            msg.value >= PRICE * num,
            "TheArtOfCryptoWaves: Ether sent is less than PRICE * num"
        );

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAmountToWallet(uint256 amount) public onlyOwner {
        uint256 _balance = address(this).balance;
        require(
            _balance > 0,
            "TheArtOfCryptoWaves: withdraw amount call without balance"
        );
        require(
            _balance - amount >= 0,
            "TheArtOfCryptoWaves: withdraw amount call with more than the balance"
        );
        require(
            payable(wavesWallet).send(amount),
            "TheArtOfCryptoWaves: FAILED withdraw amount call"
        );
    }

    function withdrawAllToWallet() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(
            _balance > 0,
            "TheArtOfCryptoWaves: withdraw all call without balance"
        );
        require(
            payable(wavesWallet).send(_balance),
            "TheArtOfCryptoWaves: FAILED withdraw all call"
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "TheArtOfCryptoWaves: URI query for nonexistent token"
        );

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}
