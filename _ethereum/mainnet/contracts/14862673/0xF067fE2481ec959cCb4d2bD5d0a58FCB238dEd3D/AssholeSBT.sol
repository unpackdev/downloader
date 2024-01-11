//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";

contract AssholeSBT {
    using Address for address;
    using Strings for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event AdminUpdate(
        address indexed edited,
        address indexed editor,
        bool indexed newStatus
    );

    event PriceChange(string indexed mintOrBurn, uint256 indexed amount);

    event WithdrawalTargetChange(
        address indexed newTarget,
        address indexed changer
    );

    struct ContractData {
        address launcher;
        address withdrawalTarget;
        string _name;
        string _symbol;
        uint256 amountStored;
        uint256 burnPrice;
        uint256 mintPrice;
        bool isActive;
        string _inactiveMessage;
        uint256 totalSupply;
    }

    ContractData public contractData;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _freeMinters;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => address) public _minters;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => string) private _uris;

    constructor() {
        contractData._name = "Asshole Soul Bound Token";
        contractData._symbol = "ASBT";
        _admins[msg.sender] = true;
        contractData.totalSupply = 0;
        contractData.burnPrice = 1 ether;
        contractData.mintPrice = 0.01 ether;
        contractData.withdrawalTarget = msg.sender;
        contractData.isActive = true;
        contractData
            ._inactiveMessage = "The Asshole SBT has been turned off, thanks for playing.";
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "wtf");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "wtf");
        return owner;
    }

    function setActivity(bool _newStatus) external {
        require(_admins[msg.sender], "no perms");
        contractData.isActive = _newStatus;
    }

    function editFreeMinter(address _freeMinter, bool _allow) external {
        require(_admins[msg.sender], "no perms");
        _freeMinters[_freeMinter] = _allow;
    }

    function addAdmin(address _newAdmin) external {
        require(_admins[msg.sender], "no perms");
        _admins[_newAdmin] = true;
        emit AdminUpdate(_newAdmin, msg.sender, true);
    }

    function removeAdmin(address _oldAdmin) external {
        require(_admins[msg.sender], "no perms");
        require(_oldAdmin != contractData.launcher, "wtf");
        _admins[msg.sender] = false;
        emit AdminUpdate(_oldAdmin, msg.sender, false);
    }

    function renounceAdmin() external {
        require(_admins[msg.sender], "no perms");
        _admins[msg.sender] = false;
    }

    function name() public view returns (string memory) {
        return contractData._name;
    }

    function symbol() public view returns (string memory) {
        return contractData._symbol;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function getOwnedTokens(address _user) external view returns(uint256[] memory) {
        return _ownedTokens[_user];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "wtf");
        if (!contractData.isActive) {
            return string(contractData._inactiveMessage);
        } else {
            return string(_uris[tokenId]);
        }
    }

    function changePrice(bool mintOrBurn, uint256 _newPrice) external {
        require(_admins[msg.sender], "no perms");
        if (mintOrBurn == true) {
            contractData.mintPrice = _newPrice;
            emit PriceChange("mint", _newPrice);
        }
        if (mintOrBurn == false) {
            contractData.burnPrice = _newPrice;
            emit PriceChange("burn", _newPrice);
        }
    }

    function changeWithdrawalAddress(address _newTarget) external {
        require(_admins[msg.sender], "no perms");
        contractData.withdrawalTarget = _newTarget;
        emit WithdrawalTargetChange(_newTarget, msg.sender);
    }

    function findOwnedTokenIndex(address holder, uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 foundId = 0;
        for (uint256 i = 0; i <= _ownedTokens[holder].length; i++) {
            if (_ownedTokens[holder][i] == value) {
                foundId = i;
            }
        }
        return foundId;
    }

    function mint(address to, string memory _reason) public payable {
        require(to != address(0), "dumbass");
        require(to != msg.sender, "no self owns");
        if (!_admins[msg.sender] && !_freeMinters[msg.sender]) {
            require(msg.value >= contractData.mintPrice, "ain't a charity...");
        }
        contractData.amountStored += msg.value;
        ++contractData.totalSupply;
        _balances[to] += 1;
        _owners[contractData.totalSupply] = to;
        _ownedTokens[to].push(contractData.totalSupply);
        _uris[contractData.totalSupply] = _reason;
        _minters[contractData.totalSupply] = msg.sender;
        emit Transfer(address(0), to, contractData.totalSupply);
    }

    function burn(uint256 id) public payable {
        if (!_admins[msg.sender]) {
            require(msg.value >= contractData.burnPrice, "stake me");
        }
        contractData.amountStored += msg.value;
        address owner = ownerOf(id);
        _balances[owner] -= 1;
        delete _owners[id];

        emit Transfer(owner, address(0), id);
    }

    function withdraw() public payable {
        require(_admins[msg.sender], "f off");
        uint256 amount_to_send = contractData.amountStored;
        contractData.amountStored = 0;
        payable(msg.sender).transfer(amount_to_send);
    }
}
