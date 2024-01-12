//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./PaymentSplitter.sol";

contract Seecret is ERC721A, Ownable, Pausable, PaymentSplitter {
    using SafeMath for uint256;

    uint256 public maxSupply = 10000;
    uint256 public freeMaxSupply = 2500;

    uint256 public maxPerWallet = 8;
    uint256 public price = 0.015 ether;

    string public baseTokenURI;

    uint256[] private _shares = [93, 7];
    address[] private _shareholders = [
        0x19733bB8564093b3a39C3373Bd25d751c4D18806,
        0xDfE2FEaDFb7c530EAe197Ba8779F1B1753d6cD8e
    ];

    constructor()
        ERC721A("Seecret", "SCRT")
        PaymentSplitter(_shareholders, _shares)
    {
        _pause();
    }

    function mint(uint256 _amount) external payable whenNotPaused {
        uint256 _totalSupply = totalSupply();

        require(
            _numberMinted(msg.sender).add(_amount) <= maxPerWallet,
            "Minting would exceed a wallet allowance"
        );

        require(_totalSupply.add(_amount) <= maxSupply, "Out of supply");

        if (_totalSupply.add(_amount) > freeMaxSupply) {
            require(msg.value >= price.mul(_amount), "Not enough ETH");
        }

        _safeMint(msg.sender, _amount);
    }

    function teamMint(uint256 _amount) external onlyOwner {
        _safeMint(msg.sender, _amount);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        price = _mintPrice;
    }

    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        maxPerWallet = _amount;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        for (uint256 sh; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function emergencyFundsWithdrawal(address _receiver, uint256 _amount)
        external
        onlyOwner
    {
        payable(_receiver).transfer(_amount);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
