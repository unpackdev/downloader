pragma solidity ^0.8.20;

import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Kartel is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public vibezKartelAddress = 0xd3f35C2Bc82b9e156393fD5B0219CCd0DeCcCB8D;
    address public zaibatsuAddress = 0xd74702fb587fAE4567688868c9D197521920dda9;
    mapping (uint256 => mapping(address => uint256)) mintStageToMintCount;
    mapping (uint256 => bool) zaibatsuMinted;
    uint256 public maxSupply = 501;
    uint256 public mintStage = 0; // 1 = VibezKartel, 2 = FCFS, 3 = Zaibatsu
    bytes32 public fcfsRoot = 0x30de03a191f6c5142973294d44dbe4815c1e4103ff6a77644927e896dba5e742;
    string baseURI = "https://bafybeif6vdt3mfkthaqv666uxuxfdnj4wd6vc2y52is7qf2qatzs3vl24u.ipfs.nftstorage.link/";

    constructor() ERC721("Kartel", "KTL") Ownable(msg.sender) {}

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintStage(uint256 _mintStage) public onlyOwner {
        mintStage = _mintStage;
    }

    function setFcfsRoot(bytes32 _fcfsRoot) public onlyOwner {
        fcfsRoot = _fcfsRoot;
    }

    function setZaibatsuAddress(address _zaibatsuAddress) public onlyOwner {
        zaibatsuAddress = _zaibatsuAddress;
    }

    function setVibezKartelAddress(address _vibezKartelAddress) public onlyOwner {
        vibezKartelAddress = _vibezKartelAddress;
    }

    function setBaseURI(string calldata __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }

    function stageCheckMint() private {
        uint256 _mintStage = mintStage; // gas saving (MLOAD is cheaper)
        uint256 totalSupply = super.totalSupply(); //
        require (totalSupply + 1 <= maxSupply, "Max supply reached!");
        uint256 mintCount = mintStageToMintCount[_mintStage][msg.sender]; //
        if (_mintStage == 1) { // VibezKartel
            require(mintCount < 2, "You already minted!");
        } else if (_mintStage == 2) { // FCFS
            require(mintCount < 1, "You already minted!");
        }
        mintStageToMintCount[_mintStage][msg.sender]++;
        super._safeMint(msg.sender, totalSupply + 1);
    }

    function vibezKartelMint(uint256[] calldata _vibezKartelIds) public {
        require(mintStage == 1, "Mint isn't open for Vibez Kartel");
        for (uint256 i = 0; i < _vibezKartelIds.length; i++) {
            uint256 _vibezKartelId = _vibezKartelIds[i];
            IERC721(vibezKartelAddress).transferFrom(msg.sender, deadWallet, _vibezKartelId);
            stageCheckMint();
        }
    }

    function fcfsMint(bytes32[] memory _proof) public {
        require(mintStage == 2, "Mint isn't open for FCFS");
        require(
            MerkleProof.verify(_proof, fcfsRoot, keccak256(bytes.concat(keccak256(abi.encode(msg.sender))))),
            "You are not in the FCFS list!"
        );
        stageCheckMint();
    }

    function zaibatsuMint(uint256[] calldata _zaibatsuIds) public {
        require(mintStage == 3, "Mint isn't open for Zaibatsu");
        require (super.totalSupply() + _zaibatsuIds.length <= maxSupply, "Max supply reached!");
        uint256 totalSupply = super.totalSupply(); // gas saving (MLOAD is cheaper)
        for (uint256 i = 0; i < _zaibatsuIds.length; i++) {
            require(IERC721(zaibatsuAddress).ownerOf(_zaibatsuIds[i]) == msg.sender, "You're not the owner of this Zaibatsu!");
            require(!zaibatsuMinted[_zaibatsuIds[i]], "This Zaibatsu already minted!");
            zaibatsuMinted[_zaibatsuIds[i]] = true;
            super._safeMint(msg.sender, totalSupply + i + 1);
        }
    }

    function ownerMint() public onlyOwner {
        uint256 totalSupply = super.totalSupply(); // gas saving (MLOAD is cheaper)
        uint256 remainingSupply = maxSupply - totalSupply;
        for (uint256 i = 1; i <= remainingSupply; i++) {
            super._safeMint(msg.sender, totalSupply + i);
        }
    }

    // required overrides by ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
