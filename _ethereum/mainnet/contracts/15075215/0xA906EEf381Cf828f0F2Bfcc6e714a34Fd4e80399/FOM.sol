// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

Built by W3bbie

*/

//import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract FOM is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    uint256 public maxSupply = 3333;
    uint256 public maxMintAmountPerTx = 3;
    bool public paused = false;
    string public uriPrefix;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        uriPrefix = baseURI;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            balanceOf(msg.sender) < 3,
            "Only three tokens per wallet is allowed"
        );
        require(!paused, "The contract is paused!");
        _;
    }

    /**
     */
    function setURI(string memory _uri) external onlyOwner {
        uriPrefix = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        _mintLoop(msg.sender, _mintAmount);
    }

    function magicMint(uint256 _mintAmount) external onlyOwner {
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );

        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
