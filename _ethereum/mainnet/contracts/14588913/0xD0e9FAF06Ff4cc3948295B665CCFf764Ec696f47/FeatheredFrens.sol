// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Package.sol";

/**
 * @title Feathered Frens
 */
contract FeatheredFrens is Package {
    receive() external payable {}
    fallback() external payable {}

    event Withdraw(address operator, address receiver, uint256 value);

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) _mintLimit;

    uint256 private _limit;

    bool private _mintPaused;
    bool private _freeForAllPaused;
    bool private _locked;

    modifier gate() {
        require(_locked == false, "FF: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(address _contractOwner, bytes32 _merkleRoot) Package("Feathered Frens", "FF") {
        _transferOwnership(_contractOwner);
        _mintPaused = true;
        _freeForAllPaused = true;
        _locked == false;
        setMintLimit(10);
        setMerkleRoot(_merkleRoot);
    }

    function mintPause(bool _bool) public ownership {
        _mintPaused = _bool;
    }

    function mintPauseStatus() public view returns (bool) {
        return _mintPaused;
    }

    function freeForAllPause(bool _bool) public ownership {
        _freeForAllPaused = _bool;
    }

    function freeForAllPauseStatus() public view returns (bool) {
        return _freeForAllPaused;
    }

    function setMintLimit(uint256 _amount) public ownership {
        _limit = _amount;
    }

    function mintLimit() public view returns (uint256) {
        return _limit;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public ownership {
        _setMerkleRoot(_merkleRoot);
    }

    function totalMinted(address _account) public view returns (uint256) {
        return _mintLimit[_account];
    }

    function freeForAll(address _to, uint256 _quantity) public gate {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        require(_quantity <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_quantity + _mintLimit[_to] <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_freeForAllPaused != true, "FF: minting is paused");
        _mintLimit[_to] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function mint(address _to, bytes32[] calldata _merkleProof, uint256 _quantity) public gate {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        require(_quantity <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_quantity + _mintLimit[_to] <= mintLimit(), "FF: 10 tokens allowed to mint");
        require(_mintPaused != true, "FF: minting is paused");
        _mintLimit[_to] += _quantity;
        for (uint256 i=0; i < _quantity; i++) {
            _whitelistMint(_to, _merkleProof, merkleRoot());
        }
    }

    function airdropBatch(address[] memory _to) public ownership {
        require(_to.length + totalSupply() <= 5555, "FF: maximum tokens minted");
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i]);
        }
    }

    function airdrop(address _to, uint256 _quantity) public ownership {
        require(_quantity + totalSupply() <= 5555, "FF: maximum tokens minted");
        for (uint256 i=0; i < _quantity; i++) {
            _mint(_to);
        }
    }

    function withdraw(address _account) public ownership {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_account).call{value: address(this).balance}("");
        require(success, "FF: ether transfer failed");

        emit Withdraw(msg.sender, _account, balance);
    }
}
