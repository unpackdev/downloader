// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Pausable.sol";

contract MintMeDaddy is ERC721A, Ownable, Pausable {
    uint256 public maxSupply = 6969;
    uint256 public price = 0.006969 ether;

    string private baseURI = 'http://ipfs.io/ipfs/Qmb5tRhjAxY6jsSCpQjrK951B7VC9eRbGUwYCM5eKEaXRj/';

    mapping(address => bool) public walletHasMinted;

    constructor() ERC721A("Mint Me Daddy", "MMD") {
        _pause();
    }

    function mint(uint256 _amount) external payable whenNotPaused {
        require(totalSupply() + _amount <= maxSupply);

        require(msg.value >= getPrice(_amount, msg.sender));

        _mint(msg.sender, _amount);

        walletHasMinted[msg.sender] = true;
    }

    function getPrice(uint256 _amount, address _wallet)
        public
        view
        returns (uint256)
    {
        uint256 maxMintableForFree;
        if (walletHasMinted[_wallet]) maxMintableForFree = 0;
        else if (totalSupply() <= 3000) maxMintableForFree = 3;
        else maxMintableForFree = 1;


        uint256 myPrice;
        if (_amount <= maxMintableForFree) myPrice = 0;
        else myPrice = price * (_amount - maxMintableForFree);

        return myPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        _paused ? _pause() : _unpause();
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}
