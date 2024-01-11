// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0x48Cd5F1141536901edB35ac2a3D1624Ed49d5657
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract BattleForNewVenice is ERC721, Ownable {
    // Token mint values
    uint256 public constant MAX_SUPPLY = 9894;
    uint256 public reserved_mints_init = 650;
    uint256 public reserved_mints = reserved_mints_init;
    uint256 public free_public_mints = 1000 - reserved_mints_init;
    uint256 _totalSupply = 0;

    bytes32 public _merkleRootFree;
    uint256 public _price = 0.03 ether;

    uint256 public _publicStartTime = 1654948800;
    string public _baseTokenURI;

    mapping(address => uint256) public freeTicketList;

    constructor(string memory baseURI, bytes32 merkleRootFree)
        ERC721("Battle For New Venice", "BFNV")
    {
        _baseTokenURI = baseURI;
        _merkleRootFree = merkleRootFree;
        _mint(0x34Cc0455Fa50fD3EA398934b66BD178a7d497c9C, 0);
        _mint(0x8058D889C48B7a79cFdaA54Dd6d623B09c9146a3, 1);
        _mint(0x739AB197a3c2BA8D79fC5DEDa53CF5761152D277, 2);
        _mint(0x3cC89C200Ee18B618EA7C99A2A8b7d1496cD438a, 3);
        _totalSupply = 4;
    }

    /// @notice Adopt via public minting
    /// @param amount Number to mint
    function publicMint(uint256 amount) external payable {
        uint256 currentId = _totalSupply;
        require(msg.sender == tx.origin, "VQ2: Only EOAs");
        require(
            block.timestamp > _publicStartTime &&
                block.timestamp < _publicStartTime + 7 days,
            "VQ2: Public minting closed"
        );

        // conditional requires
        if (
            _totalSupply <
            free_public_mints + (reserved_mints_init - reserved_mints)
        ) {
            payable(msg.sender).transfer(msg.value); // currently a free mint
        } else {
            require(msg.value == _price * amount);
        }
        if (block.timestamp < _publicStartTime + 3 days) {
            require(
                currentId + amount < MAX_SUPPLY - reserved_mints,
                "VQ2: Exceeds Supply"
            );
        } else {
            require(currentId + amount < MAX_SUPPLY, "VQ2: Exceeds Supply");
        }

        for (uint256 i = currentId; i < currentId + amount; i++) {
            _mint(msg.sender, i);
        }

        unchecked {
            currentId += amount;
        }
        _totalSupply = currentId;
    }

    function freeListMint(bytes32[] calldata merkleProof, uint256 numClaim)
        external
    {
        uint256 currentId = _totalSupply;
        require(currentId + numClaim < MAX_SUPPLY, "VQ2: Exceeds Supply");
        require(
            freeTicketList[msg.sender] == 0,
            "VQ2: Already redeemed free mint"
        );
        require(
            block.timestamp > _publicStartTime &&
                block.timestamp < _publicStartTime + 7 days,
            "VQ2: Outside claim time"
        );

        // Merkle magic
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, numClaim));
        require(
            MerkleProof.verify(merkleProof, _merkleRootFree, leaf),
            "VQ2: Invalid merkle proof"
        );

        // claim ticket
        freeTicketList[msg.sender] = numClaim;

        for (uint256 i = 0; i < numClaim; i++) {
            _mint(msg.sender, currentId);
            unchecked {
                currentId++;
            }
        }

        reserved_mints -= numClaim;
        _totalSupply = currentId;
    }

    /// @notice Set baseURI
    /// @param baseURI URI of the pet image server
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Get uri of tokens
    /// @return string Uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set the purchase price of pets
    /// @param newPrice In wei - 10 ** 18
    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
    }

    /// @notice Set new Merkle Root
    /// @param merkleRoot Root of merkle tree
    function setMerkleRootFree(bytes32 merkleRoot) external onlyOwner {
        _merkleRootFree = merkleRoot;
    }

    /// @notice Set the public mint start time
    /// @param publicStartTime public mint start time
    function setPublicStartTime(uint256 publicStartTime) external onlyOwner {
        _publicStartTime = publicStartTime;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        if (tokenCount == 0) {
            return tokensId;
        }

        // fetch by brute force :( to avoid gas from storing the mapping :)
        // (sorry node providers, I love you :)
        uint256 curToken = 0;
        for (uint256 i; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokensId[curToken] = i;
                curToken++;
                if (curToken == tokenCount) {
                    return tokensId;
                }
            }
        }

        return tokensId;
    }

    /// @notice Withdraw funds from contract
    function withdraw() external payable {
        uint256 balMul = address(this).balance / 10000;
        payable(address(0x84dBc933095071BeAf9271286b40585ef1824011)).transfer(
            30_00 * balMul
        );
        payable(address(0xc9AccF51a01a0A39Be3feE897bdAe9a870B69C2B)).transfer(
            1_00 * balMul
        );
        payable(address(0x44981eb429f1cCF0a2DDFE87c017dB0b4e73EB5F)).transfer(
            2_60 * balMul
        );
        payable(address(0xD4fda2396E7f88085bFeea94F057cAC08F617c88)).transfer(
            5_40 * balMul
        );
        payable(address(0x537038D516E7e71BFf78A555799Ce0daa01e79a1)).transfer(
            3_60 * balMul
        );
        payable(address(0x7cf298e9cc01B5460570c8678cE19D734D604e05)).transfer(
            4_40 * balMul
        );
        payable(address(0x34Cc0455Fa50fD3EA398934b66BD178a7d497c9C)).transfer(
            6_80 * balMul
        );
        payable(address(0x027fdD192980DBb700DF7592033c57F6EC4F53f9)).transfer(
            1_20 * balMul
        );
        payable(address(0x740975Bdc13e4253c0b8aF32f5271EF0aD6Dd52e)).transfer(
            10_00 * balMul
        );
        payable(address(0x93eC3c0D92788A788370FB7Dbdbd5629502A6e01)).transfer(
            6_00 * balMul
        );
        payable(address(0x5872C9f6466F5bCa6086479537b0372eE026E6F5)).transfer(
            6_00 * balMul
        );
        payable(address(0xEF19bba0CA1A32eE95a599a25E510beF4011aB34)).transfer(
            6_00 * balMul
        );
        payable(address(0x4729f800b85D10be1b15785Fb0553F835E5B036e)).transfer(
            3_00 * balMul
        );
        payable(address(0xC0B81951c7AcC287976d0556F7e666081D7119bC)).transfer(
            3_50 * balMul
        );
        payable(address(0xD0ED3818D1aC8fdfEC6158E7c02a268c8050B75e)).transfer(
            1_00 * balMul
        );
        payable(address(0xC8df9AF1E99Cbadd4C3DD71C01044D87C88180c1)).transfer(
            25 * balMul
        );
        payable(address(0x80bDdFc2bD0B7C7FBc9691859948060C5BF86D59)).transfer(
            2_50 * balMul
        );
        payable(address(0x0218170f7F780Bbd46b633a17F15eD137490f74a)).transfer(
            2_50 * balMul
        );
        payable(address(0x84dBc933095071BeAf9271286b40585ef1824011)).transfer(
            50 * balMul
        );
        payable(address(0x5Ae95143b570AF028FF85c9D7390b134408408cC)).transfer(
            75 * balMul
        );
        payable(address(0xB7843C748D5aedEb84420364e75adfe8C2C91beA)).transfer(
            50 * balMul
        );
        payable(address(0x9Dc17c8C44300f17774Dd8Ce3828768ac1418759)).transfer(
            50 * balMul
        );
        payable(address(0x47A9DCf163132c8c1C271Fc5D8a90a801c8c85ac)).transfer(
            50 * balMul
        );
        payable(address(0xA1EFFe7fb679A99c77b55Fa29AA39A06031Cf024)).transfer(
            1_00 * balMul
        );
        payable(address(0xE6a35d73B5E27e7Cd0c8EEAb3856E2EEFbfbc8B9)).transfer(
            50 * balMul
        );
    }
}
