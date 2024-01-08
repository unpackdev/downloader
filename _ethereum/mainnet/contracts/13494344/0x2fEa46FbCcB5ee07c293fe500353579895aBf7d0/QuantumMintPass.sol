// SPDX-License-Identifier: MIT
/*
    Inspiration from MetaHero MintPass https://etherscan.io/address/0x797a48c46be32aafcedcfd3d8992493d8a1f256b
*/

pragma solidity ^0.8.0;
import "./IQuantumMintPass.sol";
import "./OSContractURI.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./MerkleProof.sol";
import "./Address.sol";

contract QuantumMintPass is ERC2981, IQuantumMintPass, OSContractURI, Ownable, ERC1155Supply, ERC1155Burnable {

    struct MintPass {
        bytes32 merkleRoot;
        uint256 price;
        string uriSuffix;
        address redeemableContract; // contract of the redeemable NFT
    }

    event Claimed(uint mpId, address indexed account, uint amount);

    string public name;
    string public symbol;   

    uint private _counter;
    address payable private _treasury;
  
    mapping (uint256 => MintPass) public mintPasses;
    mapping (uint256 => mapping (address => bool)) public claimed;

    constructor(string memory baseURI, address payable treasury) ERC1155(baseURI) {
        name = "Quantum MintPass";
        symbol = "QPASS";
        _treasury = treasury;
    }  

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function setContractURI(string calldata newUri) onlyOwner override public {
        super.setContractURI(newUri);
    }

    function setRoyalteFee(uint256 fee) onlyOwner override public {
        royaltyFee = fee;
    }

    function addMintPass(
        bytes32 merkleRoot,
        uint256 price,
        string memory uriSuffix,
        address redeemableContract
    ) external onlyOwner {
        mintPasses[_counter++] = MintPass(
            merkleRoot,
            price,
            uriSuffix,
            redeemableContract
        );
    }

    function editMintPass(
        uint256 mpId,
        bytes32 merkleRoot,
        uint256 price, 
        string memory uriSuffix,
        address redeemableContract
    ) external onlyOwner {
        mintPasses[mpId] = MintPass(
            merkleRoot,
            price,
            uriSuffix,
            redeemableContract
        );
    }

    function burnFromRedeem(
        address user, 
        uint256 mpId, 
        uint256 amount
    ) external override {
        require(mintPasses[mpId].redeemableContract == msg.sender, "burnFromRedeem: Only allowed from redeemable contract");
        _burn(user, mpId, amount);
    }  

    function claim(
        uint256 mpId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable {
        MintPass memory mp = mintPasses[mpId];
        require(msg.value == mp.price * amount, "claim: invalid msg.value");
        require(mp.merkleRoot.length > 0, "claim: mint pass does not exist");
        require(!claimed[mpId][msg.sender], "claim: already claimed");
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, mp.merkleRoot, node),"claim: Invalid proof.");
        claimed[mpId][msg.sender] = true;
        _mint(msg.sender, mpId, amount, "");
        emit Claimed(mpId, msg.sender, amount);
        Address.sendValue(_treasury, msg.value);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), mintPasses[_id].uriSuffix));
    }

    function royaltyInfo(uint256 tokenId,uint256 salePrice) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (_treasury, (salePrice * royaltyFee) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }  

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    } 
}
