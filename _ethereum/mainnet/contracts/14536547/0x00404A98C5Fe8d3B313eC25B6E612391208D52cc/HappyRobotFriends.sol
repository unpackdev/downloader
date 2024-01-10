// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package.sol";

/**
 * @title Happy Robot Friends
 */
contract HappyRobotFriends is Package {
    receive() external payable {}
    fallback() external payable {}

    event Withdrawal(address operator, address receiver, uint256 value);

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _claimer;
    mapping(address => uint256) _mintLimit;
    mapping(address => uint256) _preMintLimit;

    uint256 private _price;

    bool private _publicMintPaused;
    bool private _preMintPaused;
    bool private _freeMintPaused;

    bool private _locked;

    modifier gate() {
        require(_locked == false, "HRF: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(address _contractOwner) Package("Happy Robot Friends", "HRF") {
        _transferOwnership(_contractOwner);
        _price = 100000000000000000;
        _publicMintPaused = true;
        _preMintPaused = true;
        _freeMintPaused = true;
        _locked == false;
    }

    function addClaimers(address[] memory _accounts, uint256 _quantity) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _claimer[_accounts[i]] = _quantity;
        }
    }

    function revokeClaimers(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _claimer[_accounts[i]] = 0;
        }
    }

    function claimable(address _account) public view returns (uint256) {
        return _claimer[_account];
    }

    function addWhitelist(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _whitelist[_accounts[i]] = true;
        }
    }

    function revokeWhitelist(address[] memory _accounts) public ownership {
        for (uint i = 0; i < _accounts.length; i++) {
            _whitelist[_accounts[i]] = false;
        }
    }

    function whitelisted(address _account) public view returns (bool) {
        return _whitelist[_account];
    }

    function mintPrice() public view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 _value) public ownership {
        _price = _value;
    }

    function publicMintPause(bool _bool) public ownership {
        _publicMintPaused = _bool;
    }

    function publicMintPauseStatus() public view returns (bool) {
        return _publicMintPaused;
    }

    function preMintPause(bool _bool) public ownership {
        _preMintPaused = _bool;
    }

    function preMintPauseStatus() public view returns (bool) {
        return _preMintPaused;
    }

    function freeMintPause(bool _bool) public ownership {
        _freeMintPaused = _bool;
    }

    function freeMintPauseStatus() public view returns (bool) {
        return _freeMintPaused;
    }

    function publicMint(uint256 _quantity) public payable gate {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_publicMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_mintLimit[msg.sender] < 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function preMint(uint256 _quantity) public payable gate {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_whitelist[msg.sender] == true, "HRF: caller not on the whitelist");
        require(_preMintPaused != true, "HRF: minting is paused");
        require(msg.value >= mintPrice(), "HRF: not enough funds provided");
        if (_quantity == 2) {require(msg.value >= (mintPrice() * 2), "HRF: not enough funds provided");}
        require(_quantity <= 2, "HRF: Cannot mint more than 2 tokens");
        require(_preMintLimit[msg.sender] < 2, "HRF: Maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _preMintLimit[msg.sender] += 1;
            _mint(msg.sender);
        }
    }

    function freeMint() public gate {
        require(_claimer[msg.sender] + totalSupply() <= 3333, "HRF: maximum tokens minted");
        require(_freeMintPaused != true, "HRF: minting is paused");
        require(_claimer[msg.sender] >= 1, "HRF: not a claimer or already claimed");
        uint256 _totalAmount = _claimer[msg.sender];
        for (uint256 i=0; i < _totalAmount; i++) {
            _claimer[msg.sender] -= 1;
            _mint(msg.sender);
        }
    }

    function ownershipMint(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 3333, "HRF: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mintLimit[msg.sender] += 1;
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "HRF: ether transfer failed");

        emit Withdrawal(msg.sender, _account, balance);
    }
}