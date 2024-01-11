// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

contract VQ2 is ERC721, Ownable {
    // Token mint values
    uint256 public constant MAX_QUESTIONS = 8893;
    uint256 _totalSupply = 0;

    bytes32 public _merkleRootPresale;
    bytes32 public _merkleRootVQ1;
    uint256 public _price = 0.088 ether;

    uint256 public _presaleStartTime = 1650083760;
    string public _baseTokenURI;

    // For bit manipulation
    uint256[] _allowListTicketSlots;
    mapping(address => uint256) public vq1TicketList;

    constructor(
        string memory baseURI,
        bytes32 merkleRootVQ1,
        bytes32 merkleRootPresale
    ) ERC721("VAST QUESTIONS 2", "VQ2") {
        _baseTokenURI = baseURI;
        _merkleRootVQ1 = merkleRootVQ1;
        _merkleRootPresale = merkleRootPresale;
    }

    /// @notice Adopt via public minting
    /// @dev Id tracking starts at 9999 to prevent id contamination
    /// @dev Signature to help avoid bot minting
    /// @param amount Number to mint
    function publicMint(uint256 amount) external payable {
        uint256 currentId = _totalSupply;
        require(msg.sender == tx.origin, "VQ2: Only EOAs");
        require(
            block.timestamp > _presaleStartTime + 2 days &&
                block.timestamp < _presaleStartTime + 7 days,
            "VQ2: Public minting closed"
        );
        require(currentId + amount < MAX_QUESTIONS, "VQ2: Exceeds Supply");
        require(msg.value == _price * amount, "VQ2: Invalid Eth sent");

        for (uint256 i = currentId; i < currentId + amount; i++) {
            _mint(msg.sender, i);
        }

        unchecked {
            currentId += amount; // check gas of this vs. doing unchecked incrementation of _totalSupply
        }
        _totalSupply = currentId;
    }

    /// @notice Mint via presale list with reference to a ticket number + merkle tree
    /// @dev Id tracking starts at 9999 to prevent id contamination
    /// @dev We could allow contracts to mint but saving gas for users is more important
    /// @dev Dont start ticketNumber at 0
    /// @param merkleProof Merkle proof for verifcation
    /// @param ticketNumbers ticket number assigned to user's address
    function presaleListMintMultiple(
        bytes32[] calldata merkleProof,
        uint256[] calldata ticketNumbers,
        uint256 numClaim
    ) external payable {
        uint256 currentId = _totalSupply;

        require(
            block.timestamp > _presaleStartTime &&
                block.timestamp < _presaleStartTime + 2 days,
            "VQ2: Presale closed"
        );
        require(currentId + numClaim < MAX_QUESTIONS, "VQ2: Exceeds Supply");
        require(msg.value == _price * numClaim, "VQ2: Invalid Eth sent");
        // no require needed for presale status as they can only mint through our website

        // Merkle magic
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticketNumbers));
        require(
            MerkleProof.verify(merkleProof, _merkleRootPresale, leaf),
            "VQ2: Invalid merkle proof"
        );

        // claim ticket
        _claimTickets(ticketNumbers, numClaim);

        // Pets bought by non-cat holders will have token ID increasing from 9,999 onwards
        for (uint256 i = 0; i < numClaim; i++) {
            _mint(msg.sender, currentId);
            unchecked {
                currentId++;
            }
        }

        _totalSupply = currentId;
    }

    function vq1ListMint(bytes32[] calldata merkleProof, uint256 numClaim)
        external
    {
        uint256 currentId = _totalSupply;
        require(currentId + numClaim < MAX_QUESTIONS, "VQ2: Exceeds Supply");
        require(
            vq1TicketList[msg.sender] == 0,
            "VQ2: Already redeemed free mint"
        );
        require(
            block.timestamp > _presaleStartTime &&
                block.timestamp < _presaleStartTime + 7 days,
            "VQ2: Outside claim time"
        );

        // Merkle magic
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, numClaim));
        require(
            MerkleProof.verify(merkleProof, _merkleRootVQ1, leaf),
            "VQ2: Invalid merkle proof"
        );

        // claim ticket
        vq1TicketList[msg.sender] = numClaim;

        for (uint256 i = 0; i < numClaim; i++) {
            _mint(msg.sender, currentId);
            unchecked {
                currentId++;
            }
        }

        _totalSupply = currentId;
    }

    /// @notice To check and track ticket numbers being claimed against
    /// @dev Returns error if ticket is larger than range or has been claimed against
    /// @dev Uses bit manipulation in place of mapping
    /// @dev https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
    /// @param ticketNumbers ticket numbers assigned to user's address
    /// @param numClaim number of tokens being minted, requires number of tickets
    function _claimTickets(uint256[] calldata ticketNumbers, uint256 numClaim)
        internal
    {
        uint256 ticketNumber;
        uint256 storageOffset; // [][][]
        uint256 localGroup; // [][x][]
        uint256 offsetWithin256; // 0xF[x]FFF
        require(
            numClaim < ticketNumbers.length + 1,
            "VQ2: Invalid number of tickets"
        );
        require(
            ticketNumbers[ticketNumbers.length - 1] <
                _allowListTicketSlots.length * 256,
            "VQ2: Invalid tickets"
        );
        // We can trust the admin arent adding silly numbers
        unchecked {
            storageOffset = ticketNumbers[0] / 256;
        }
        localGroup = _allowListTicketSlots[storageOffset];

        for (uint256 i = 0; i < numClaim; i++) {
            ticketNumber = ticketNumbers[i];
            offsetWithin256 = ticketNumber % 256;

            if (ticketNumber / 256 != storageOffset) {
                // accounting if ticketNumbers span multiple groups
                _allowListTicketSlots[storageOffset] = localGroup; // highest gas because updating storage, happens max 2 times per claim
                unchecked {
                    storageOffset = ticketNumbers[0] / 256;
                }
                localGroup = _allowListTicketSlots[storageOffset];
            }
            // [][x][] > 0x1111[x]1111 > 1
            require(
                (localGroup >> offsetWithin256) & uint256(1) == 1,
                "VQ2: Ticket Claimed"
            );

            // [][x][] > 0x1111[x]1111 > (1) flip to (0)
            localGroup = localGroup & ~(uint256(1) << offsetWithin256);
        }
        _allowListTicketSlots[storageOffset] = localGroup; // final set of stored variable
    }

    /// @notice Sets the mint data slot length that tracks the state of tickets
    /// @param num number of tickets available for allow list
    function setMintSlotLength(uint256 num) external onlyOwner {
        // account for solidity rounding down
        uint256 slotCount = (num / 256) + 1;

        // set each element in the slot to binaries of 1
        uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        // create a temporary array based on number of slots required
        uint256[] memory arr = new uint256[](slotCount);

        // fill each element with MAX_INT
        for (uint256 i; i < slotCount; i++) {
            arr[i] = MAX_INT;
        }

        _allowListTicketSlots = arr;
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
    function setMerkleRootPresale(bytes32 merkleRoot) external onlyOwner {
        _merkleRootPresale = merkleRoot;
    }

    /// @notice Set new Merkle Root
    /// @param merkleRoot Root of merkle tree
    function setMerkleRootVQ1(bytes32 merkleRoot) external onlyOwner {
        _merkleRootVQ1 = merkleRoot;
    }

    /// @notice Set the presale start time
    /// @param presaleStartTime presale start time
    function setPresaleStartTime(uint256 presaleStartTime) external onlyOwner {
        _presaleStartTime = presaleStartTime;
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
            25_00 * balMul
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
            11_00 * balMul
        );
        payable(address(0x93eC3c0D92788A788370FB7Dbdbd5629502A6e01)).transfer(
            7_00 * balMul
        );
        payable(address(owner())).transfer(7_00 * balMul);
        payable(address(0xEF19bba0CA1A32eE95a599a25E510beF4011aB34)).transfer(
            7_00 * balMul
        );
        payable(address(0xE7F97Cdd853d30A1BeFB42B88f8fe314AC67e8eb)).transfer(
            1_00 * balMul
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
        payable(address(0xa8d67e13AC97cba918DeCdCD78f71fca8aB2d1a8)).transfer(
            25 * balMul
        );
        payable(address(0xf239447Dafa45D4FF2136f3006d445908f43E9c3)).transfer(
            25 * balMul
        );
        payable(address(0xC8df9AF1E99Cbadd4C3DD71C01044D87C88180c1)).transfer(
            25 * balMul
        );
        payable(address(0xE7F97Cdd853d30A1BeFB42B88f8fe314AC67e8eb)).transfer(
            1_00 * balMul
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
    }
}
