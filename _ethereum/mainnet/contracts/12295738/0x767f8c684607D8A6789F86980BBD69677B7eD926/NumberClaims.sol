// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract NumberClaims is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    uint256 private _price;

    function initialize() public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained('Number Claims', 'NMBR');
        __ERC721Enumerable_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __NumberClaims_init_unchained();
    }

    function __NumberClaims_init_unchained() internal initializer {
        _price = 0.1 ether;
    }

    function _baseURI() internal pure override returns (string memory) {
        return 'https://number.claims/api/';
    }

    // This modifier requires a certain fee being associated with a function call.
    // If the caller sent too much, he or she is refunded, but only after the function body.
    modifier costs(uint256 _amount) {
        require(msg.value >= _amount, 'not enough Ether provided');
        _;
        if (msg.value > _amount) payable(msg.sender).transfer(msg.value - _amount);
    }

    function mint(address recipient, uint256 number) external onlyOwner returns (uint256) {
        _safeMint(recipient, number);

        return number;
    }

    function setPrice(uint256 priceInWei) external onlyOwner {
        _price = priceInWei;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claim(uint256 number) external payable costs(_price) whenNotPaused returns (uint256) {
        // mint for sender
        _safeMint(_msgSender(), number);

        // send ether to the owner
        payable(owner()).transfer(_price);

        return number;
    }
}
