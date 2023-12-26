// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract KomodosRoost is ERC721, Ownable {
    using Strings for uint256;

    // Tokens 0 - 32 will be preminted to court wallet
    uint256 public constant HONOR_ALLOCATION = 33;
    // Tokens 33 - 164 will be marked as available to claim
    uint256 public constant CLAIM_ALLOCATION = 165;

    uint256 public nextToClaim = HONOR_ALLOCATION;
    uint256 public nextToMint = CLAIM_ALLOCATION;

    address public minter = address(0);
    address public courtAddress = address(0);

    uint256 private claimsEnabledBlock;
    mapping(address => uint256) private claimsRemaining;

    string public tokenBaseURI;

    event MinterUpdated(address minter);
    event ClaimsEnabledBlockUpdated(uint256 claimsEnabledBlock);
    event TokenBaseURIUpdated(string uri);
    event EggMinted(uint256 indexed eggId, address indexed mintedTo);
    event MetadataUpdate(uint256 _tokenId);

    modifier onlyMinter() {
        require(msg.sender == minter, "MINTER_ONLY");
        _;
    }

    constructor(
        address _courtAddress,
        string memory _tokenBaseURI,
        uint256 _claimsEnabledBlock
    ) ERC721("Komodo's Roost", "KOMODO") {
        require(_courtAddress != address(0), "INVALID_COURT");

        courtAddress = _courtAddress;
        tokenBaseURI = _tokenBaseURI;
        claimsEnabledBlock = _claimsEnabledBlock;

        _transferOwnership(_courtAddress);
    }

    function emitMetadataUpdate(uint256 tokenId) public {
        require(msg.sender == minter || msg.sender == courtAddress, "NOT_ALLOWED");
        emit MetadataUpdate(tokenId);
    }


    function exists(uint256 id) public view returns (bool) {
        return _ownerOf[id] != address(0);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(ownerOf(id) != address(0), "NOT_YET_MINTED");

        return
            bytes(tokenBaseURI).length > 0
                ? string(abi.encodePacked(tokenBaseURI, id.toString()))
                : "";
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit MinterUpdated(_minter);
    }

    function setClaimsEnabledBlock(uint256 _newClaimsEnabledBlock)
        external
        onlyOwner
    {
        claimsEnabledBlock = _newClaimsEnabledBlock;
        emit ClaimsEnabledBlockUpdated(_newClaimsEnabledBlock);
    }

    function setBaseTokenURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
        emit TokenBaseURIUpdated(_tokenBaseURI);
    }

    function assignClaims(
        address[] calldata addresses,
        uint256[] calldata claimQuantities
    ) external onlyOwner {
        require(
            addresses.length == claimQuantities.length,
            "MISMATCHING_LENGTHS"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            claimsRemaining[addresses[i]] += claimQuantities[i];
        }
    }

    function removeClaims(
        address[] calldata addresses,
        uint256[] calldata claimQuantities
    ) external onlyOwner {
        require(
            addresses.length == claimQuantities.length,
            "MISMATCHING_LENGTHS"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                claimsRemaining[addresses[i]] >= claimQuantities[i],
                "INVALID_CLAIMS_QUANTITY"
            );
            claimsRemaining[addresses[i]] -= claimQuantities[i];
        }
    }

    function mint(address to) public onlyMinter {
        _mint(to, nextToMint++);
        emit EggMinted(nextToMint - 1, to);
    }

    function claimHonor() public onlyOwner {
        for (uint256 i = 0; i < HONOR_ALLOCATION; i++) {
            _mint(courtAddress, i);
            emit EggMinted(i, courtAddress);
        }
    }

    function claim(uint256 quantity) public {
        require((block.number >= claimsEnabledBlock), "CLAIM_WINDOW_INACTIVE");
        require(quantity > 0, "CLAIM_QTY_ZERO");
        require(quantity <= claimsRemaining[msg.sender], "NO_CLAIMS_REMAINING");
        require(
            nextToClaim + quantity <= CLAIM_ALLOCATION,
            "ALLOCATION_EXHAUSTED"
        );

        claimsRemaining[msg.sender] -= quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, nextToClaim++);
            emit EggMinted(nextToClaim - 1, msg.sender);
        }
    }

    function claimsAvailable(address claimer) public view returns (uint256) {
        return
            nextToClaim + claimsRemaining[claimer] <= CLAIM_ALLOCATION
                ? claimsRemaining[claimer]
                : CLAIM_ALLOCATION - nextToClaim;
    }

    function claimAll() public {
        claim(claimsAvailable(msg.sender));
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from ||
                msg.sender == minter ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];
        emit Transfer(from, to, id);
    }
}
