// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract Unicorn is
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable
{
    using MerkleProof for bytes32[];

    struct RoundData {
        bytes32 merkleRoot;
        uint256 startAt;
    }

    uint256 public constant SEED = 0;
    uint256 public maxSupply;
    address public treasury;

    mapping(uint256 => mapping(address => uint256)) private _count;
    string private _name;
    string private _symbol;
    RoundData[] private _rounds;
    uint256 private _price;
    bool private _active;
    
    mapping(uint256 => uint256) public totalRedeem;

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 price_,
        address treasury_,
        string memory uri_
    ) public initializer {
        AccessControlUpgradeable.__AccessControl_init();
        OwnableUpgradeable.__Ownable_init();
        ERC1155Upgradeable.__ERC1155_init(uri_);
        ERC1155SupplyUpgradeable.__ERC1155Supply_init();


        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _price = price_;
        _active = true;
        treasury = treasury_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    /*
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) public pure returns(bool){
        return MerkleProof.verify(proof, root, leaf);
    }

    function verifyRedeem(bytes32[] memory proof, bytes32 root, address sender, uint256 allowed) public pure returns(bool){
        return MerkleProof.verify(
            proof, root,
            keccak256(abi.encodePacked(sender, allowed))
        );
    }
    */

    function redeem(
        uint256 round,
        uint256 amount,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable {
        require(_active, "Not active");
        require(amount > 0, "Invalid amount");
        require(_price * amount <= msg.value, "Value incorrect");
        require(round < _rounds.length, "Invalid round");
        require(_count[round][_msgSender()] + amount <= allowed, "Exceeded max");
        require(totalSupply(SEED) + amount <= maxSupply, "Exceeded max supply");
        RoundData memory _round = _rounds[round];
        require(block.timestamp >= _round.startAt, "Round not start");
        require(
            MerkleProof.verify(
                proof,
                _round.merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Not part of list"
        );

        unchecked {
            _count[round][_msgSender()] = _count[round][_msgSender()] + amount;
            totalRedeem[round] = totalRedeem[round] + amount;
        }

        _mint(_msgSender(), SEED, amount, "");

        if(treasury != address(0))
            AddressUpgradeable.sendValue(payable(treasury), msg.value);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply(SEED) + amount <= maxSupply, "Exceeded max supply");

        _mint(account, SEED, amount, "");
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
    }

    function setActive(bool newActive) external onlyOwner {
        _active = newActive;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "0 balance");
        require(treasury != address(0), "treasury 0");

        uint256 balance = address(this).balance;
        AddressUpgradeable.sendValue(payable(treasury), balance);
    }

    function setURI(string memory newURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setURI(newURI);
    }

    function setMerkleRoot(bytes32 newRoot, uint256 startAt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _rounds.push(RoundData({
            merkleRoot: newRoot,
            startAt: startAt
        }));
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), SEED, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function merkleRoot(uint256 round) external view returns (bytes32) {
        return _rounds[round].merkleRoot;
    }

    function startTime(uint256 round) external view returns (uint256) {
        return _rounds[round].startAt;
    }

    function rounds() external view returns (uint256){
        return _rounds.length;
    }

    function count(address account, uint256 round) external view returns(uint256) {
        return _count[round][account];
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function active() external view returns (bool) {
        return _active;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}