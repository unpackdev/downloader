// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "Ownable.sol";
import "ERC1155.sol";
import "ReentrancyGuard.sol";


/*
                                        Authors: madjin.eth
                                            year: 2021

                ███╗░░░███╗░█████╗░██████╗░███████╗░█████╗░░█████╗░███████╗░██████╗
                ████╗░████║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
                ██╔████╔██║███████║██║░░██║█████╗░░███████║██║░░╚═╝█████╗░░╚█████╗░
                ██║╚██╔╝██║██╔══██║██║░░██║██╔══╝░░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗
                ██║░╚═╝░██║██║░░██║██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝
                ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

*/

contract Keys is ERC1155, Ownable, ReentrancyGuard {

    struct keyStruct {
        uint256 totalSupply;
        uint256 totalMinted;
        uint256 maxMinted;
        uint256 role;
        string uri;
        bool exists;
        bool locked;
        mapping(address => bool) giveawayEntries;
    }

    bool public locked_contract = false;

    string private _name;
    string private _symbol;
    string private _contractURI;

    mapping(uint256 => keyStruct) private keysInfo;
    mapping(address => bool) public madContractAddresses;

    constructor(string memory baseURI_, string memory name_, string memory symbol_) ERC1155(baseURI_) {
        _name = name_;
        _symbol = symbol_;
    }

    modifier keyExists(uint256 keyId) {
        require(exists(keyId), "Request for non existing key");
        _;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function uri(uint256 keyId) public view override returns (string memory) {
        require(_isMinted(keyId), "URI requested for non minted key");
        return keysInfo[keyId].uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply(uint256 id) public keyExists(id) view virtual returns (uint256) {
        return keysInfo[id].totalSupply;
    }

    function totalMinted(uint256 id) public keyExists(id) view virtual returns (uint256) {
        return keysInfo[id].totalMinted;
    }

    function maxMinted(uint256 id) public keyExists(id) view virtual returns (uint256) {
        return keysInfo[id].maxMinted;
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return keysInfo[id].exists;
    }

    function role(uint256 id) public keyExists(id) view virtual returns (uint256) {
        return keysInfo[id].role;
    }

    function locked(uint256 id) public keyExists(id) view virtual returns (bool) {
        return keysInfo[id].locked;
    }

    function giveAwayEntry(uint256 id) public keyExists(id) view virtual returns (bool) {
        return keysInfo[id].giveawayEntries[_msgSender()];
    }

    function _isMinted(uint256 id) private view returns (bool){
        return keysInfo[id].totalMinted > 0;
    }

    function setMadContractAddresses(address madContractAddress) external onlyOwner {
        require(!locked_contract, 'Contract has been lock forever, action not permitted');
        madContractAddresses[madContractAddress] = true;
    }

    function setNewKey(uint256 keyId, uint256 role_, uint256 maxMinted_, string memory baseURI_) external onlyOwner {
        require(!_isMinted(keyId), "Mint already start for this keyId");
        keysInfo[keyId].maxMinted = maxMinted_;
        keysInfo[keyId].totalMinted = 0;
        keysInfo[keyId].totalSupply = 0;
        keysInfo[keyId].exists = true;
        keysInfo[keyId].role = role_;
        keysInfo[keyId].uri = baseURI_;
        keysInfo[keyId].locked = false;
    }

    function giveawayKey(uint256 keyId) external nonReentrant {
        require(giveAwayEntry(keyId), "Must be on the whitelist to pretend a giveaway");
        require(totalMinted(keyId) + 1 <= maxMinted(keyId), "Amount Will exceed the max minted");

        _mint(_msgSender(), keyId, 1, "");
        keysInfo[keyId].totalSupply += 1;
        keysInfo[keyId].totalMinted += 1;
        keysInfo[keyId].giveawayEntries[_msgSender()] = false;
    }

    function mintKey(uint256 keyId, uint256 amount) external onlyOwner {
        require(totalMinted(keyId) + amount <= maxMinted(keyId), "Amount Will exceed the max minted");

        _mint(owner(), keyId, amount, "");
        keysInfo[keyId].totalSupply += amount;
        keysInfo[keyId].totalMinted += amount;
    }

    function burnKey(address account, uint256 keyId) external {
        require(madContractAddresses[_msgSender()], "Only Mad Contract are allowed to burn a key");
        _burn(account, keyId, 1);
        keysInfo[keyId].totalSupply -= 1;
    }


    function setToGiveaway(uint256 keyId, address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            keysInfo[keyId].giveawayEntries[entry] = true;
        }
    }

    function removeFromGiveaway(uint256 keyId, address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            keysInfo[keyId].giveawayEntries[entry] = false;
        }
    }

    function setUri(uint256 keyId, string memory baseURI_) external onlyOwner {
        require(!locked(keyId), 'Key has been lock forever, action not permitted');
        keysInfo[keyId].uri = baseURI_;
    }

    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    //!\ Irreversible, lock key forever /!\
    function setLockedKey(uint256 keyId) external onlyOwner {
        keysInfo[keyId].locked = true;
    }

    //!\ Irreversible, lock contract forever /!\
    function setLockedContract() external onlyOwner {
        locked_contract = true;
    }
}