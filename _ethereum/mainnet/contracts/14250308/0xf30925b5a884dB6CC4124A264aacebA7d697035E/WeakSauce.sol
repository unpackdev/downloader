// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./CryptoLibrary.sol";
import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";


contract W3ak5auc3 is ERC721Enumerable {
    bytes32 public groupsRoot = 0x4f4c9f876ca94e21ca2ed12e40563e47097be4cc3ee36632513475a662f5f604;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private magicMsg = "Love Always, Cr0wn";
    bytes32 public magicSalt;
    uint256 public maxSupply = 3000;
    uint256 public maxPerAddress = 2;
    uint256 public mintPrice = 1;
    bool public soulved;
    constructor() ERC721("W3ak5auc3", "W5") {
    }
    function mint() public payable {
        require(!soulved, "Puzzle already soulved");
        require(msg.value >= mintPrice && msg.value % mintPrice == 0, "Invalid value sent");
        uint256 _amount = msg.value / mintPrice;
        require(balanceOf(msg.sender) + _amount <= maxPerAddress, "You only need 2");
        require(
            (totalSupply() + _amount) <= maxSupply,
            "Mint would exceed total supply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            _mint(msg.sender, newNftTokenId);
        }
    }
    function soulve(bytes32[] memory _proof, uint256[2] memory _sig, uint256[4] memory _pubK) public {
        require(isValidPubK(_proof, _pubK), "Not a valid public key");
        require(verify(_sig, _pubK), "Invalid signature");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }
    function isValidPubK(bytes32[] memory _proof, uint256[4] memory _pubK) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_pubK));
        bytes32 hleaf = keccak256(abi.encodePacked(leaf));
        return MerkleProof.verify(_proof, groupsRoot, hleaf);
    }
    function verify(
        uint256[2] memory _sig,
        uint256[4] memory _pubK
    ) public view returns (bool) {
        bytes memory _msg = getHolderMsg();
        bytes memory _nMsg = abi.encodePacked(
            _pubK[0],
            _pubK[1],
            _pubK[2],
            _pubK[3],
            _msg
        );
        return CryptoLibrary.Verify(_nMsg, _sig, _pubK);
    }
    function getHolderMsg() public view returns (bytes memory) {
        bytes32 nMsg;
        for (uint8 i = 0; i < 2; i++) {
            uint256 id = tokenOfOwnerByIndex(msg.sender, i);
            bytes memory raw = abi.encodePacked(id);
            nMsg = nMsg ^ keccak256(abi.encodePacked(raw, magicMsg));
        }
        return abi.encodePacked(nMsg);
    }
    function getTokenPk(uint256 _tokenId, bytes32 _magicSalt) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(((_tokenId % 66) + 1), _magicSalt));
    }
    function fundPuzzle() public payable returns (string memory) {
        return magicMsg;
    }
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"',
                    _tokenId.toString(),
                    '","image_data":"',
                    'ipfs://QmTFStUXxYYbVeJXKNudrdvvmzBzk1qXHt61stKzeLKgJW',
                    '"}'
                )
            );
    }
}