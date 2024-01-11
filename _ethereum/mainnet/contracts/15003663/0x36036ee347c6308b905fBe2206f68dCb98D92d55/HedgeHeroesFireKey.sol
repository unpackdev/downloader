// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Counters.sol";
import "./Pausable.sol";

contract HedgeHeroesFireKey is Ownable, ERC721A, Pausable {
    uint256 public maxSupply = 10000;

    uint256 public price = 0.005 ether;
    uint256 public freeUntilSupply = 8000;

    uint256 public maxMintablePerWallet = 3;
    mapping(address => uint256) public totalMintedPerWallet;

    string private baseURI;

    constructor() ERC721A("Fire Keys by Hedge Heroes", "FKHH") {
        _mint(_msgSender(), 200);
        _pause();
    }

    function mint(uint256 _amount) external payable whenNotPaused {
        require(
            totalSupply() + _amount <= maxSupply,
            "Max amount of keys has been reached"
        );
        require(
            totalMintedPerWallet[_msgSender()] + _amount <=
                maxMintablePerWallet,
            "You can't mint more keys"
        );
        if (totalSupply() >= freeUntilSupply)
            require(msg.value >= price * _amount, "Not enough ETH");

        _mint(_msgSender(), _amount);

        totalMintedPerWallet[_msgSender()] =
            totalMintedPerWallet[_msgSender()] +
            _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function airdrop(address[] memory _addresses, uint256 _amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amount);
        }
    }

    function burn(uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _burn(_ids[i]);
        }
    }

    function setPaused(bool _paused) external onlyOwner {
        _paused ? _pause() : _unpause();
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}
