// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//   __      _  ___  __  ____  ____  __ _   __   _  _  ____  _  _  _   __   _  _  _  _  _       __   __  __  __ _  ____ 
//  / _\    / )/ __)/  \(    \(  __)(  ( \ / _\ ( \/ )(  __)(_)/ )( \ / _\ ( \/ )( \/ )( \    _(  ) /  \(  )(  ( \(_  _)
// /    \  ( (( (__(  O )) D ( ) _) /    //    \/ \/ \ ) _)  _ ) __ (/    \/ \/ \/ \/ \ ) )  / \) \(  O ))( /    /  )(  
// \_/\_/   \_)\___)\__/(____/(____)\_)__)\_/\_/\_)(_/(____)(_)\_)(_/\_/\_/\_)(_/\_)(_/(_/   \____/ \__/(__)\_)__) (__) 

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./MerkleProof.sol";

contract ProbablyNothingMints is ERC1155, Ownable, Pausable, ERC1155Supply {
    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmbuRAJug5pC8QzZYhaper64RwzQd9Nvg2m4DATTL5iDcR/{id}.json") {}
    string private contractUri = "https://gateway.pinata.cloud/ipfs/QmPHkRxcA8enbL2QufDs5GVeQCi8B79mqoc5AsvSxY3aqt/contract.json";
    string public name = "Probably Nothing Mints";
    string public symbol = "MINTS";

    // Type of Mints.  Probably Nothing.
    uint constant COOLMINT = 0;
    uint constant SPEARMINT = 1;
    uint constant WINTERGREEN = 2;
    uint constant PEPPERMINT = 3;

    // Number of Mints.  Probably Nothing.
    uint256 public immutable maxSupply = 2000;

    // Merkle Tree Root.  Probably Nothing.
    bytes32 public root;

    // Addresses that Claimed.  Probably Nothing.
    struct MintHistory {
        uint64 ownerFreeMints;
    }
    mapping(address => MintHistory) public mintHistory;

    function mint(bytes32[] memory _proof, uint8 _mintType, uint8 _maxAllocation, uint256 _mintAmount) public {
        uint256 supply = totalSupply(COOLMINT)+totalSupply(PEPPERMINT)+totalSupply(WINTERGREEN)+totalSupply(SPEARMINT);
        require(MerkleProof.verify(_proof,root,keccak256(abi.encodePacked(msg.sender, _mintType, _maxAllocation))),"Error - Verify Qualification");
        require(supply + _mintAmount < maxSupply + 1, "Error - No Mints Available");
        require(mintHistory[msg.sender].ownerFreeMints + _mintAmount < _maxAllocation + 1,"Error - Wallet Claimed");
 
        mintHistory[msg.sender].ownerFreeMints += uint64(_mintAmount);
        _mint(msg.sender, _mintType, _mintAmount, "");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setBaseUri(string calldata _baseURI) public onlyOwner {
        _setURI(_baseURI);
    }

    function setContractUri(string calldata _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    function readContractUri() public view returns (string memory) {
        return contractUri;
    }
}