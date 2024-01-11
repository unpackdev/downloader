// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MinionsInWeb3 is ERC721A, Ownable, ReentrancyGuard {
    uint256 public price = 0.001 ether;
    uint256 public maxSupply = 10400;
    uint256 public maxperAddress = 2;
    bool public isMintEnabled;
    string internal baseURI;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMinted;

    constructor() ERC721A("MinionsInWeb3", "GRU") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setIsMintEnabled(bool _isMintEnabled) external onlyOwner {
        isMintEnabled = _isMintEnabled;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "Minion does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID), ".json"));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        require(success, "Withdraw failed");
    }

    /******************** MINT FUNCTIONS ********************/

    function mint(uint256 _quantity) public payable nonReentrant {
        uint256 tempSupply = totalSupply();
        require(isMintEnabled, "Minion store is not open yet!");
        require(_quantity > 0, "Must mint at least 1 Minion!");
        require(_quantity <= maxperAddress, "You've got enough Minions already!" );
        require(tempSupply + _quantity <= maxSupply, "No more Minions in stock!");
        require(msg.value >= price * _quantity);
        _mint(msg.sender, _quantity);
        delete tempSupply;
    }

    function gruMint(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Provide quantities and recipients");
        uint256 totalQuantity = 0;
        uint256 tempSupply = totalSupply();
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(tempSupply + totalQuantity <= maxSupply, "Too many Minions in Web3");
        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            _mint(recipient[i], quantity[i]);
        }
        delete tempSupply;
    }
}