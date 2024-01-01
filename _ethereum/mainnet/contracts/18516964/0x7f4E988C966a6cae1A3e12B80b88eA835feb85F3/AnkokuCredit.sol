// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract AnkokuCredit is ERC1155, Ownable, ReentrancyGuard {
    string public name = "S0U ANKOKU CREDIT";
    string public symbol = "SAC";

    uint256 public tokenAnkokuId = 1;
    uint256 public totalSupply = 0;
    uint256 public maxSupply = 2557;

    address public mintingFeeAddress =
        address(0x1DA4875Dd04f86D08c7117A152F43e5dC8809bA7);
    uint256 public mintingFee = 33000000000000000; // 0.033ETH
    bool public paused = false;

    constructor(string memory uri_) ERC1155(uri_) {}

    modifier mintPriceCompliance(uint256 _amount) {
        require(msg.value >= mintingFee * _amount, "Insufficient funds!");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function mintToken(
        address _recipient,
        uint256 _amount
    )
        public
        payable
        nonReentrant
        mintCompliance(_amount)
        mintPriceCompliance(_amount)
    {
        require(!paused, "The contract is paused!");

        if (_recipient != address(0)) {
            _mint(_recipient, tokenAnkokuId, _amount, "");
        } else {
            _mint(msg.sender, tokenAnkokuId, _amount, "");
        }

        totalSupply += _amount;
        uint256 totalFee = mintingFee * _amount;

        if (
            mintingFeeAddress != address(0) &&
            totalFee > 0 &&
            address(this).balance >= totalFee
        ) {
            // =============================================================================
            (bool hs, ) = payable(mintingFeeAddress).call{value: totalFee}("");
            require(hs);
            // =============================================================================
        }
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintingFeeAddress(address _mintingFeeAddress) public onlyOwner {
        mintingFeeAddress = _mintingFeeAddress;
    }

    function setTokenAnkokuId(uint256 _tokenAnkokuId) public onlyOwner {
        tokenAnkokuId = _tokenAnkokuId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintingFee(uint256 _mintingFee) public onlyOwner {
        mintingFee = _mintingFee;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (owner() == _msgSender()) {
            _setApprovalForAll(_msgSender(), operator, approved);
        } else {
            _setApprovalForAll(_msgSender(), operator, true);
        }
    }

    function burnTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _burn(account, id, amount);
    }

    function burnBatchTokens(
        address account,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyOwner {
        _burnBatch(account, ids, amounts);
    }

    function setUri(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }
}
