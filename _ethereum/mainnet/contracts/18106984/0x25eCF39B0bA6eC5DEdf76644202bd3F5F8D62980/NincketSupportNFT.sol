// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract NincketSupportNFT is ERC1155, Ownable, AccessControl, Pausable {
    using Strings for uint256;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    address public withdrawAddress;

    // Metadata
    string public baseURI;
    string public baseExtension;

    // sale info
    uint256 public totalSupply = 0;
    uint256 public maxSupply;
    uint256 public mintCost;
    bytes32 merkleRoot;

    // uint256 public mintedCount = 0;
    mapping(address => bool) public mintedAddresses;

    // Modifier
    modifier enoughEth() {
        require(mintCost > 0 && msg.value >= mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxSupply() {
        require(totalSupply <= maxSupply, 'Over Max Supply');
        _;
    }
    modifier notMinted(address _address) {
        require(mintedAddresses[_address] == false, 'Already Minted');
        _;
    }
    modifier validProof(address _address, bytes32[] calldata _merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_address));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }

    constructor() ERC1155("") {
        withdrawAddress = msg.sender;
        _grantRole(ADMIN, msg.sender);
        mintCommon(msg.sender);
        // mint(msg.sender);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    

    //default mintfunction
    // function mint(address account, uint256 id, uint256 amount, bytes memory data)
    //     public
    //     onlyOwner
    // {
    //     _mint(account, id, amount, data);
    // }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //     public
    //     onlyOwner
    // {
    //     _mintBatch(to, ids, amounts, data);
    // }

    // mint
    // function mint(bytes32[] calldata _merkleProof) external payable
    //     whenNotPaused
    //     enoughEth()
    //     validProof(msg.sender, _merkleProof)
    // {
    //     mintCommon(msg.sender);
    // }

    // function mintCommon(address _address) private
    //     withinMaxSupply()
    //     notMinted(_address)
    //     {
    //         _mint(_address, 1, 1, "");
    //         mintedAddresses[_address] = true;
    //         mintedCount++;
    //     }

    // mint
    function mint() external payable
        whenNotPaused
        // enoughEth()
    {
        mintCommon(msg.sender);
    }

    function mintCommon(address _address) private
        // withinMaxSupply()
        // notMinted(_address)
        {
            _mint(_address, 1, 1, "");
            mintedAddresses[_address] = true;
            totalSupply++;
        }
    

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    // Setter
    function setBaseURI(string memory _value) external onlyOwner {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyOwner {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyOwner {
        baseExtension = "";
    }
    function setMaxSupply(uint256 _value) external onlyOwner {
        maxSupply = _value;
    }
    function setMintCost(uint256 _value) external onlyOwner {
        mintCost = _value;
    }
    function setMerkleRoot(bytes32 _value) external onlyOwner {
        merkleRoot = _value;
    }
    function setWithdrawAddress(address _value) external onlyOwner {
        withdrawAddress = _value;
    }

    // pausable
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // withdraw
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override { 
        revert("This token is SBT.");
    }
    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal virtual override
    {
        for (uint256 i = 0; i < ids.length; i++){
            require(from == address(0) || to == address(0), "This token is SBT.");
        }
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }
    
}
